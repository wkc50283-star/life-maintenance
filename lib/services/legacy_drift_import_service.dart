import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../data/maintenance_card_catalog.dart';
import '../database/app_database.dart';
import '../models/enums.dart';
import '../models/item.dart';
import '../models/legacy_drift_import_report.dart';
import '../models/maintenance_plan.dart';
import '../models/maintenance_plan_enums.dart';
import '../models/maintenance_record.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import 'local_data_backup_service.dart';
import 'local_storage_service.dart';

abstract interface class LegacyImportSource {
  Future<String?> readString(String key);
}

class SharedPreferencesLegacyImportSource implements LegacyImportSource {
  const SharedPreferencesLegacyImportSource(this._storage);

  final LocalStorageService _storage;

  @override
  Future<String?> readString(String key) => _storage.readString(key);
}

class LegacyDriftImportService {
  const LegacyDriftImportService({
    required AppDatabase database,
    required LegacyImportSource source,
  }) : _database = database,
       _source = source;

  static const String _manualReminderCardId = 'manual-expiry-reminder';
  static const String _legacyCategoryId = 'system-category-legacy-imported';
  static const String _legacyItemNote = '由 schema v1 案件資料自動建立；名稱可由使用者後續修正。';

  final AppDatabase _database;
  final LegacyImportSource _source;

  Future<LegacyDriftImportReport> dryRun() async {
    final preparation = await _prepare();
    if (preparation.issues.isNotEmpty) {
      return preparation.report(LegacyDriftImportStatus.blocked);
    }

    final databaseIssues = await _databaseIssues();
    if (databaseIssues.isNotEmpty) {
      return preparation.report(
        LegacyDriftImportStatus.blocked,
        extraIssues: databaseIssues,
      );
    }

    final target = await _assessTarget(preparation.plan!);
    return preparation.report(target.status, extraIssues: target.issues);
  }

  Future<LegacyDriftImportReport> execute({
    required bool sourceWritesAreDisabled,
    bool allowVerifiedPlanningMutations = false,
  }) async {
    final preparation = await _prepare();
    if (!sourceWritesAreDisabled) {
      preparation.issues.add(
        const LegacyDriftImportIssue(
          code: 'source-not-frozen',
          message: '匯入期間必須先停止 SharedPreferences 寫入。',
        ),
      );
    }
    if (preparation.issues.isNotEmpty) {
      throw LegacyDriftImportException(
        preparation.report(LegacyDriftImportStatus.blocked),
      );
    }

    final result = await _database.transaction(() async {
      final beforeIssues = await _databaseIssues();
      if (beforeIssues.isNotEmpty) {
        throw LegacyDriftImportException(
          preparation.report(
            LegacyDriftImportStatus.blocked,
            extraIssues: beforeIssues,
          ),
        );
      }

      final plan = preparation.plan!;
      final target = await _assessTarget(
        plan,
        allowVerifiedPlanningMutations: allowVerifiedPlanningMutations,
      );
      if (target.status == LegacyDriftImportStatus.alreadyImported) {
        return preparation.report(LegacyDriftImportStatus.alreadyImported);
      }
      if (target.status != LegacyDriftImportStatus.ready) {
        throw LegacyDriftImportException(
          preparation.report(
            LegacyDriftImportStatus.blocked,
            extraIssues: target.issues,
          ),
        );
      }

      await _writePlan(plan, target.replaceableItemIds);

      final after = await _assessTarget(
        plan,
        allowVerifiedPlanningMutations: allowVerifiedPlanningMutations,
      );
      if (after.status != LegacyDriftImportStatus.alreadyImported) {
        throw StateError('Legacy import target verification failed.');
      }
      final afterIssues = await _databaseIssues();
      if (afterIssues.isNotEmpty) {
        throw StateError(
          'Legacy import integrity verification failed: '
          '${afterIssues.map((issue) => issue.code).join(', ')}',
        );
      }
      return preparation.report(LegacyDriftImportStatus.imported);
    });

    return result;
  }

