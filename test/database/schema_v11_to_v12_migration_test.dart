import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v11 to v12 preserves existing types and permits null for manual',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'schema-v11-v12-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fixture.sqlite');
      await _createV11Fixture(file);

      final database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
      await database.customSelect('SELECT 1').get();

      expect(database.schemaVersion, 12);
      final existing = await database.select(database.workCases).getSingle();
      expect(existing.caseType, WorkCaseType.repair);

      await database.customStatement('''
      INSERT INTO work_cases (
        schema_version, id, item_id, source_type, source_id, source_task_id,
        case_type, title, description, occurred_at, started_at, status,
        created_at, updated_at, closed_at, canceled_at, close_result,
        cancellation_reason
      ) VALUES (
        1, 'case-untyped', NULL, 'manual', NULL, NULL,
        NULL, '未提供類型', NULL, NULL, NULL, 'inProgress',
        '2026-08-18T00:00:00.000Z', '2026-08-18T00:00:00.000Z',
        NULL, NULL, NULL, NULL
      )
    ''');
      expect(
        (await database.select(database.workCases).get())
            .singleWhere((row) => row.id == 'case-untyped')
            .caseType,
        isNull,
      );

      await expectLater(
        database.customStatement('''
        INSERT INTO work_cases (
          schema_version, id, item_id, source_type, source_id, source_task_id,
          case_type, title, status, created_at, updated_at
        ) VALUES (
          1, 'case-invalid-source', 'item-1', 'generalReminder',
          'reminder-1', NULL, NULL, '來源案件', 'inProgress',
          '2026-08-18T00:00:00.000Z', '2026-08-18T00:00:00.000Z'
        )
      '''),
        throwsA(anything),
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test('fresh v12 and migrated v12 WorkCase schema match', () async {
    final directory = await Directory.systemTemp.createTemp(
      'schema-v12-match-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final freshFile = File('${directory.path}/fresh.sqlite');
    final migratedFile = File('${directory.path}/migrated.sqlite');

    final fresh = AppDatabase(NativeDatabase(freshFile));
    await fresh.customSelect('SELECT 1').get();
    await fresh.close();
    await _createV11Fixture(migratedFile);
    final migrated = AppDatabase(NativeDatabase(migratedFile));
    await migrated.customSelect('SELECT 1').get();
    await migrated.close();

    expect(_workCaseSchema(migratedFile), _workCaseSchema(freshFile));
  });
}

Future<void> _createV11Fixture(File file) async {
  final database = AppDatabase(NativeDatabase(file));
  await database.customSelect('SELECT 1').get();
  await database.close();

  final raw = sqlite.sqlite3.open(file.path);
  try {
    raw.execute('PRAGMA foreign_keys = OFF');
    raw.execute('PRAGMA legacy_alter_table = ON');
    final currentSql =
        raw
                .select(
                  "SELECT sql FROM sqlite_schema WHERE type = 'table' AND name = 'work_cases'",
                )
                .single['sql']
            as String;
    final oldSql = currentSql
        .replaceFirst(
          'CREATE TABLE "work_cases"',
          'CREATE TABLE work_cases_v11',
        )
        .replaceFirst('"case_type" TEXT NULL', '"case_type" TEXT NOT NULL')
        .replaceFirst(
          ", CHECK (case_type IS NOT NULL OR source_type = 'manual')",
          '',
        );
    raw.execute(oldSql);
    raw.execute('INSERT INTO work_cases_v11 SELECT * FROM work_cases');
    raw.execute('DROP TABLE work_cases');
    raw.execute('ALTER TABLE work_cases_v11 RENAME TO work_cases');
    for (final statement in const [
      'CREATE INDEX work_cases_item_status_idx ON work_cases (item_id, status)',
      'CREATE INDEX work_cases_source_idx ON work_cases (source_type, source_id)',
      'CREATE INDEX work_cases_source_task_idx ON work_cases (source_task_id)',
      'CREATE INDEX work_cases_updated_at_idx ON work_cases (updated_at)',
    ]) {
      raw.execute(statement);
    }
    raw.execute('''
      INSERT INTO item_categories (
        id, system_code, custom_name, display_name, sort_order, status,
        created_at, updated_at, archived_at
      ) VALUES (
        'category-1', 'other', NULL, '其他', 0, 'active',
        '2026-08-18T00:00:00.000Z', '2026-08-18T00:00:00.000Z', NULL
      )
    ''');
    raw.execute('''
      INSERT INTO items (
        id, name, category_id, created_at, updated_at, purchase_date,
        warranty_end_date, expected_life_years, location, note, status,
        archived_at
      ) VALUES (
        'item-1', '既有項目', 'category-1',
        '2026-08-18T00:00:00.000Z', '2026-08-18T00:00:00.000Z',
        NULL, NULL, NULL, NULL, NULL, 'active', NULL
      )
    ''');
    raw.execute('''
      INSERT INTO work_cases (
        schema_version, id, item_id, source_type, source_id, source_task_id,
        case_type, title, status, created_at, updated_at
      ) VALUES (
        1, 'case-linked', 'item-1', 'manual', NULL, NULL,
        '${WorkCaseType.repair.name}', '既有案件', 'inProgress',
        '2026-08-18T00:00:00.000Z', '2026-08-18T00:00:00.000Z'
      )
    ''');
    raw.execute('PRAGMA user_version = 11');
  } finally {
    raw.close();
  }
}

List<String> _workCaseSchema(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    return database
        .select('''
          SELECT type, name, sql FROM sqlite_schema
          WHERE name = 'work_cases' OR name LIKE 'work_cases_%'
          ORDER BY type, name
        ''')
        .map((row) => '${row['type']}|${row['name']}|${row['sql']}')
        .toList(growable: false);
  } finally {
    database.close();
  }
}
