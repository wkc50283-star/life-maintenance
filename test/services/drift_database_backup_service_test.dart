import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/services/drift_database_backup_service.dart';
import 'package:sqlite3/sqlite3.dart';

void main() {
  late Directory directory;
  late File source;
  late File backup;
  late File destination;

  setUp(() async {
    directory = await Directory.systemTemp.createTemp(
      'life-management-backup-safety-',
    );
    source = File('${directory.path}/source.sqlite');
    backup = File('${directory.path}/backup.sqlite');
    destination = File('${directory.path}/destination.sqlite');
    await _writeDatabase(source, itemId: 'source-item', itemName: '來源資料');
  });

  tearDown(() async {
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  test('creates and validates a complete schema v5 SQLite backup', () async {
    final service = DriftDatabaseBackupService();

    final validation = await service.createBackup(
      source: source,
      destination: backup,
    );

    expect(validation.formatVersion, 5);
    expect(validation.rowCounts['items'], 1);
    expect(validation.rowCounts['item_management_periods'], 1);
    expect(validation.rowCounts['item_lifecycle_events'], 1);
    expect(validation.rowCounts['item_lifecycle_event_periods'], 1);
    expect(validation.rowCounts['item_custom_management_periods'], 1);
    expect(validation.rowCounts['item_lifecycle_event_custom_periods'], 1);
    expect(await _itemNames(backup), ['來源資料']);
    expect(await File('${backup.path}.restore-staging').exists(), isFalse);
  });

  test('restores a schema v4 backup that migrates cleanly to v5', () async {
    await _downgradeToSchemaV4(source);
    final service = DriftDatabaseBackupService();

    final validation = await service.restore(
      backup: source,
      destination: destination,
    );
    expect(validation.formatVersion, 4);
    expect(
      validation.rowCounts,
      isNot(contains('item_custom_management_periods')),
    );

    final migrated = AppDatabase(NativeDatabase(destination));
    addTearDown(migrated.close);
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 5);
    expect(await migrated.select(migrated.items).get(), hasLength(1));
    expect(
      await migrated.select(migrated.itemCustomManagementPeriods).get(),
      isEmpty,
    );
    expect(
      await migrated.select(migrated.itemLifecycleEventCustomPeriods).get(),
      isEmpty,
    );
  });

  test(
    'rejects invalid format and unsupported versions before restore',
    () async {
      await backup.writeAsString('not a sqlite database');
      final service = DriftDatabaseBackupService();

      await expectLater(
        service.restore(backup: backup, destination: destination),
        throwsA(isA<DatabaseBackupException>()),
      );
      expect(await destination.exists(), isFalse);

      await backup.delete();
      await _writeDatabase(backup, itemId: 'wrong-version', itemName: '錯誤版本');
      final raw = sqlite3.open(backup.path);
      raw.execute('PRAGMA user_version = 99');
      raw.close();
      await expectLater(
        service.restore(backup: backup, destination: destination),
        throwsA(
          isA<DatabaseBackupException>().having(
            (error) => error.message,
            'message',
            contains('Unsupported database backup version'),
          ),
        ),
      );
      expect(await destination.exists(), isFalse);
    },
  );

  test(
    'restore atomically replaces the destination after validation',
    () async {
      final service = DriftDatabaseBackupService();
      await service.createBackup(source: source, destination: backup);
      await _writeDatabase(
        destination,
        itemId: 'destination-item',
        itemName: '待還原資料',
      );

      final validation = await service.restore(
        backup: backup,
        destination: destination,
      );

      expect(validation.rowCounts['items'], 1);
      expect(await _itemNames(destination), ['來源資料']);
      expect(
        await File('${destination.path}.restore-staging').exists(),
        isFalse,
      );
    },
  );

  test('rejects missing tables and foreign-key violations', () async {
    final service = DriftDatabaseBackupService();
    final raw = sqlite3.open(source.path);
    raw.execute('DROP TABLE attachments');
    raw.close();

    await expectLater(
      service.validate(source),
      throwsA(
        isA<DatabaseBackupException>().having(
          (error) => error.message,
          'message',
          contains('missing required tables'),
        ),
      ),
    );

    await source.delete();
    await _writeDatabase(source, itemId: 'orphan', itemName: '孤兒資料');
    final orphaned = sqlite3.open(source.path);
    orphaned.execute('PRAGMA foreign_keys = OFF');
    orphaned.execute(
      "DELETE FROM item_categories WHERE id = 'category-orphan'",
    );
    orphaned.close();

    await expectLater(
      service.validate(source),
      throwsA(
        isA<DatabaseBackupException>().having(
          (error) => error.message,
          'message',
          contains('foreign-key violations'),
        ),
      ),
    );
  });

  test('mid-copy failure leaves no partial destination writes', () async {
    await _writeDatabase(
      destination,
      itemId: 'destination-item',
      itemName: '原本資料',
    );
    final service = DriftDatabaseBackupService(
      snapshotWriter: (sourceDatabase, stagedDatabase) async {
        stagedDatabase.execute('CREATE TABLE partial_write (value TEXT)');
        stagedDatabase.execute(
          "INSERT INTO partial_write (value) VALUES ('incomplete')",
        );
        throw StateError('Simulated interrupted restore.');
      },
    );

    await expectLater(
      service.restore(backup: source, destination: destination),
      throwsStateError,
    );

    expect(await _itemNames(destination), ['原本資料']);
    expect(await File('${destination.path}.restore-staging').exists(), isFalse);
  });

  test(
    'promotion failure rolls back without replacing existing data',
    () async {
      await _writeDatabase(
        destination,
        itemId: 'destination-item',
        itemName: '原本資料',
      );
      final service = DriftDatabaseBackupService(
        backupPromoter: (stagedFile, destinationFile) async {
          throw FileSystemException(
            'Simulated atomic promotion failure.',
            destinationFile.path,
          );
        },
      );

      await expectLater(
        service.restore(backup: source, destination: destination),
        throwsA(isA<FileSystemException>()),
      );

      expect(await _itemNames(destination), ['原本資料']);
      expect(
        await File('${destination.path}.restore-staging').exists(),
        isFalse,
      );
    },
  );

  test('never overwrites an existing backup', () async {
    await _writeDatabase(backup, itemId: 'immutable', itemName: '既有備份');
    final service = DriftDatabaseBackupService();

    await expectLater(
      service.createBackup(source: source, destination: backup),
      throwsA(
        isA<DatabaseBackupException>().having(
          (error) => error.message,
          'message',
          contains('will not be overwritten'),
        ),
      ),
    );
    expect(await _itemNames(backup), ['既有備份']);
  });
}

Future<void> _writeDatabase(
  File file, {
  required String itemId,
  required String itemName,
}) async {
  final database = AppDatabase(NativeDatabase(file));
  final now = DateTime.utc(2026, 7, 21);
  await database
      .into(database.itemCategories)
      .insert(
        ItemCategoriesCompanion.insert(
          id: 'category-$itemId',
          systemCode: const Value('other'),
          displayName: '其他',
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
          name: itemName,
          categoryId: 'category-$itemId',
          createdAt: now,
          updatedAt: now,
          status: 'active',
        ),
      );
  await database
      .into(database.itemCustomManagementPeriods)
      .insert(
        ItemCustomManagementPeriodsCompanion.insert(
          itemId: itemId,
          intervalValue: 2,
          intervalUnit: 'week',
          canonicalFamily: 'day',
          canonicalValue: 14,
          createdAt: now,
        ),
      );
  await database
      .into(database.itemManagementPeriods)
      .insert(
        ItemManagementPeriodsCompanion.insert(
          itemId: itemId,
          period: 'month',
          createdAt: now,
        ),
      );
  await database
      .into(database.itemLifecycleEvents)
      .insert(
        ItemLifecycleEventsCompanion.insert(
          id: 'item-created-$itemId',
          itemId: itemId,
          eventType: 'created',
          itemNameSnapshot: itemName,
          categoryIdSnapshot: 'category-$itemId',
          categorySystemCodeSnapshot: const Value('other'),
          categoryDisplayNameSnapshot: '其他',
          occurredAt: now,
          createdAt: now,
        ),
      );
  await database
      .into(database.itemLifecycleEventPeriods)
      .insert(
        ItemLifecycleEventPeriodsCompanion.insert(
          eventId: 'item-created-$itemId',
          period: 'month',
        ),
      );
  await database
      .into(database.itemLifecycleEventCustomPeriods)
      .insert(
        ItemLifecycleEventCustomPeriodsCompanion.insert(
          eventId: 'item-created-$itemId',
          intervalValue: 2,
          intervalUnit: 'week',
          canonicalFamily: 'day',
          canonicalValue: 14,
        ),
      );
  await database.close();
}

Future<void> _downgradeToSchemaV4(File file) async {
  final raw = sqlite3.open(file.path);
  raw.execute('DROP TRIGGER item_management_periods_no_custom_equivalent');
  raw.execute('DROP TRIGGER item_lifecycle_event_periods_no_custom_equivalent');
  raw.execute('DROP TABLE item_lifecycle_event_custom_periods');
  raw.execute('DROP TABLE item_custom_management_periods');
  raw.execute('PRAGMA user_version = 4');
  raw.close();
}

Future<List<String>> _itemNames(File file) async {
  final database = AppDatabase(NativeDatabase(file));
  final rows = await database.select(database.items).get();
  await database.close();
  return rows.map((row) => row.name).toList(growable: false);
}