  Future<_Preparation> _prepare() async {
    final issues = <LegacyDriftImportIssue>[];
    final rawSources = <String, String?>{};
    final digests = <String, String>{};
    final byteLengths = <String, int>{};

    for (final entry in LocalDataBackupService.backupKeys.entries) {
      final sourceValue = await _source.readString(entry.key);
      final backupValue = await _source.readString(entry.value);
      rawSources[entry.key] = sourceValue;
      digests[entry.key] =
          'sha256:${sha256.convert(utf8.encode(sourceValue ?? ''))}';
      byteLengths[entry.key] = utf8.encode(sourceValue ?? '').length;

      if (sourceValue != null && backupValue == null) {
        issues.add(
          LegacyDriftImportIssue(
            code: 'backup-missing',
            message: '來源資料缺少不可變備份。',
            storageKey: entry.key,
          ),
        );
      } else if (sourceValue != backupValue) {
        issues.add(
          LegacyDriftImportIssue(
            code: 'backup-mismatch',
            message: '來源資料與不可變備份不一致。',
            storageKey: entry.key,
          ),
        );
      }
    }

    final items = _decode<Item>(
      key: 'items',
      raw: rawSources['items'],
      parser: Item.fromJson,
      idOf: (value) => value.id,
      validateRaw: _validateItemJson,
      issues: issues,
    );
    final schedules = _decode<Schedule>(
      key: 'schedules',
      raw: rawSources['schedules'],
      parser: Schedule.fromJson,
      idOf: (value) => value.id,
      validateRaw: _validateScheduleJson,
      issues: issues,
    );
    final tasks = _decode<Task>(
      key: 'tasks',
      raw: rawSources['tasks'],
      parser: Task.fromJson,
      idOf: (value) => value.id,
      validateRaw: _validateTaskJson,
      issues: issues,
    );
    final records = _decode<MaintenanceRecord>(
      key: 'maintenance_records',
      raw: rawSources['maintenance_records'],
      parser: MaintenanceRecord.fromJson,
      idOf: (value) => value.id,
      validateRaw: _validateRecordJson,
      issues: issues,
    );

    final counts = <String, int>{
      for (final entry in rawSources.entries)
        entry.key: _rawEntryCount(entry.value),
    };
    final validCounts = <String, int>{
      'items': items.length,
      'schedules': schedules.length,
      'tasks': tasks.length,
      'maintenance_records': records.length,
    };

    _validateGraph(items, schedules, tasks, records, issues);
    final plan = issues.isEmpty ? _map(items, schedules, tasks, records) : null;
    return _Preparation(
      sourceDigests: digests,
      sourceByteLengths: byteLengths,
      sourceCounts: counts,
      validSourceCounts: validCounts,
      issues: issues,
      plan: issues.isEmpty ? plan : null,
    );
  }

  int _rawEntryCount(String? raw) {
    if (raw == null) return 0;
    try {
      final decoded = jsonDecode(raw);
      return decoded is List ? decoded.length : 0;
    } catch (_) {
      return 0;
    }
  }

  List<T> _decode<T>({
    required String key,
    required String? raw,
    required T Function(Map<String, dynamic>) parser,
    required String Function(T) idOf,
    required bool Function(Map<String, dynamic>) validateRaw,
    required List<LegacyDriftImportIssue> issues,
  }) {
    if (raw == null) return <T>[];
    Object? decoded;
    try {
      decoded = jsonDecode(raw);
    } catch (_) {
      issues.add(
        LegacyDriftImportIssue(
          code: 'unreadable-json',
          message: '來源不是可解析的 JSON。',
          storageKey: key,
        ),
      );
      return <T>[];
    }
    if (decoded is! List) {
      issues.add(
        LegacyDriftImportIssue(
          code: 'invalid-top-level',
          message: '來源 JSON 頂層必須是陣列。',
          storageKey: key,
        ),
      );
      return <T>[];
    }

    final result = <T>[];
    final seen = <String>{};
    for (var index = 0; index < decoded.length; index += 1) {
      final rawEntry = decoded[index];
      try {
        if (rawEntry is! Map) throw const FormatException();
        final json = Map<String, dynamic>.from(rawEntry);
        if (!validateRaw(json)) throw const FormatException();
        final value = parser(json);
        final id = idOf(value);
        if (id.trim().isEmpty) throw const FormatException();
        if (!seen.add(id)) {
          issues.add(
            LegacyDriftImportIssue(
              code: 'duplicate-id',
              message: '來源資料含有重複 ID。',
              storageKey: key,
              entryId: id,
            ),
          );
        }
        result.add(value);
      } catch (_) {
        issues.add(
          LegacyDriftImportIssue(
            code: 'invalid-entry',
            message: '來源資料含有無法安全轉換的項目（index $index）。',
            storageKey: key,
          ),
        );
      }
    }
    return result;
  }

