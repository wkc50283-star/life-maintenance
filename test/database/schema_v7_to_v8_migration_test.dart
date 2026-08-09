import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('v7 to v8 adds empty FutureMatter change history only', () async {
    final directory = await Directory.systemTemp.createTemp('schema-v7-v8-');
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fixture.sqlite');
    var database = AppDatabase(NativeDatabase(file));
    await database.customSelect('SELECT 1').get();
    await database.close();

    final raw = sqlite.sqlite3.open(file.path);
    raw.execute('DROP TABLE future_matter_change_event_snapshots');
    raw.execute('DROP TABLE future_matter_change_events');
    raw.execute('PRAGMA user_version = 7');
    raw.close();

    database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    await database.customSelect('SELECT 1').get();
    expect(database.schemaVersion, 10);
    expect(
      await database.select(database.futureMatterChangeEvents).get(),
      isEmpty,
    );
    expect(
      await database.select(database.futureMatterChangeEventSnapshots).get(),
      isEmpty,
    );
  });

  test('fresh v8 and migrated v8 FutureMatter change schema match', () async {
    final directory = await Directory.systemTemp.createTemp('schema-v8-match-');
    addTearDown(() => directory.delete(recursive: true));
    final freshFile = File('${directory.path}/fresh.sqlite');
    final migratedFile = File('${directory.path}/migrated.sqlite');
    for (final file in [freshFile, migratedFile]) {
      final database = AppDatabase(NativeDatabase(file));
      await database.customSelect('SELECT 1').get();
      await database.close();
    }
    final raw = sqlite.sqlite3.open(migratedFile.path);
    raw.execute('DROP TABLE future_matter_change_event_snapshots');
    raw.execute('DROP TABLE future_matter_change_events');
    raw.execute('PRAGMA user_version = 7');
    raw.close();
    final migrated = AppDatabase(NativeDatabase(migratedFile));
    await migrated.customSelect('SELECT 1').get();
    await migrated.close();

    expect(_schema(migratedFile), _schema(freshFile));
  });
}

List<String> _schema(File file) {
  final database = sqlite.sqlite3.open(file.path);
  try {
    return database
        .select('''
          SELECT type, name, sql FROM sqlite_schema
          WHERE name LIKE 'future_matter_change_%'
          ORDER BY type, name
        ''')
        .map((row) => '${row['type']}|${row['name']}|${row['sql']}')
        .toList(growable: false);
  } finally {
    database.close();
  }
}
