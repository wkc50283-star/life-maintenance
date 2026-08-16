import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema v6 adds future matters without rewriting existing data',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-management-schema-v6-v7-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final file = File('${directory.path}/fixture.sqlite');
      final now = DateTime.utc(2026, 8, 8);
      var database = AppDatabase(NativeDatabase(file));
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: 'existing-item',
              name: '既有生活項目',
              categoryId: 'system-category-unclassified',
              createdAt: now,
              updatedAt: now,
              status: 'active',
            ),
          );
      await database.close();

      final raw = sqlite.sqlite3.open(file.path);
      raw.execute('DROP TABLE future_matter_created_events');
      raw.execute('DROP TABLE future_matters');
      raw.execute('PRAGMA user_version = 6');
      raw.close();

      database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
      await database.customSelect('SELECT 1').get();

      expect(database.schemaVersion, 11);
      expect(
        (await database.select(database.items).get()).single.id,
        'existing-item',
      );
      expect(await database.select(database.futureMatters).get(), isEmpty);
      expect(
        await database.select(database.futureMatterCreatedEvents).get(),
        isEmpty,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );

  test(
    'fresh and migrated schema v7 use identical FutureMatter schema',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-management-schema-v7-equivalence-',
      );
      addTearDown(() => directory.delete(recursive: true));
      final freshFile = File('${directory.path}/fresh.sqlite');
      final migratedFile = File('${directory.path}/migrated.sqlite');

      final fresh = AppDatabase(NativeDatabase(freshFile));
      await fresh.customSelect('SELECT 1').get();
      await fresh.close();

      var migrated = AppDatabase(NativeDatabase(migratedFile));
      await migrated.customSelect('SELECT 1').get();
      await migrated.close();
      final raw = sqlite.sqlite3.open(migratedFile.path);
      raw.execute('DROP TABLE future_matter_created_events');
      raw.execute('DROP TABLE future_matters');
      raw.execute('PRAGMA user_version = 6');
      raw.close();
      migrated = AppDatabase(NativeDatabase(migratedFile));
      await migrated.customSelect('SELECT 1').get();
      await migrated.close();

      final freshSchema = _futureMatterSchema(freshFile);
      final migratedSchema = _futureMatterSchema(migratedFile);
      expect(migratedSchema.entities, freshSchema.entities);
      expect(migratedSchema.foreignKeys, freshSchema.foreignKeys);
    },
  );
}

({List<String> entities, Map<String, List<String>> foreignKeys})
_futureMatterSchema(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    final entities = database
        .select('''
          SELECT type, name, sql
          FROM sqlite_schema
          WHERE name IN (
            'future_matters',
            'future_matter_created_events',
            'future_matters_item_idx',
            'future_matters_timing_mode_idx',
            'future_matter_created_events_matter_unique_idx',
            'future_matter_created_events_item_idx',
            'future_matter_created_events_no_update',
            'future_matter_created_events_no_delete'
          )
          ORDER BY type, name
        ''')
        .map((row) => '${row['type']}|${row['name']}|${row['sql']}')
        .toList(growable: false);
    final foreignKeys = <String, List<String>>{};
    for (final table in const [
      'future_matters',
      'future_matter_created_events',
    ]) {
      foreignKeys[table] = database
          .select('PRAGMA foreign_key_list($table)')
          .map((row) => row.values.join('|'))
          .toList(growable: false);
    }
    return (entities: entities, foreignKeys: foreignKeys);
  } finally {
    database.close();
  }
}