  bool _validateItemJson(Map<String, dynamic> json) {
    final category = json['category'];
    final status = json['status'];
    final photoPath = json['photoPath'];
    return category is String &&
        ItemCategory.values.any((value) => value.name == category) &&
        (status == null ||
            status is String &&
                ItemStatus.values.any((value) => value.name == status)) &&
        (photoPath == null || photoPath is String && photoPath.isNotEmpty);
  }

  bool _validateScheduleJson(Map<String, dynamic> json) {
    final cycleType = json['cycleType'];
    final status = json['status'];
    final reminderTime = json['reminderTime'];
    return cycleType is String &&
        CycleType.values.any((value) => value.name == cycleType) &&
        (status == null ||
            status is String &&
                ScheduleStatus.values.any((value) => value.name == status)) &&
        (reminderTime == null ||
            reminderTime is String && _isValidReminderTime(reminderTime));
  }

  bool _isValidReminderTime(String value) {
    final match = RegExp(r'^(\d{2}):(\d{2})$').firstMatch(value);
    if (match == null) return false;
    final hour = int.parse(match.group(1)!);
    final minute = int.parse(match.group(2)!);
    return hour <= 23 && minute <= 59;
  }

  bool _validateTaskJson(Map<String, dynamic> json) {
    final status = json['status'];
    return status == null ||
        status is String &&
            TaskStatus.values.any((value) => value.name == status);
  }

  bool _validateRecordJson(Map<String, dynamic> json) {
    final recordType = json['recordType'];
    final parts = json['partsChanged'];
    final photos = json['photos'];
    return (recordType == null ||
            recordType is String &&
                RecordType.values.any((value) => value.name == recordType)) &&
        _isStringListOrNull(parts) &&
        _isStringListOrNull(photos, requireNonEmpty: true);
  }

  bool _isStringListOrNull(Object? value, {bool requireNonEmpty = false}) {
    if (value == null) return true;
    return value is List &&
        value.every(
          (entry) =>
              entry is String && (!requireNonEmpty || entry.trim().isNotEmpty),
        );
  }

  void _validateGraph(
    List<Item> items,
    List<Schedule> schedules,
    List<Task> tasks,
    List<MaintenanceRecord> records,
    List<LegacyDriftImportIssue> issues,
  ) {
    final itemIds = items.map((value) => value.id).toSet();
    final scheduleById = {for (final value in schedules) value.id: value};
    final taskById = {for (final value in tasks) value.id: value};
    final scheduleDueKeys = <String>{};

    for (final item in items) {
      if (item.name.trim().isEmpty ||
          (item.expectedLifeYears != null && item.expectedLifeYears! <= 0)) {
        _invalidRelation(issues, 'items', item.id, 'invalid-item-values');
      }
    }
    for (final schedule in schedules) {
      if (!itemIds.contains(schedule.itemId)) {
        _invalidRelation(issues, 'schedules', schedule.id, 'missing-item');
      }
      if (schedule.interval <= 0) {
        _invalidRelation(issues, 'schedules', schedule.id, 'invalid-interval');
      }
      if (schedule.cardId != _manualReminderCardId &&
          MaintenanceCardCatalog.resolve(
                cardId: schedule.cardId,
                itemId: schedule.itemId,
              ) ==
              null) {
        _invalidRelation(issues, 'schedules', schedule.id, 'unknown-card-id');
      }
    }
    for (final task in tasks) {
      final hasSchedule = task.scheduleId.isNotEmpty;
      final schedule = hasSchedule ? scheduleById[task.scheduleId] : null;
      if (!itemIds.contains(task.itemId)) {
        _invalidRelation(issues, 'tasks', task.id, 'missing-item');
      }
      if (hasSchedule && schedule == null) {
        _invalidRelation(issues, 'tasks', task.id, 'missing-schedule');
      } else if (schedule != null &&
          (schedule.itemId != task.itemId || schedule.cardId != task.cardId)) {
        _invalidRelation(issues, 'tasks', task.id, 'task-source-mismatch');
      }
      if (task.title.trim().isEmpty) {
        _invalidRelation(issues, 'tasks', task.id, 'empty-title');
      }
      final scheduleDueKey = hasSchedule
          ? '${task.scheduleId}\u0000${task.dueDate.toIso8601String()}'
          : null;
      if (scheduleDueKey != null && !scheduleDueKeys.add(scheduleDueKey)) {
        _invalidRelation(
          issues,
          'tasks',
          task.id,
          'duplicate-schedule-due-date',
        );
      }
    }
    for (final record in records) {
      if (!itemIds.contains(record.itemId)) {
        _invalidRelation(
          issues,
          'maintenance_records',
          record.id,
          'missing-item',
        );
      }
      final taskId = record.taskId;
      if (taskId != null && taskId.isNotEmpty) {
        final task = taskById[taskId];
        if (task == null || task.itemId != record.itemId) {
          _invalidRelation(
            issues,
            'maintenance_records',
            record.id,
            'record-task-mismatch',
          );
        }
      }
      if (record.title.trim().isEmpty ||
          (record.cost != null && record.cost! < 0)) {
        _invalidRelation(
          issues,
          'maintenance_records',
          record.id,
          'invalid-record-values',
        );
      }
    }
  }

