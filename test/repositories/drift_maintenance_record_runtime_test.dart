import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_maintenance_record_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftMaintenanceRecordRuntimeRepository records;
  final now = DateTime.utc(2026, 7, 19, 10);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    records = DriftMaintenanceRecordRuntimeRepository(database);
    await repositories.itemCategories.save(
      ItemCategoryRow(
        id: 'category-1',
        systemCode: 'other',
        displayName: '其他',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final id in const ['item-1', 'item-2']) {
      await repositories.items.save(
        ItemRow(
          id: id,
          name: id,
          categoryId: 'category-1',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  });

  tearDown(() => database.close());

  MaintenanceRecord record({
    String id = 'record-1',
    String itemId = 'item-1',
    String? taskId,
    List<String> photos = const [],
  }) => MaintenanceRecord(
    id: id,
    itemId: itemId,
    taskId: taskId,
    recordType: RecordType.regularMaintenance,
    date: now.add(const Duration(hours: 1)),
    title: '完成簡單清潔',
    partsChanged: const ['濾網'],
    cost: 120,
    photos: photos,
    createdAt: now.add(const Duration(hours: 1)),
  );

  Future<void> insertTask({String id = 'task-1', String itemId = 'item-1'}) {
    return database
        .into(database.tasks)
        .insert(
          TaskRow(
            id: id,
            itemId: itemId,
            sourceType: 'manual',
            title: '清潔提醒',
            dueDate: now,
            status: TaskStatus.pending.name,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  test('reads imported rows through the formal domain mapping', () async {
    await repositories.maintenanceRecords.create(
      MaintenanceRecordRow(
        id: 'legacy-record',
        itemId: 'item-1',
        recordType: 'futureLegacyType',
        date: now,
        title: '舊匯入紀錄',
        partsChanged: '["舊零件"]',
        createdAt: now,
      ),
    );

    final loaded = await records.findById('legacy-record');

    expect(loaded?.recordType, RecordType.other);
    expect(loaded?.partsChanged, ['舊零件']);
  });

  test('completes Task and creates exactly one record atomically', () async {
    await insertTask();

    await records.completeSimpleTask(record(taskId: 'task-1'));

    final task = await repositories.tasks.findById('task-1');
    expect(task?.status, TaskStatus.completed.name);
    expect(task?.completedAt, now.add(const Duration(hours: 1)));
    expect((await records.listForItem('item-1')).single.taskId, 'task-1');
    await expectLater(
      records.completeSimpleTask(record(id: 'record-2', taskId: 'task-1')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect((await records.listForItem('item-1')), hasLength(1));
  });

  test('rolls back Task completion when record insertion fails', () async {
    await insertTask();
    await records.createSimpleRecord(record());

    await expectLater(
      records.completeSimpleTask(record(taskId: 'task-1')),
      throwsA(anything),
    );

    final task = await repositories.tasks.findById('task-1');
    expect(task?.status, TaskStatus.pending.name);
    expect(task?.completedAt, isNull);
  });

  test('rejects cross-Item Task and Attachment path bypass', () async {
    await insertTask(itemId: 'item-2');

    await expectLater(
      records.completeSimpleTask(record(taskId: 'task-1')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      records.createSimpleRecord(record(photos: const ['platform/path.jpg'])),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test('Task with a WorkCase must conclude through WorkCaseClosure', () async {
    await insertTask();
    await database
        .into(database.workCases)
        .insert(
          WorkCaseRow(
            schemaVersion: 1,
            id: 'case-1',
            itemId: 'item-1',
            sourceType: WorkCaseSourceType.maintenanceTask,
            sourceId: 'task-1',
            caseType: WorkCaseType.maintenance,
            title: '需要持續處理',
            status: WorkCaseStatus.inProgress,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(
      records.completeSimpleTask(record(taskId: 'task-1')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await records.listForItem('item-1'), isEmpty);
  });

  test('new simple record appears in read-only History projection', () async {
    await records.createSimpleRecord(record());
    final history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );

    final projection = await history.projectForItem('item-1');

    final entry = projection.entries.singleWhere(
      (value) => value.sourceId == 'record-1',
    );
    expect(entry, isA<MaintenanceRecordHistoryEntry>());
    expect((entry as MaintenanceRecordHistoryEntry).record.title, '完成簡單清潔');
  });
}
