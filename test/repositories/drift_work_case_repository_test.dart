import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_work_case_repository.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftWorkCaseRepository repository;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repository = DriftWorkCaseRepository(database);

    final now = DateTime.utc(2026, 7, 18);
    await database
        .into(database.itemCategories)
        .insert(
          ItemCategoriesCompanion.insert(
            id: 'category-1',
            systemCode: const Value('other'),
            displayName: '其他',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ),
        );
    for (final itemId in const ['item-1', 'item-2']) {
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: itemId,
              name: '測試生活項目 $itemId',
              categoryId: 'category-1',
              createdAt: now,
              updatedAt: now,
              status: 'active',
            ),
          );
    }
  });

  tearDown(() async {
    await database.close();
  });

  WorkCase buildCase({
    String id = 'case-1',
    String itemId = 'item-1',
    DateTime? updatedAt,
  }) {
    final createdAt = DateTime.utc(2026, 7, 18, 8);
    return WorkCase(
      id: id,
      itemId: itemId,
      sourceType: WorkCaseSourceType.manual,
      caseType: WorkCaseType.repair,
      title: '冷氣異音',
      status: WorkCaseStatus.inProgress,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      description: '運轉時出現間歇異音',
      occurredAt: createdAt,
      startedAt: createdAt,
    );
  }

  WorkCaseUpdate buildUpdate({
    String id = 'update-1',
    String workCaseId = 'case-1',
    DateTime? occurredAt,
  }) {
    final time = occurredAt ?? DateTime.utc(2026, 7, 18, 9);
    return WorkCaseUpdate(
      id: id,
      workCaseId: workCaseId,
      occurredAt: time,
      description: '完成初步檢查',
      contactOrVendor: '安心冷氣行',
      result: '需更換軸承',
      cost: 500,
      partsOrItems: const ['軸承'],
      photoIdentifiers: const ['photo-1'],
      nextAction: '等待零件到貨',
      createdAt: time,
    );
  }

  test('saves and restores a complete work case model', () async {
    final workCase = buildCase();

    await repository.saveCase(workCase);
    final restored = await repository.findCaseById(workCase.id);

    expect(restored, isNotNull);
    expect(restored!.toJson(), workCase.toJson());
  });

  test('saveCase updates an open case instead of duplicating it', () async {
    final workCase = buildCase();
    final updatedAt = DateTime.utc(2026, 7, 19, 17);

    await repository.saveCase(workCase);
    await repository.saveCase(
      workCase.copyWith(
        status: WorkCaseStatus.waiting,
        updatedAt: updatedAt,
        description: '等待零件到貨',
      ),
    );

    final rows = await database.select(database.workCases).get();
    final restored = await repository.findCaseById(workCase.id);

    expect(rows, hasLength(1));
    expect(restored!.status, WorkCaseStatus.waiting);
    expect(restored.description, '等待零件到貨');
  });

  test('rejects completion without a formal WorkCaseClosure', () async {
    final workCase = buildCase();
    await repository.saveCase(workCase);

    await expectLater(
      repository.saveCase(
        workCase.copyWith(
          status: WorkCaseStatus.completed,
          closedAt: DateTime.utc(2026, 7, 19),
        ),
      ),
      throwsA(anything),
    );

    expect(
      (await repository.findCaseById(workCase.id))?.status,
      WorkCaseStatus.inProgress,
    );
  });

  test(
    'rejects a maintenance case sourced from a non-maintenance Task',
    () async {
      await database
          .into(database.tasks)
          .insert(
            TasksCompanion.insert(
              id: 'manual-task',
              itemId: 'item-1',
              sourceType: 'manual',
              title: '手動提醒',
              dueDate: DateTime.utc(2026, 7, 18),
              status: 'pending',
              createdAt: DateTime.utc(2026, 7, 18),
              updatedAt: DateTime.utc(2026, 7, 18),
            ),
          );

      await expectLater(
        repository.saveCase(
          buildCase().copyWith(
            sourceType: WorkCaseSourceType.maintenanceTask,
            sourceId: 'manual-task',
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );

      expect(await repository.findCaseById('case-1'), isNull);
    },
  );

  test('lists cases by item with latest updated case first', () async {
    await repository.saveCase(
      buildCase(id: 'older', updatedAt: DateTime.utc(2026, 7, 18, 8)),
    );
    await repository.saveCase(
      buildCase(id: 'newer', updatedAt: DateTime.utc(2026, 7, 19, 8)),
    );
    await repository.saveCase(buildCase(id: 'other', itemId: 'item-2'));

    final cases = await repository.listCasesForItem('item-1');

    expect(cases.map((entry) => entry.id), ['newer', 'older']);
  });

  test('appends updates without overwriting earlier progress', () async {
    await repository.saveCase(buildCase());
    await repository.appendUpdate(
      buildUpdate(id: 'later', occurredAt: DateTime.utc(2026, 7, 18, 11)),
    );
    await repository.appendUpdate(
      buildUpdate(id: 'earlier', occurredAt: DateTime.utc(2026, 7, 18, 9)),
    );

    final updates = await repository.listUpdatesForCase('case-1');

    expect(updates.map((entry) => entry.id), ['earlier', 'later']);
    expect(updates.first.partsOrItems, ['軸承']);
    expect(
      () => updates.first.partsOrItems.add('不得改寫'),
      throwsUnsupportedError,
    );
  });

  test('creates a case and initial update atomically', () async {
    final workCase = buildCase();
    final update = buildUpdate();

    await repository.createCaseWithInitialUpdate(workCase, update);

    expect(await repository.findCaseById(workCase.id), isNotNull);
    expect(await repository.listUpdatesForCase(workCase.id), hasLength(1));
  });

  test('rejects a mismatched initial update before writing anything', () async {
    final workCase = buildCase();
    final update = buildUpdate(workCaseId: 'different-case');

    await expectLater(
      repository.createCaseWithInitialUpdate(workCase, update),
      throwsArgumentError,
    );

    expect(await repository.findCaseById(workCase.id), isNull);
    expect(await database.select(database.workCaseUpdates).get(), isEmpty);
  });

  test('duplicate initial update rolls back the newly inserted case', () async {
    final update = buildUpdate();
    await repository.saveCase(buildCase(id: 'existing-case'));
    await repository.appendUpdate(buildUpdate(workCaseId: 'existing-case'));

    final newCase = buildCase(id: 'case-1');

    await expectLater(
      repository.createCaseWithInitialUpdate(newCase, update),
      throwsA(anything),
    );

    expect(await repository.findCaseById(newCase.id), isNull);
    expect(await repository.listUpdatesForCase('existing-case'), hasLength(1));
  });
}