  void _invalidRelation(
    List<LegacyDriftImportIssue> issues,
    String storageKey,
    String entryId,
    String code,
  ) {
    issues.add(
      LegacyDriftImportIssue(
        code: code,
        message: '來源資料關聯或欄位不符合安全匯入條件。',
        storageKey: storageKey,
        entryId: entryId,
      ),
    );
  }

  _ImportPlan _map(
    List<Item> items,
    List<Schedule> schedules,
    List<Task> tasks,
    List<MaintenanceRecord> records,
  ) {
    final categoryDates = <ItemCategory, DateTime>{};
    for (final item in items) {
      final current = categoryDates[item.category];
      if (current == null || item.createdAt.isBefore(current)) {
        categoryDates[item.category] = item.createdAt;
      }
    }
    final categories = categoryDates.entries
        .map((entry) {
          final mapping = _categoryMapping(entry.key);
          return ItemCategoryRow(
            id: 'legacy-category-${entry.key.name}',
            systemCode: mapping.$1,
            displayName: mapping.$2,
            sortOrder: entry.key.index,
            status: 'active',
            createdAt: entry.value,
            updatedAt: entry.value,
          );
        })
        .toList(growable: false);

    final itemRows = items
        .map(
          (item) => ItemRow(
            id: item.id,
            name: item.name,
            categoryId: 'legacy-category-${item.category.name}',
            createdAt: item.createdAt,
            updatedAt: item.createdAt,
            purchaseDate: item.purchaseDate,
            warrantyEndDate: item.warrantyEndDate,
            expectedLifeYears: item.expectedLifeYears,
            location: item.location,
            note: item.note,
            status: item.status.name,
          ),
        )
        .toList(growable: false);

    final planRows = <MaintenancePlanRow>[];
    final stepRows = <MaintenancePlanStepRow>[];
    final reminderRows = <GeneralReminderRow>[];
    final scheduleRows = <ScheduleRow>[];
    final planIdBySchedule = <String, String>{};
    final reminderIdBySchedule = <String, String>{};

    for (final schedule in schedules) {
      final isReminder = schedule.cardId == _manualReminderCardId;
      final title = schedule.title?.trim().isNotEmpty == true
          ? schedule.title!.trim()
          : isReminder
          ? '提醒事項'
          : MaintenanceCardCatalog.resolve(
              cardId: schedule.cardId,
              itemId: schedule.itemId,
            )!.title;
      String? planId;
      String? reminderId;
      if (isReminder) {
        reminderId = 'legacy-reminder-${schedule.id}';
        reminderIdBySchedule[schedule.id] = reminderId;
        reminderRows.add(
          GeneralReminderRow(
            schemaVersion: 1,
            id: reminderId,
            itemId: schedule.itemId,
            title: title,
            reminderType: 'expiry',
            status: schedule.status.name,
            createdAt: schedule.startDate,
            updatedAt: schedule.startDate,
          ),
        );
      } else {
        final template = MaintenanceCardCatalog.resolve(
          cardId: schedule.cardId,
          itemId: schedule.itemId,
        )!;
        planId = 'legacy-plan-${schedule.id}';
        planIdBySchedule[schedule.id] = planId;
        planRows.add(
          MaintenancePlanRow(
            schemaVersion: MaintenancePlan.currentSchemaVersion,
            id: planId,
            itemId: schedule.itemId,
            templateCardId: template.id,
            title: title,
            planType: _planType(template.type).name,
            riskLevel: template.riskLevel.name,
            estimatedMinutes: template.estimatedMinutes,
            requiredPhotos: template.requiredPhotos,
            requiredNote: template.requiredNote,
            safetyNotice: template.safetyNotice,
            status: _planStatus(schedule.status).name,
            createdAt: schedule.startDate,
            updatedAt: schedule.startDate,
          ),
        );
        for (final step in template.steps) {
          stepRows.add(
            MaintenancePlanStepRow(
              id: 'legacy-step-${schedule.id}-${step.order}',
              maintenancePlanId: planId,
              stepOrder: step.order,
              title: step.title,
              description: step.description.isEmpty ? null : step.description,
              isRequired: step.isRequired,
              photoRequired: step.photoRequired,
              noteRequired: step.noteRequired,
            ),
          );
        }
      }
      scheduleRows.add(
        ScheduleRow(
          id: schedule.id,
          itemId: schedule.itemId,
          sourceType: isReminder ? 'generalReminder' : 'maintenancePlan',
          maintenancePlanId: planId,
          generalReminderId: reminderId,
          legacyCardId: schedule.cardId,
          cycleType: schedule.cycleType.name,
          interval: schedule.interval,
          startDate: schedule.startDate,
          nextDueDate: schedule.nextDueDate,
          reminderTime: schedule.reminderTime,
          status: schedule.status.name,
          anchorPolicy: schedule.cycleType == CycleType.custom
              ? 'userDefined'
              : 'fixedCalendarPeriod',
          userDefinedNextDate: schedule.cycleType == CycleType.custom
              ? schedule.nextDueDate
              : null,
          createdAt: schedule.startDate,
          updatedAt: schedule.startDate,
        ),
      );
    }

    final scheduleById = {for (final value in schedules) value.id: value};
    final taskRows = tasks
        .map((task) {
          final schedule = task.scheduleId.isEmpty
              ? null
              : scheduleById[task.scheduleId];
          final isReminder = schedule?.cardId == _manualReminderCardId;
          return TaskRow(
            id: task.id,
            itemId: task.itemId,
            sourceType: schedule == null
                ? 'unknown'
                : isReminder
                ? 'scheduledReminder'
                : 'scheduledMaintenance',
            scheduleId: schedule?.id,
            maintenancePlanId: schedule == null
                ? null
                : planIdBySchedule[task.scheduleId],
            generalReminderId: schedule == null
                ? null
                : reminderIdBySchedule[task.scheduleId],
            legacyCardId: task.cardId,
            title: task.title,
            dueDate: task.dueDate,
            status: task.status.name,
            completedAt: task.completedAt,
            postponedAt: task.postponedAt,
            createdAt: task.dueDate,
            updatedAt: task.completedAt ?? task.postponedAt ?? task.dueDate,
          );
        })
        .toList(growable: false);

    final taskById = {for (final value in tasks) value.id: value};
    final recordRows = records
        .map((record) {
          final task = record.taskId == null ? null : taskById[record.taskId];
          return MaintenanceRecordRow(
            id: record.id,
            itemId: record.itemId,
            taskId: record.taskId?.isEmpty == true ? null : record.taskId,
            maintenancePlanId: task == null
                ? null
                : planIdBySchedule[task.scheduleId],
            recordType: record.recordType.name,
            date: record.date,
            title: record.title,
            issueDescription: record.issueDescription,
            workDescription: record.workDescription,
            partsChanged: jsonEncode(record.partsChanged),
            cost: record.cost,
            vendorName: record.vendorName,
            warrantyUntil: record.warrantyUntil,
            result: record.result,
            note: record.note,
            createdAt: record.createdAt,
          );
        })
        .toList(growable: false);

    final attachments = <AttachmentRow>[];
    for (final item in items) {
      final identifier = item.photoPath;
      if (identifier != null && identifier.isNotEmpty) {
        attachments.add(
          _legacyAttachment(
            id: 'legacy-item-photo-${item.id}',
            ownerType: 'item',
            ownerId: item.id,
            storageIdentifier: identifier,
            createdAt: item.createdAt,
          ),
        );
      }
    }
    for (final record in records) {
      for (var index = 0; index < record.photos.length; index += 1) {
        attachments.add(
          _legacyAttachment(
            id: 'legacy-record-photo-${record.id}-$index',
            ownerType: 'maintenanceRecord',
            ownerId: record.id,
            storageIdentifier: record.photos[index],
            createdAt: record.createdAt,
          ),
        );
      }
    }

    return _ImportPlan(
      categories: categories,
      items: itemRows,
      plans: planRows,
      steps: stepRows,
      reminders: reminderRows,
      schedules: scheduleRows,
      tasks: taskRows,
      records: recordRows,
      attachments: attachments,
    );
  }

