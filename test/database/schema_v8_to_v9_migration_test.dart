import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'v8 to v9 marks existing FutureMatter active without fake completion',
    () async {
      final directory = await Directory.systemTemp.createTemp('schema-v8-v9-');
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fixture.sqlite');
      final raw = sqlite.sqlite3.open(file.path);
      _createV8Fixture(raw);
      raw.execute(
        "INSERT INTO future_matters (id,title,timing_mode,created_at,updated_at) VALUES ('legacy','既有事項','later','2026-08-08T00:00:00.000Z','2026-08-08T00:00:00.000Z')",
      );
      raw.close();

      final database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
      await database.customSelect('SELECT 1').get();
      expect(database.schemaVersion, 12);
      expect(
        (await database.select(database.futureMatters).getSingle())
            .lifecycleStatus,
        'active',
      );
      expect(
        await database.select(database.futureMatterCompletedEvents).get(),
        isEmpty,
      );
    },
  );

  test('fresh v11 and migrated v11 FutureMatter schema match', () async {
    final directory = await Directory.systemTemp.createTemp('schema-v9-match-');
    addTearDown(() => directory.delete(recursive: true));
    final freshFile = File('${directory.path}/fresh.sqlite');
    final migratedFile = File('${directory.path}/migrated.sqlite');
    final fresh = AppDatabase(NativeDatabase(freshFile));
    await fresh.customSelect('SELECT 1').get();
    await fresh.close();
    final raw = sqlite.sqlite3.open(migratedFile.path);
    _createV8Fixture(raw);
    raw.close();
    final migrated = AppDatabase(NativeDatabase(migratedFile));
    await migrated.customSelect('SELECT 1').get();
    await migrated.close();

    expect(_schema(migratedFile), _schema(freshFile));
    expect(_lifecycleColumn(migratedFile), _lifecycleColumn(freshFile));
    expect(_provenanceColumns(migratedFile), _provenanceColumns(freshFile));
  });
}

void _createV8Fixture(sqlite.Database database) {
  database.execute('''
    CREATE TABLE future_matters (
      id TEXT NOT NULL PRIMARY KEY,
      title TEXT NOT NULL,
      item_id TEXT NULL,
      timing_mode TEXT NOT NULL,
      specified_date TEXT NULL,
      specified_minute_of_day INTEGER NULL,
      recurring_interval_value INTEGER NULL,
      recurring_interval_unit TEXT NULL,
      recurring_anchor_date TEXT NULL,
      recurring_anchor_minute_of_day INTEGER NULL,
      condition_type TEXT NULL,
      condition_maintenance_record_id TEXT NULL,
      condition_delay_value INTEGER NULL,
      condition_delay_unit TEXT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL,
      CHECK (trim(title) <> ''),
      CHECK (timing_mode IN ('later', 'specifiedDate', 'recurring', 'condition')),
      CHECK (specified_minute_of_day IS NULL OR specified_minute_of_day BETWEEN 0 AND 1439),
      CHECK (recurring_anchor_minute_of_day IS NULL OR recurring_anchor_minute_of_day BETWEEN 0 AND 1439),
      CHECK (recurring_anchor_minute_of_day IS NULL OR recurring_anchor_date IS NOT NULL),
      CHECK (recurring_interval_unit IS NULL OR recurring_interval_unit IN ('minute', 'hour', 'day', 'week', 'month', 'year')),
      CHECK (condition_delay_unit IS NULL OR condition_delay_unit IN ('minute', 'hour', 'day', 'week', 'month')),
      CHECK (condition_type IS NULL OR condition_type = 'afterFormalCompletion'),
      CHECK (recurring_interval_value IS NULL OR recurring_interval_value > 0),
      CHECK (condition_delay_value IS NULL OR condition_delay_value > 0)
    )
  ''');
  database.execute('PRAGMA user_version = 8');
}

List<String> _schema(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    return database
        .select('''
          SELECT type, name, sql FROM sqlite_schema
          WHERE name LIKE 'future_matter_amendment_%'
             OR name LIKE 'future_matters_created_provenance_%'
          ORDER BY type, name
        ''')
        .map((row) => '${row['type']}|${row['name']}|${row['sql']}')
        .toList(growable: false);
  } finally {
    database.close();
  }
}

List<String> _provenanceColumns(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    return database
        .select("PRAGMA table_info('future_matters')")
        .where(
          (row) => const {
            'created_source',
            'created_source_reference_kind',
            'created_source_reference_id',
          }.contains(row['name']),
        )
        .map(
          (row) =>
              '${row['name']}|${row['type']}|${row['notnull']}|${row['dflt_value']}',
        )
        .toList(growable: false);
  } finally {
    database.close();
  }
}

String _lifecycleColumn(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    final row = database
        .select("PRAGMA table_info('future_matters')")
        .singleWhere((row) => row['name'] == 'lifecycle_status');
    return '${row['type']}|${row['notnull']}|${row['dflt_value']}';
  } finally {
    database.close();
  }
}
