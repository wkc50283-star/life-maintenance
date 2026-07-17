import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:life_maintenance/services/migration_readiness_service.dart';

class _RecordingStorageService extends LocalStorageService {
  _RecordingStorageService(this.values);

  final Map<String, String> values;
  int saveCalls = 0;
  int removeCalls = 0;

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> saveString(String key, String value) async {
    saveCalls += 1;
    throw StateError('Migration readiness inspection must remain read-only');
  }

  @override
  Future<void> remove(String key) async {
    removeCalls += 1;
    throw StateError('Migration readiness inspection must remain read-only');
  }
}

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('reports matching source and backup lists without writing', () async {
    final values = <String, String>{};
    for (final entry in LocalDataBackupService.backupKeys.entries) {
      final raw = entry.key == 'items' ? '[{"id":"item-1"}]' : '[]';
      values[entry.key] = raw;
      values[entry.value] = raw;
    }
    final storage = _RecordingStorageService(values);

    final report = await MigrationReadinessService(
      storageService: storage,
      database: database,
    ).inspect();

    expect(report.datasets, hasLength(4));
    expect(report.allSourceDataReadable, isTrue);
    expect(report.allExistingSourcesBackedUp, isTrue);
    expect(report.driftIsEmpty, isTrue);
    expect(report.datasets.firstWhere((data) => data.sourceKey == 'items').sourceCount, 1);
    expect(storage.saveCalls, 0);
    expect(storage.removeCalls, 0);
  });

  test('reports missing backup without creating one', () async {
    final storage = _RecordingStorageService({
      'items': '[{"id":"item-1"}]',
      'schedules': '[]',
      'backup_v1_schedules': '[]',
      'tasks': '[]',
      'backup_v1_tasks': '[]',
      'maintenance_records': '[]',
      'backup_v1_maintenance_records': '[]',
    });

    final report = await MigrationReadinessService(
      storageService: storage,
      database: database,
    ).inspect();
    final items = report.datasets.firstWhere((data) => data.sourceKey == 'items');

    expect(items.sourceExists, isTrue);
    expect(items.backupExists, isFalse);
    expect(items.rawValuesMatch, isNull);
    expect(report.allExistingSourcesBackedUp, isFalse);
    expect(storage.saveCalls, 0);
  });

  test('reports malformed source and mismatched backup separately', () async {
    final storage = _RecordingStorageService({
      'items': '{broken-json',
      'backup_v1_items': '[]',
      'schedules': '[{"id":"schedule-1"}]',
      'backup_v1_schedules': '[]',
      'tasks': '[]',
      'backup_v1_tasks': '[]',
      'maintenance_records': '[]',
      'backup_v1_maintenance_records': '[]',
    });

    final report = await MigrationReadinessService(
      storageService: storage,
      database: database,
    ).inspect();
    final items = report.datasets.firstWhere((data) => data.sourceKey == 'items');
    final schedules = report.datasets.firstWhere(
      (data) => data.sourceKey == 'schedules',
    );

    expect(items.sourceIsValidList, isFalse);
    expect(items.backupIsValidList, isTrue);
    expect(items.rawValuesMatch, isFalse);
    expect(schedules.sourceIsValidList, isTrue);
    expect(schedules.sourceCount, 1);
    expect(schedules.backupCount, 0);
    expect(schedules.rawValuesMatch, isFalse);
    expect(report.allSourceDataReadable, isFalse);
    expect(report.allExistingSourcesBackedUp, isFalse);
  });

  test('reports Drift counts without changing either data source', () async {
    await database.into(database.workCases).insert(
      WorkCasesCompanion.insert(
        id: 'case-1',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.repair,
        title: '冷氣維修',
        status: WorkCaseStatus.inProgress,
        createdAt: DateTime.utc(2026, 7, 18),
        updatedAt: DateTime.utc(2026, 7, 18),
      ),
    );
    await database.into(database.workCaseUpdates).insert(
      WorkCaseUpdatesCompanion.insert(
        id: 'update-1',
        workCaseId: 'case-1',
        occurredAt: DateTime.utc(2026, 7, 18, 8),
        description: '已聯絡廠商',
        createdAt: DateTime.utc(2026, 7, 18, 8, 5),
      ),
    );
    final storage = _RecordingStorageService(const <String, String>{});

    final report = await MigrationReadinessService(
      storageService: storage,
      database: database,
    ).inspect();

    expect(report.driftWorkCaseCount, 1);
    expect(report.driftWorkCaseUpdateCount, 1);
    expect(report.driftIsEmpty, isFalse);
    expect(storage.saveCalls, 0);
    expect(storage.removeCalls, 0);
  });
}