  (String, String) _categoryMapping(ItemCategory category) =>
      switch (category) {
        ItemCategory.appliance => ('homeAndAppliance', '家電與居家設備'),
        ItemCategory.vehicle => ('vehicleAndTransport', '車輛與交通'),
        ItemCategory.house => ('houseAndRepair', '房屋與修繕'),
        ItemCategory.warrantyDocument => ('documentAndContract', '文件與合約'),
        ItemCategory.other => ('other', '其他'),
      };

  MaintenancePlanType _planType(MaintenanceType type) => switch (type) {
    MaintenanceType.cleaning => MaintenancePlanType.cleaning,
    MaintenanceType.inspection => MaintenancePlanType.inspection,
    MaintenanceType.replacement => MaintenancePlanType.replacement,
    MaintenanceType.expiryReminder => MaintenancePlanType.expiryReview,
    MaintenanceType.repairRecord ||
    MaintenanceType.constructionRecord => MaintenancePlanType.custom,
  };

  MaintenancePlanStatus _planStatus(ScheduleStatus status) => switch (status) {
    ScheduleStatus.active => MaintenancePlanStatus.active,
    ScheduleStatus.paused => MaintenancePlanStatus.paused,
    ScheduleStatus.ended => MaintenancePlanStatus.archived,
  };

