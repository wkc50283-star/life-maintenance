import 'dart:convert';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/legacy_drift_import_report.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/services/legacy_drift_import_service.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';

class _MemorySource implements LegacyImportSource {
  _MemorySource(this.values);

  final Map<String, String> values;
  final List<String> reads = <String>[];

  @override
  Future<String?> readString(String key) async {
    reads.add(key);
    return values[key];
  }
}

void main() {
  final createdAt = DateTime.utc(2026, 7, 1, 8);
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() => database.close());

  Map<String, String> fixture({
    String maintenanceCardId = 'card-aircon-filter-cleaning',
  }) {
    final item = Item(
      id: 'item-1',
      name: '客廳冷氣',
      category: ItemCategory.appliance,
      photoPath: 'legacy/photos/aircon.jpg',
      createdAt: createdAt,
      purchaseDate: DateTime.utc(2024, 1, 2),
      warrantyEndDate: DateTime.utc(2027, 1, 2),
      expectedLifeYears: 10,
      location: '客廳',
      note: '保留原始備註',
    );
    final maintenanceSchedule = Schedule(
      id: 'schedule-maintenance',
      itemId: item.id,
      cardId: maintenanceCardId,
      cycleType: CycleType.monthly,
      interval: 1,
      startDate: createdAt,
      nextDueDate: DateTime.utc(2026, 8, 1, 8),
      title: '每月清洗濾網',
      reminderTime: '08:30',
    );
    final reminderSchedule = Schedule(
      id: 'schedule-reminder',
      itemId: item.id,
      cardId: 'manual-expiry-reminder',
      cycleType: CycleType.custom,
      interval: 1,
      startDate: createdAt,
      nextDueDate: DateTime.utc(2027, 1, 2),
      title: '保固到期',
    );
    final maintenanceTask = Task(
      id: 'task-maintenance',
      itemId: item.id,
      cardId: maintenanceSchedule.cardId,
      scheduleId: maintenanceSchedule.id,
      title: '清洗濾網',
      dueDate: DateTime.utc(2026, 8, 1, 8),
      status: TaskStatus.completed,
      completedAt: DateTime.utc(2026, 8, 2, 9),
      overdue: true,
    );
    final reminderTask = Task(
      id: 'task-reminder',
      itemId: item.id,
      cardId: reminderSchedule.cardId,
      scheduleId: reminderSchedule.id,
      title: '確認保固',
      dueDate: DateTime.utc(2027, 1, 2),
    );
    final record = MaintenanceRecord(
      id: 'record-1',
      itemId: item.id,
      taskId: maintenanceTask.id,
      recordType: RecordType.regularMaintenance,
      date: maintenanceTask.completedAt!,
      title: '濾網已清洗',
      workDescription: '清洗並晾乾後裝回',
      partsChanged: const <String>['濾網棉'],
      cost: 300,
      vendorName: '安心冷氣行',
      result: '運轉正常',
      photos: const <String>['legacy/photos/result.jpg'],
      note: '下次留意異音',
      createdAt: maintenanceTask.completedAt!,
    );
    final sources = <String, String>{
      'items': jsonEncode(<Object>[item.toJson()]),
      'schedules': jsonEncode(<Object>[
        maintenanceSchedule.toJson(),
        reminderSchedule.toJson(),
      ]),
      'tasks': jsonEncode(<Object>[
        maintenanceTask.toJson(),
        reminderTask.toJson(),
      ]),
      'maintenance_records': jsonEncode(<Object>[record.toJson()]),
    };
    return <String, String>{
      ...sources,
      for (final entry in LocalDataBackupService.backupKeys.entries)
        entry.value: sources[entry.key]!,
    };
  }

  LegacyDriftImportService service(Map<String, String> values) =>
      LegacyDriftImportService(
        database: database,
        source: _MemorySource(values),
      );

  test('dry-run maps every legacy dataset without writing Drift', () async {
    final report = await service(fixture()).dryRun();

    expect(report.status, LegacyDriftImportStatus.ready);
    expect(report.issues, isEmpty);
    expect(report.sourceCounts, <String, int>{
      'items': 1,
      'schedules': 2,
      'tasks': 2,
      'maintenance_records': 1,
    });
    expect(report.sourceDigests.values, everyElement(startsWith('sha256:')));
    expect(report.sourceByteLengths.values, everyElement(greaterThan(0)));
    expect(report.validSourceCounts, report.sourceCounts);
    expect(report.targetCounts['maintenance_plans'], 1);
    expect(report.targetCounts['general_reminders'], 1);
    expect(report.targetCounts['attachments'], 2);
    expect(await database.select(database.items).get(), isEmpty);
    expect(await database.select(database.tasks).get(), isEmpty);
  });

  test(
    'imports the graph atomically and preserves legacy field evidence',
    () async {
      final report = await service(
        fixture(),
      ).execute(sourceWritesAreDisabled: true);

      expect(report.status, LegacyDriftImportStatus.imported);
      final item = (await database.select(database.items).get()).single;
      expect(item.name, '客廳冷氣');
      expect(item.note, '保留原始備註');
      expect(item.expectedLifeYears, 10);

      final plans = await database.select(database.maintenancePlans).get();
      expect(plans.single.templateCardId, 'card-aircon-filter-cleaning');
      expect(plans.single.title, '每月清洗濾網');
      expect(
        await database.select(database.maintenancePlanSteps).get(),
        hasLength(3),
      );

      final schedules = await database.select(database.schedules).get();
      final maintenance = schedules.singleWhere(
        (row) => row.id == 'schedule-maintenance',
      );
      final reminder = schedules.singleWhere(
        (row) => row.id == 'schedule-reminder',
      );
      expect(maintenance.sourceType, 'maintenancePlan');
      expect(maintenance.anchorPolicy, 'fixedCalendarPeriod');
      expect(reminder.sourceType, 'generalReminder');
      expect(reminder.anchorPolicy, 'userDefined');
      expect(reminder.userDefinedNextDate, reminder.nextDueDate);

      final tasks = await database.select(database.tasks).get();
      expect(
        tasks.singleWhere((row) => row.id == 'task-maintenance').sourceType,
        'scheduledMaintenance',
      );
      expect(
        tasks.singleWhere((row) => row.id == 'task-reminder').sourceType,
        'scheduledReminder',
      );
      final record =
          (await database.select(database.maintenanceRecords).get()).single;
      expect(jsonDecode(record.partsChanged!), <String>['濾網棉']);
      expect(record.maintenancePlanId, plans.single.id);

      final attachments = await database.select(database.attachments).get();
      expect(attachments, hasLength(2));
      expect(attachments.every((row) => row.state == 'unknown'), isTrue);
      expect(
        attachments.map((row) => row.note),
        containsAll(<String>[
          'SharedPreferences 舊照片識別（未驗證）：legacy/photos/aircon.jpg',
          'SharedPreferences 舊照片識別（未驗證）：legacy/photos/result.jpg',
        ]),
      );
      expect(
        attachments.every(
          (row) => row.storageIdentifier.startsWith('legacy-unverified:'),
        ),
        isTrue,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test('a repeated import is a no-op and never duplicates rows', () async {
    final importer = service(fixture());
    await importer.execute(sourceWritesAreDisabled: true);

    final repeated = await importer.execute(sourceWritesAreDisabled: true);

    expect(repeated.status, LegacyDriftImportStatus.alreadyImported);
    expect(await database.select(database.items).get(), hasLength(1));
    expect(await database.select(database.schedules).get(), hasLength(2));
    expect(await database.select(database.tasks).get(), hasLength(2));
    expect(
      await database.select(database.maintenanceRecords).get(),
      hasLength(1),
    );
  });

  test(
    'blocks missing backup, unknown card, and active source writes',
    () async {
      final missingBackup = fixture()..remove('backup_v1_items');
      final backupReport = await service(missingBackup).dryRun();
      expect(backupReport.isBlocked, isTrue);
      expect(
        backupReport.issues.map((issue) => issue.code),
        contains('backup-missing'),
      );

      final unknownReport = await service(
        fixture(maintenanceCardId: 'unknown-card'),
      ).dryRun();
      expect(unknownReport.isBlocked, isTrue);
      expect(
        unknownReport.issues.map((issue) => issue.code),
        contains('unknown-card-id'),
      );

      await expectLater(
        service(fixture()).execute(sourceWritesAreDisabled: false),
        throwsA(
          isA<LegacyDriftImportException>().having(
            (error) => error.report.issues.map((issue) => issue.code),
            'issue codes',
            contains('source-not-frozen'),
          ),
        ),
      );
      expect(await database.select(database.items).get(), isEmpty);
    },
  );

  test(
    'blocks a damaged entry without importing the readable entries',
    () async {
      final values = fixture();
      final decodedItems = jsonDecode(values['items']!) as List<dynamic>;
      decodedItems.add(<String, Object?>{
        'id': 'item-broken',
        'name': '未知分類項目',
        'category': 'future-category',
        'createdAt': createdAt.toIso8601String(),
      });
      values['items'] = jsonEncode(decodedItems);
      values['backup_v1_items'] = values['items']!;

      final report = await service(values).dryRun();

      expect(report.isBlocked, isTrue);
      expect(
        report.issues.map((issue) => issue.code),
        contains('invalid-entry'),
      );
      expect(await database.select(database.items).get(), isEmpty);
    },
  );

  test(
    'preserves a task without schedule as an unknown legacy reminder',
    () async {
      final values = fixture();
      final decodedTasks = jsonDecode(values['tasks']!) as List<dynamic>;
      decodedTasks.add(
        Task(
          id: 'task-without-schedule',
          itemId: 'item-1',
          cardId: 'legacy-manual-card',
          scheduleId: '',
          title: '舊版手動提醒',
          dueDate: DateTime.utc(2026, 9, 1),
        ).toJson(),
      );
      values['tasks'] = jsonEncode(decodedTasks);
      values['backup_v1_tasks'] = values['tasks']!;

      await service(values).execute(sourceWritesAreDisabled: true);

      final task = (await database.select(database.tasks).get()).singleWhere(
        (row) => row.id == 'task-without-schedule',
      );
      expect(task.sourceType, 'unknown');
      expect(task.scheduleId, isNull);
      expect(task.legacyCardId, 'legacy-manual-card');
    },
  );

  test('rolls back every inserted row when a mid-import write fails', () async {
    await database.customStatement('''
      CREATE TRIGGER reject_legacy_task
      BEFORE INSERT ON tasks
      BEGIN
        SELECT RAISE(ABORT, 'forced task failure');
      END
    ''');

    await expectLater(
      service(fixture()).execute(sourceWritesAreDisabled: true),
      throwsA(anything),
    );

    expect(await database.select(database.itemCategories).get(), isEmpty);
    expect(await database.select(database.items).get(), isEmpty);
    expect(await database.select(database.maintenancePlans).get(), isEmpty);
    expect(await database.select(database.generalReminders).get(), isEmpty);
    expect(await database.select(database.schedules).get(), isEmpty);
    expect(await database.select(database.tasks).get(), isEmpty);
    expect(await database.select(database.maintenanceRecords).get(), isEmpty);
    expect(await database.select(database.attachments).get(), isEmpty);
  });

  test(
    'replaces only a schema-v1 placeholder and preserves its WorkCase',
    () async {
      await database
          .into(database.itemCategories)
          .insert(
            ItemCategoriesCompanion.insert(
              id: 'system-category-legacy-imported',
              systemCode: const Value('legacyImported'),
              displayName: '舊資料匯入',
              sortOrder: const Value(999),
              status: 'active',
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item-1',
              name: '舊資料項目 item-1',
              categoryId: 'system-category-legacy-imported',
              createdAt: createdAt,
              updatedAt: createdAt,
              note: const Value('由 schema v1 案件資料自動建立；名稱可由使用者後續修正。'),
              status: 'active',
            ),
          );
      await database
          .into(database.workCases)
          .insert(
            WorkCasesCompanion.insert(
              id: 'case-1',
              itemId: 'item-1',
              sourceType: WorkCaseSourceType.manual,
              caseType: WorkCaseType.repair,
              title: '既有案件',
              status: WorkCaseStatus.inProgress,
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          );

      final report = await service(
        fixture(),
      ).execute(sourceWritesAreDisabled: true);

      expect(report.status, LegacyDriftImportStatus.imported);
      expect((await database.select(database.items).get()).length, 1);
      expect((await database.select(database.items).get()).single.name, '客廳冷氣');
      expect(await database.select(database.workCases).get(), hasLength(1));
      expect(
        (await database.select(database.workCases).get()).single.id,
        'case-1',
      );
    },
  );

  test('blocks a conflicting Drift row without overwriting it', () async {
    await database
        .into(database.itemCategories)
        .insert(
          ItemCategoriesCompanion.insert(
            id: 'other-category',
            systemCode: const Value('other'),
            displayName: '其他',
            status: 'active',
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-1',
            name: 'Drift 既有資料',
            categoryId: 'other-category',
            createdAt: createdAt,
            updatedAt: createdAt,
            status: 'active',
          ),
        );

    final report = await service(fixture()).dryRun();

    expect(report.isBlocked, isTrue);
    expect(
      report.issues.map((issue) => issue.code),
      contains('target-id-conflict'),
    );
    expect(
      (await database.select(database.items).get()).single.name,
      'Drift 既有資料',
    );
  });
}
