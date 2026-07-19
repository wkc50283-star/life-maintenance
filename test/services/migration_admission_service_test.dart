import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/migration_admission_report.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/services/legacy_relation_audit_service.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:life_maintenance/services/migration_admission_service.dart';
import 'package:life_maintenance/services/migration_readiness_service.dart';

class _ReadOnlyStorage extends LocalStorageService {
  _ReadOnlyStorage(this.values);

  final Map<String, String> values;

  @override
  Future<String?> readString(String key) async => values[key];
}

void main() {
  final now = DateTime.utc(2026, 7, 18);

  Map<String, String> validValues() {
    final item = Item(
      id: 'item-1',
      name: '冷氣',
      category: ItemCategory.appliance,
      createdAt: now,
    );
    final schedule = Schedule(
      id: 'schedule-1',
      itemId: item.id,
      cardId: 'card-aircon-filter-cleaning',
      cycleType: CycleType.monthly,
      interval: 1,
      startDate: now,
      nextDueDate: now,
    );
    final task = Task(
      id: 'task-1',
      itemId: item.id,
      cardId: schedule.cardId,
      scheduleId: schedule.id,
      title: '冷氣濾網清洗',
      dueDate: now,
    );
    final record = MaintenanceRecord(
      id: 'record-1',
      itemId: item.id,
      taskId: task.id,
      recordType: RecordType.regularMaintenance,
      date: now,
      title: '冷氣濾網已清洗',
      createdAt: now,
    );

    final sources = <String, String>{
      'items': jsonEncode([item.toJson()]),
      'schedules': jsonEncode([schedule.toJson()]),
      'tasks': jsonEncode([task.toJson()]),
      'maintenance_records': jsonEncode([record.toJson()]),
    };
    final values = <String, String>{...sources};
    for (final entry in LocalDataBackupService.backupKeys.entries) {
      values[entry.value] = sources[entry.key]!;
    }
    return values;
  }

  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  Future<void> seedItem(String itemId) async {
    await database
        .into(database.itemCategories)
        .insert(
          ItemCategoriesCompanion.insert(
            id: 'category-$itemId',
            systemCode: const Value('appliance'),
            displayName: '家電',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: itemId,
            name: '冷氣',
            categoryId: 'category-$itemId',
            createdAt: now,
            updatedAt: now,
            status: 'active',
          ),
        );
  }

  MigrationAdmissionService serviceFor(_ReadOnlyStorage storage) {
    return MigrationAdmissionService(
      readinessService: MigrationReadinessService(
        storageService: storage,
        database: database,
      ),
      relationAuditService: LegacyRelationAuditService(storage),
    );
  }

  test('admits only a fully backed-up valid graph with empty Drift', () async {
    final storage = _ReadOnlyStorage(validValues());

    final report = await serviceFor(storage).inspect();

    expect(report.isAdmittedForDryRun, isTrue);
    expect(report.isBlocked, isFalse);
    expect(report.blockers, isEmpty);
  });

  test('returns every applicable blocker without repairing data', () async {
    final values = validValues();
    final duplicateItem = Item(
      id: 'item-1',
      name: '重複冷氣',
      category: ItemCategory.appliance,
      createdAt: now,
    ).toJson();
    values['items'] = jsonEncode([
      duplicateItem,
      duplicateItem,
      'broken-entry',
    ]);
    values.remove('backup_v1_items');
    values['tasks'] = jsonEncode([
      Task(
        id: 'task-1',
        itemId: 'missing-item',
        cardId: 'card-1',
        scheduleId: 'missing-schedule',
        title: '斷裂任務',
        dueDate: now,
      ).toJson(),
    ]);
    final storage = _ReadOnlyStorage(values);

    final report = await serviceFor(storage).inspect();

    expect(report.isBlocked, isTrue);
    expect(
      report.blockers,
      containsAll(<MigrationAdmissionBlocker>{
        MigrationAdmissionBlocker.incompleteOrMismatchedBackup,
        MigrationAdmissionBlocker.invalidLegacyEntries,
        MigrationAdmissionBlocker.duplicateLegacyIds,
        MigrationAdmissionBlocker.danglingLegacyRelations,
      }),
    );
  });

  test('blocks an unreadable source separately', () async {
    final values = validValues();
    values['items'] = '{broken-json';
    final storage = _ReadOnlyStorage(values);

    final report = await serviceFor(storage).inspect();

    expect(
      report.blockers,
      contains(MigrationAdmissionBlocker.unreadableSourceData),
    );
    expect(report.isAdmittedForDryRun, isFalse);
  });

  test('blocks when Drift target tables already contain data', () async {
    await seedItem('item-1');
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
            createdAt: now,
            updatedAt: now,
          ),
        );
    final storage = _ReadOnlyStorage(validValues());

    final report = await serviceFor(storage).inspect();

    expect(
      report.blockers,
      contains(MigrationAdmissionBlocker.nonEmptyDriftTarget),
    );
    expect(report.isBlocked, isTrue);
  });
}