  AttachmentRow _legacyAttachment({
    required String id,
    required String ownerType,
    required String ownerId,
    required String storageIdentifier,
    required DateTime createdAt,
  }) => AttachmentRow(
    schemaVersion: 1,
    id: id,
    ownerType: ownerType,
    ownerId: ownerId,
    kind: 'photo',
    storageIdentifier:
        'legacy-unverified:${sha256.convert(utf8.encode(storageIdentifier))}',
    state: 'unknown',
    note: 'SharedPreferences 舊照片識別（未驗證）：$storageIdentifier',
    createdAt: createdAt,
  );

  Future<List<LegacyDriftImportIssue>> _databaseIssues() async {
    final issues = <LegacyDriftImportIssue>[];
    final foreignKeys = await _database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    if (foreignKeys.isNotEmpty) {
      issues.add(
        LegacyDriftImportIssue(
          code: 'foreign-key-violations',
          message: 'Drift 目前有 ${foreignKeys.length} 筆外鍵違規。',
        ),
      );
    }
    final integrity = await _database
        .customSelect('PRAGMA integrity_check')
        .get();
    final values = integrity
        .expand((row) => row.data.values)
        .map((value) => '$value')
        .toList();
    if (values.length != 1 || values.single.toLowerCase() != 'ok') {
      issues.add(
        const LegacyDriftImportIssue(
          code: 'integrity-check-failed',
          message: 'Drift 完整性檢查未通過。',
        ),
      );
    }
    return issues;
  }

