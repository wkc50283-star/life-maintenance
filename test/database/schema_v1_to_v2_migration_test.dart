import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';

void main() {
  test('migrates schema v1 cases and updates into schema v2 safely', () async {
    final executor = NativeDatabase.memory();

    await executor.runCustom('''
      CREATE TABLE work_cases (
        schema_version INTEGER NOT NULL DEFAULT 1,
        id TEXT NOT NULL PRIMARY KEY,
        item_id TEXT NOT NULL,
        source_type TEXT NOT NULL,
        source_id TEXT NULL,
        case_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NULL,
        occurred_at INTEGER NULL,
        started_at INTEGER NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        closed_at INTEGER NULL,
        close_result TEXT NULL,
        cancellation_reason TEXT NULL
      )
    ''');
    await executor.runCustom('''
      CREATE TABLE work_case_updates (
        schema_version INTEGER NOT NULL DEFAULT 1,
        id TEXT NOT NULL PRIMARY KEY,
        work_case_id TEXT NOT NULL REFERENCES work_cases(id) ON UPDATE CASCADE ON DELETE RESTRICT,
        occurred_at INTEGER NOT NULL,
        description TEXT NOT NULL,
        contact_or_vendor TEXT NULL,
        result TEXT NULL,
        cost INTEGER NULL,
        parts_or_items TEXT NOT NULL DEFAULT '[]',
        photo_identifiers TEXT NOT NULL DEFAULT '[]',
        waiting_reason TEXT NULL,
        note TEXT NULL,
        next_action TEXT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await executor.runCustom('PRAGMA user_version = 1');

    const createdAt = 1784342400000000;
    await executor.runCustom('''
      INSERT INTO work_cases (
        id, item_id, source_type, source_id, case_type, title, status,
        created_at, updated_at
      ) VALUES (
        'case-1', 'item-1', 'manual', NULL, 'repair', '冷氣維修',
        'inProgress', $createdAt, $createdAt
      )
    ''');
    await executor.runCustom('''
      INSERT INTO work_case_updates (
        id, work_case_id, occurred_at, description, cost,
        parts_or_items, photo_identifiers, created_at
      ) VALUES (
        'update-1', 'case-1', $createdAt, '完成初步檢查', 500,
        '["軸承"]', '["photo-1"]', $createdAt
      )
    ''');

    final database = AppDatabase(executor);
    addTearDown(database.close);

    final cases = await database.select(database.workCases).get();
    final updates = await database.select(database.workCaseUpdates).get();
    final items = await database.select(database.items).get();
    final categories = await database.select(database.itemCategories).get();

    expect(database.schemaVersion, 2);
    expect(cases, hasLength(1));
    expect(cases.single.id, 'case-1');
    expect(cases.single.itemId, 'item-1');
    expect(updates, hasLength(1));
    expect(updates.single.workCaseId, 'case-1');
    expect(updates.single.cost, 500);
    expect(items, hasLength(1));
    expect(items.single.id, 'item-1');
    expect(items.single.note, contains('schema v1'));
    expect(categories.single.systemCode, 'legacyImported');

    final legacyTables = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name LIKE 'legacy_%'
    ''').get();
    expect(legacyTables, isEmpty);

    final violations = await database.customSelect('PRAGMA foreign_key_check').get();
    expect(violations, isEmpty);
  });

  test('rolls back the whole migration when legacy data violates v2 rules', () async {
    final executor = NativeDatabase.memory();
    await executor.runCustom('''
      CREATE TABLE work_cases (
        schema_version INTEGER NOT NULL DEFAULT 1,
        id TEXT NOT NULL PRIMARY KEY,
        item_id TEXT NOT NULL,
        source_type TEXT NOT NULL,
        source_id TEXT NULL,
        case_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NULL,
        occurred_at INTEGER NULL,
        started_at INTEGER NULL,
        status TEXT NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL,
        closed_at INTEGER NULL,
        close_result TEXT NULL,
        cancellation_reason TEXT NULL
      )
    ''');
    await executor.runCustom('''
      CREATE TABLE work_case_updates (
        schema_version INTEGER NOT NULL DEFAULT 1,
        id TEXT NOT NULL PRIMARY KEY,
        work_case_id TEXT NOT NULL,
        occurred_at INTEGER NOT NULL,
        description TEXT NOT NULL,
        contact_or_vendor TEXT NULL,
        result TEXT NULL,
        cost INTEGER NULL,
        parts_or_items TEXT NOT NULL DEFAULT '[]',
        photo_identifiers TEXT NOT NULL DEFAULT '[]',
        waiting_reason TEXT NULL,
        note TEXT NULL,
        next_action TEXT NULL,
        created_at INTEGER NOT NULL
      )
    ''');
    await executor.runCustom('PRAGMA user_version = 1');
    await executor.runCustom('''
      INSERT INTO work_cases (
        id, item_id, source_type, source_id, case_type, title, status,
        created_at, updated_at
      ) VALUES (
        'invalid-case', 'item-1', 'manual', 'illegal-source', 'repair',
        '無效舊案件', 'inProgress', 1, 1
      )
    ''');

    final database = AppDatabase(executor);
    addTearDown(database.close);

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(isA<Exception>()),
    );

    final version = await executor.runSelect('PRAGMA user_version', const []);
    expect(version.single['user_version'], 1);
    final oldRows = await executor.runSelect('SELECT id FROM work_cases', const []);
    expect(oldRows.single['id'], 'invalid-case');
  });
}
