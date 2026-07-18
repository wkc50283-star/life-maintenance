import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case_enums.dart';

void main() {
  late AppDatabase database;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());

    final now = DateTime.utc(2026, 7, 18);
    await database.into(database.itemCategories).insert(
          ItemCategoriesCompanion.insert(
            id: 'category-1',
            systemCode: const Value('other'),
            displayName: '其他',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.into(database.items).insert(
          ItemsCompanion.insert(
            id: 'item-1',
            name: '測試生活項目',
            categoryId: 'category-1',
            createdAt: now,
            updatedAt: now,
            status: 'active',
          ),
        );
  });

  tearDown(() async {
    await database.close();
  });

  test('schema v2 creates the formal life-management tables', () async {
    final rows = await database.customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' ORDER BY name",
    ).get();
    final names = rows.map((row) => row.read<String>('name')).toSet();

    expect(database.schemaVersion, 2);
    expect(names, containsAll(<String>{
      'item_categories',
      'items',
      'maintenance_plans',
      'maintenance_plan_steps',
      'general_reminders',
      'milestones',
      'schedules',
      'tasks',
      'maintenance_records',
      'work_cases',
      'work_case_updates',
      'work_case_closures',
      'attachments',
    }));
  });

  test('case and progress round trip preserves ISO datetime precision', () async {
    final occurredAt = DateTime.utc(2026, 7, 18, 9, 30, 12, 345, 678);
    final createdAt = DateTime.utc(2026, 7, 18, 9, 31, 1, 234, 567);

    await database.into(database.workCases).insert(
          WorkCasesCompanion.insert(
            id: 'case-1',
            itemId: 'item-1',
            sourceType: WorkCaseSourceType.manual,
            caseType: WorkCaseType.repair,
            title: '冷氣異音檢查',
            status: WorkCaseStatus.inProgress,
            createdAt: createdAt,
            updatedAt: createdAt,
            occurredAt: Value(occurredAt),
          ),
        );

    await database.into(database.workCaseUpdates).insert(
          WorkCaseUpdatesCompanion.insert(
            id: 'update-1',
            workCaseId: 'case-1',
            occurredAt: occurredAt,
            description: '完成第一次檢查',
            createdAt: createdAt,
            cost: const Value(500),
            partsOrItems: const Value(['風扇軸承']),
            photoIdentifiers: const Value(['photo-1']),
          ),
        );

    final caseRow = await database.select(database.workCases).getSingle();
    final updateRow = await database.select(database.workCaseUpdates).getSingle();

    expect(caseRow.itemId, 'item-1');
    expect(caseRow.sourceType, WorkCaseSourceType.manual);
    expect(caseRow.caseType, WorkCaseType.repair);
    expect(caseRow.occurredAt, occurredAt);
    expect(caseRow.createdAt, createdAt);
    expect(updateRow.cost, 500);
    expect(updateRow.partsOrItems, ['風扇軸承']);
    expect(updateRow.photoIdentifiers, ['photo-1']);
  });

  test('foreign key rejects a case without a parent item', () async {
    final now = DateTime.utc(2026, 7, 18);
    final insert = database.into(database.workCases).insert(
          WorkCasesCompanion.insert(
            id: 'orphan-case',
            itemId: 'missing-item',
            sourceType: WorkCaseSourceType.manual,
            caseType: WorkCaseType.other,
            title: '不應寫入的孤兒案件',
            status: WorkCaseStatus.notStarted,
            createdAt: now,
            updatedAt: now,
          ),
        );

    await expectLater(insert, throwsA(isA<Exception>()));
  });

  test('foreign key rejects progress without a parent case', () async {
    final insert = database.into(database.workCaseUpdates).insert(
          WorkCaseUpdatesCompanion.insert(
            id: 'orphan-update',
            workCaseId: 'missing-case',
            occurredAt: DateTime.utc(2026, 7, 18),
            description: '不應寫入的孤兒進度',
            createdAt: DateTime.utc(2026, 7, 18),
          ),
        );

    await expectLater(insert, throwsA(isA<Exception>()));
    expect(await database.select(database.workCaseUpdates).get(), isEmpty);
  });

  test('deleting a case with progress is restricted', () async {
    final now = DateTime.utc(2026, 7, 18);
    await database.into(database.workCases).insert(
          WorkCasesCompanion.insert(
            id: 'case-protected',
            itemId: 'item-1',
            sourceType: WorkCaseSourceType.manual,
            caseType: WorkCaseType.construction,
            title: '陽台修繕',
            status: WorkCaseStatus.waiting,
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database.into(database.workCaseUpdates).insert(
          WorkCaseUpdatesCompanion.insert(
            id: 'update-protected',
            workCaseId: 'case-protected',
            occurredAt: now,
            description: '等待報價',
            createdAt: now,
          ),
        );

    final deletion = (database.delete(database.workCases)
          ..where((table) => table.id.equals('case-protected')))
        .go();

    await expectLater(deletion, throwsA(isA<Exception>()));
    expect(await database.select(database.workCases).get(), hasLength(1));
    expect(await database.select(database.workCaseUpdates).get(), hasLength(1));
  });

  test('deleting an item with a case is restricted', () async {
    final now = DateTime.utc(2026, 7, 18);
    await database.into(database.workCases).insert(
          WorkCasesCompanion.insert(
            id: 'item-protected-case',
            itemId: 'item-1',
            sourceType: WorkCaseSourceType.manual,
            caseType: WorkCaseType.repair,
            title: '保護生活項目',
            status: WorkCaseStatus.inProgress,
            createdAt: now,
            updatedAt: now,
          ),
        );

    final deletion = (database.delete(database.items)
          ..where((table) => table.id.equals('item-1')))
        .go();

    await expectLater(deletion, throwsA(isA<Exception>()));
    expect(await database.select(database.items).get(), hasLength(1));
  });

  test('transaction rollback leaves no partial case or progress rows', () async {
    final now = DateTime.utc(2026, 7, 18);

    await expectLater(
      database.transaction(() async {
        await database.into(database.workCases).insert(
              WorkCasesCompanion.insert(
                id: 'case-rollback',
                itemId: 'item-1',
                sourceType: WorkCaseSourceType.manual,
                caseType: WorkCaseType.other,
                title: '回復測試',
                status: WorkCaseStatus.notStarted,
                createdAt: now,
                updatedAt: now,
              ),
            );
        await database.into(database.workCaseUpdates).insert(
              WorkCaseUpdatesCompanion.insert(
                id: 'update-rollback',
                workCaseId: 'case-rollback',
                occurredAt: now,
                description: '這筆進度必須一起回滾',
                createdAt: now,
              ),
            );
        throw StateError('force rollback');
      }),
      throwsStateError,
    );

    expect(await database.select(database.workCases).get(), isEmpty);
    expect(await database.select(database.workCaseUpdates).get(), isEmpty);
  });
}