  Future<_TargetAssessment> _assessTarget(
    _ImportPlan plan, {
    bool allowVerifiedPlanningMutations = false,
  }) async {
    final issues = <LegacyDriftImportIssue>[];
    final replaceable = <String>{};
    var exact = 0;
    var missing = 0;

    Future<void> assess<T>(
      List<T> expected,
      Future<List<T>> Function() load,
    ) async {
      if (expected.isEmpty) return;
      final existing = await load();
      final byId = <String, T>{for (final row in existing) _rowId(row): row};
      for (final row in expected) {
        final id = _rowId(row);
        final current = byId[id];
        if (current == null) {
          missing += 1;
        } else if (current == row) {
          exact += 1;
        } else if (allowVerifiedPlanningMutations &&
            _hasSamePlanningIdentity(row, current)) {
          exact += 1;
        } else if (row is ItemRow &&
            current is ItemRow &&
            _isLegacyPlaceholder(current)) {
          replaceable.add(id);
          missing += 1;
        } else {
          issues.add(
            LegacyDriftImportIssue(
              code: 'target-id-conflict',
              message: 'Drift 已有相同 ID 但內容不同，禁止覆蓋。',
              entryId: id,
            ),
          );
        }
      }
    }

    await assess(
      plan.categories,
      () => _database.select(_database.itemCategories).get(),
    );
    await assess(plan.items, () => _database.select(_database.items).get());
    await assess(
      plan.plans,
      () => _database.select(_database.maintenancePlans).get(),
    );
    await assess(
      plan.steps,
      () => _database.select(_database.maintenancePlanSteps).get(),
    );
    await assess(
      plan.reminders,
      () => _database.select(_database.generalReminders).get(),
    );
    await assess(
      plan.schedules,
      () => _database.select(_database.schedules).get(),
    );
    await assess(plan.tasks, () => _database.select(_database.tasks).get());
    await assess(
      plan.records,
      () => _database.select(_database.maintenanceRecords).get(),
    );
    await assess(
      plan.attachments,
      () => _database.select(_database.attachments).get(),
    );

    if (issues.isNotEmpty || (exact > 0 && missing > 0)) {
      if (issues.isEmpty) {
        issues.add(
          const LegacyDriftImportIssue(
            code: 'partial-import-detected',
            message: 'Drift 只含部分匯入資料，禁止補寫或覆蓋。',
          ),
        );
      }
      return _TargetAssessment(
        status: LegacyDriftImportStatus.blocked,
        issues: issues,
        replaceableItemIds: replaceable,
      );
    }
    if (missing == 0) {
      return _TargetAssessment(
        status: LegacyDriftImportStatus.alreadyImported,
        replaceableItemIds: replaceable,
      );
    }
    return _TargetAssessment(
      status: LegacyDriftImportStatus.ready,
      replaceableItemIds: replaceable,
    );
  }

  String _rowId(Object? row) => switch (row) {
    ItemCategoryRow value => value.id,
    ItemRow value => value.id,
    MaintenancePlanRow value => value.id,
    MaintenancePlanStepRow value => value.id,
    GeneralReminderRow value => value.id,
    ScheduleRow value => value.id,
    TaskRow value => value.id,
    MaintenanceRecordRow value => value.id,
    AttachmentRow value => value.id,
    _ => throw ArgumentError.value(row, 'row'),
  };

  bool _hasSamePlanningIdentity(Object? expected, Object? current) {
    if (expected is MaintenancePlanRow && current is MaintenancePlanRow) {
      return expected.id == current.id &&
          expected.itemId == current.itemId &&
          expected.templateCardId == current.templateCardId &&
          expected.createdAt == current.createdAt;
    }
    if (expected is MaintenancePlanStepRow &&
        current is MaintenancePlanStepRow) {
      return expected.id == current.id &&
          expected.maintenancePlanId == current.maintenancePlanId;
    }
    if (expected is GeneralReminderRow && current is GeneralReminderRow) {
      return expected.id == current.id &&
          expected.itemId == current.itemId &&
          expected.createdAt == current.createdAt;
    }
    if (expected is ScheduleRow && current is ScheduleRow) {
      return expected.id == current.id &&
          expected.itemId == current.itemId &&
          expected.sourceType == current.sourceType &&
          expected.maintenancePlanId == current.maintenancePlanId &&
          expected.generalReminderId == current.generalReminderId &&
          expected.milestoneId == current.milestoneId &&
          expected.legacyCardId == current.legacyCardId &&
          expected.createdAt == current.createdAt;
    }
    return false;
  }

