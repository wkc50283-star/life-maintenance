import 'dart:convert';

import '../models/item.dart';
import '../models/legacy_relation_audit_report.dart';
import '../models/maintenance_record.dart';
import '../models/schedule.dart';
import '../models/task.dart';
import 'local_storage_service.dart';

class LegacyRelationAuditService {
  const LegacyRelationAuditService(this._storageService);

  static const List<String> _storageKeys = <String>[
    'items',
    'schedules',
    'tasks',
    'maintenance_records',
  ];

  final LocalStorageService _storageService;

  Future<LegacyRelationAuditReport> inspect() async {
    final datasetAudits = <String, LegacyDatasetAudit>{};
    final relationIssues = <LegacyRelationIssue>[];

    final itemsResult = await _parseDataset<Item>(
      storageKey: 'items',
      parser: Item.fromJson,
      idOf: (item) => item.id,
    );
    datasetAudits['items'] = itemsResult.audit;

    final schedulesResult = await _parseDataset<Schedule>(
      storageKey: 'schedules',
      parser: Schedule.fromJson,
      idOf: (schedule) => schedule.id,
    );
    datasetAudits['schedules'] = schedulesResult.audit;

    final tasksResult = await _parseDataset<Task>(
      storageKey: 'tasks',
      parser: Task.fromJson,
      idOf: (task) => task.id,
    );
    datasetAudits['tasks'] = tasksResult.audit;

    final recordsResult = await _parseDataset<MaintenanceRecord>(
      storageKey: 'maintenance_records',
      parser: MaintenanceRecord.fromJson,
      idOf: (record) => record.id,
    );
    datasetAudits['maintenance_records'] = recordsResult.audit;

    final itemIds = itemsResult.entries.map((item) => item.id).toSet();
    final scheduleIds = schedulesResult.entries.map((schedule) => schedule.id).toSet();
    final taskIds = tasksResult.entries.map((task) => task.id).toSet();

    for (final schedule in schedulesResult.entries) {
      _checkReference(
        relationIssues: relationIssues,
        datasetKey: 'schedules',
        entryId: schedule.id,
        fieldName: 'itemId',
        referenceId: schedule.itemId,
        validIds: itemIds,
      );
    }

    for (final task in tasksResult.entries) {
      _checkReference(
        relationIssues: relationIssues,
        datasetKey: 'tasks',
        entryId: task.id,
        fieldName: 'itemId',
        referenceId: task.itemId,
        validIds: itemIds,
      );
      _checkReference(
        relationIssues: relationIssues,
        datasetKey: 'tasks',
        entryId: task.id,
        fieldName: 'scheduleId',
        referenceId: task.scheduleId,
        validIds: scheduleIds,
      );
    }

    for (final record in recordsResult.entries) {
      _checkReference(
        relationIssues: relationIssues,
        datasetKey: 'maintenance_records',
        entryId: record.id,
        fieldName: 'itemId',
        referenceId: record.itemId,
        validIds: itemIds,
      );
      final taskId = record.taskId;
      if (taskId != null && taskId.isNotEmpty) {
        _checkReference(
          relationIssues: relationIssues,
          datasetKey: 'maintenance_records',
          entryId: record.id,
          fieldName: 'taskId',
          referenceId: taskId,
          validIds: taskIds,
        );
      }
    }

    return LegacyRelationAuditReport(
      datasets: datasetAudits,
      relationIssues: relationIssues,
    );
  }

  Future<_ParsedDataset<T>> _parseDataset<T>({
    required String storageKey,
    required T Function(Map<String, dynamic>) parser,
    required String Function(T) idOf,
  }) async {
    final rawValue = await _storageService.readString(storageKey);
    final decoded = _decodeList(rawValue);
    if (decoded == null) {
      return _ParsedDataset<T>(
        entries: const <T>[],
        audit: LegacyDatasetAudit(
          storageKey: storageKey,
          rawEntryCount: rawValue == null ? 0 : 1,
          validEntryCount: 0,
          invalidEntryCount: rawValue == null ? 0 : 1,
          duplicateIds: const <String>{},
        ),
      );
    }

    final entries = <T>[];
    final seenIds = <String>{};
    final duplicateIds = <String>{};
    var invalidEntryCount = 0;

    for (final rawEntry in decoded) {
      if (rawEntry is! Map) {
        invalidEntryCount += 1;
        continue;
      }

      try {
        final entry = parser(Map<String, dynamic>.from(rawEntry));
        final id = idOf(entry);
        if (!seenIds.add(id)) {
          duplicateIds.add(id);
        }
        entries.add(entry);
      } catch (_) {
        invalidEntryCount += 1;
      }
    }

    return _ParsedDataset<T>(
      entries: List<T>.unmodifiable(entries),
      audit: LegacyDatasetAudit(
        storageKey: storageKey,
        rawEntryCount: decoded.length,
        validEntryCount: entries.length,
        invalidEntryCount: invalidEntryCount,
        duplicateIds: Set<String>.unmodifiable(duplicateIds),
      ),
    );
  }

  List<dynamic>? _decodeList(String? rawValue) {
    if (rawValue == null) {
      return const <dynamic>[];
    }

    try {
      final decoded = jsonDecode(rawValue);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  void _checkReference({
    required List<LegacyRelationIssue> relationIssues,
    required String datasetKey,
    required String entryId,
    required String fieldName,
    required String referenceId,
    required Set<String> validIds,
  }) {
    if (validIds.contains(referenceId)) {
      return;
    }

    relationIssues.add(
      LegacyRelationIssue(
        datasetKey: datasetKey,
        entryId: entryId,
        fieldName: fieldName,
        missingReferenceId: referenceId,
      ),
    );
  }
}

class _ParsedDataset<T> {
  const _ParsedDataset({required this.entries, required this.audit});

  final List<T> entries;
  final LegacyDatasetAudit audit;
}