  bool _isLegacyPlaceholder(ItemRow row) =>
      row.categoryId == _legacyCategoryId &&
      row.name == '舊資料項目 ${row.id}' &&
      row.note == _legacyItemNote;

  Future<void> _writePlan(
    _ImportPlan plan,
    Set<String> replaceableItemIds,
  ) async {
    for (final row in plan.categories) {
      await _database.into(_database.itemCategories).insert(row);
    }
    for (final row in plan.items) {
      if (replaceableItemIds.contains(row.id)) {
        await (_database.update(_database.items)
              ..where((table) => table.id.equals(row.id)))
            .write(row.toCompanion(false));
      } else {
        await _database.into(_database.items).insert(row);
      }
    }
    for (final row in plan.plans) {
      await _database.into(_database.maintenancePlans).insert(row);
    }
    for (final row in plan.steps) {
      await _database.into(_database.maintenancePlanSteps).insert(row);
    }
    for (final row in plan.reminders) {
      await _database.into(_database.generalReminders).insert(row);
    }
    for (final row in plan.schedules) {
      await _database.into(_database.schedules).insert(row);
    }
    for (final row in plan.tasks) {
      await _database.into(_database.tasks).insert(row);
    }
    for (final row in plan.records) {
      await _database.into(_database.maintenanceRecords).insert(row);
    }
    for (final row in plan.attachments) {
      await _database.into(_database.attachments).insert(row);
    }
  }
}

class _Preparation {
  _Preparation({
    required this.sourceDigests,
    required this.sourceByteLengths,
    required this.sourceCounts,
    required this.validSourceCounts,
    required this.issues,
    required this.plan,
  });

  final Map<String, String> sourceDigests;
  final Map<String, int> sourceByteLengths;
  final Map<String, int> sourceCounts;
  final Map<String, int> validSourceCounts;
  final List<LegacyDriftImportIssue> issues;
  final _ImportPlan? plan;

  LegacyDriftImportReport report(
    LegacyDriftImportStatus status, {
    List<LegacyDriftImportIssue> extraIssues = const [],
  }) => LegacyDriftImportReport(
    status: extraIssues.isEmpty ? status : LegacyDriftImportStatus.blocked,
    sourceDigests: Map.unmodifiable(sourceDigests),
    sourceByteLengths: Map.unmodifiable(sourceByteLengths),
    sourceCounts: Map.unmodifiable(sourceCounts),
    validSourceCounts: Map.unmodifiable(validSourceCounts),
    targetCounts: Map.unmodifiable(plan?.counts ?? const <String, int>{}),
    issues: List.unmodifiable(<LegacyDriftImportIssue>[
      ...issues,
      ...extraIssues,
    ]),
  );
}

class _ImportPlan {
  const _ImportPlan({
    required this.categories,
    required this.items,
    required this.plans,
    required this.steps,
    required this.reminders,
    required this.schedules,
    required this.tasks,
    required this.records,
    required this.attachments,
  });

  final List<ItemCategoryRow> categories;
  final List<ItemRow> items;
  final List<MaintenancePlanRow> plans;
  final List<MaintenancePlanStepRow> steps;
  final List<GeneralReminderRow> reminders;
  final List<ScheduleRow> schedules;
  final List<TaskRow> tasks;
  final List<MaintenanceRecordRow> records;
  final List<AttachmentRow> attachments;

  Map<String, int> get counts => <String, int>{
    'item_categories': categories.length,
    'items': items.length,
    'maintenance_plans': plans.length,
    'maintenance_plan_steps': steps.length,
    'general_reminders': reminders.length,
    'schedules': schedules.length,
    'tasks': tasks.length,
    'maintenance_records': records.length,
    'attachments': attachments.length,
  };
}

class _TargetAssessment {
  const _TargetAssessment({
    required this.status,
    this.issues = const <LegacyDriftImportIssue>[],
    this.replaceableItemIds = const <String>{},
  });

  final LegacyDriftImportStatus status;
  final List<LegacyDriftImportIssue> issues;
  final Set<String> replaceableItemIds;
}
