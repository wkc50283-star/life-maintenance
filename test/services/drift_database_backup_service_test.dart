import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
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

  test('creates and validates a complete schema v10 SQLite backup', () async {
    final service = DriftDatabaseBackupService();

    final validation = await service.createBackup(
      source: source,
      destination: backup,
    );

    expect(validation.formatVersion, 10);
    expect(validation.rowCounts['items'], 1);
    expect(validation.rowCounts['item_management_periods'], 1);
    expect(validation.rowCounts['item_lifecycle_events'], 1);
    expect(validation.rowCounts['item_lifecycle_event_periods'], 1);
    expect(validation.rowCounts['item_custom_management_periods'], 1);
    expect(validation.rowCounts['item_lifecycle_event_custom_periods'], 1);
    expect(validation.rowCounts['item_management_period_change_events'], 1);
    expect(
      validation.rowCounts['item_management_period_change_event_periods'],
      2,
    );
    expect(
      validation
          .rowCounts['item_management_period_change_event_custom_periods'],
      2,
    );
    expect(validation.rowCounts['future_matters'], 3);
    expect(validation.rowCounts['future_matter_created_events'], 3);
    expect(validation.rowCounts['future_matter_change_events'], 1);
    expect(validation.rowCounts['future_matter_change_event_snapshots'], 2);
    expect(validation.rowCounts['future_matter_completed_events'], 1);
    expect(await _itemNames(backup), ['來源資料']);
    expect(await File('${backup.path}.restore-staging').exists(), isFalse);
  });

  test('restores a schema v4 backup that migrates cleanly to v9', () async {
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
    expect(migrated.schemaVersion, 10);
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

  test('restores a schema v5 backup that migrates cleanly to v9', () async {
    await _downgradeToSchemaV5(source);
    final service = DriftDatabaseBackupService();

    final validation = await service.restore(
      backup: source,
      destination: destination,
    );
    expect(validation.formatVersion, 5);
    expect(
      validation.rowCounts,
      isNot(contains('item_management_period_change_events')),
    );

    final migrated = AppDatabase(NativeDatabase(destination));
    addTearDown(migrated.close);
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 10);
    expect(await migrated.select(migrated.items).get(), hasLength(1));
    expect(
      await migrated.select(migrated.itemCustomManagementPeriods).get(),
      hasLength(1),
    );
    expect(
      await migrated.select(migrated.itemManagementPeriodChangeEvents).get(),
      isEmpty,
    );
  });

  test('restores a schema v6 backup that migrates cleanly to v9', () async {
    await _downgradeToSchemaV6(source);
    final service = DriftDatabaseBackupService();

    final validation = await service.restore(
      backup: source,
      destination: destination,
    );
    expect(validation.formatVersion, 6);
    expect(validation.rowCounts, isNot(contains('future_matters')));

    final migrated = AppDatabase(NativeDatabase(destination));
    addTearDown(migrated.close);
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 10);
    expect(await migrated.select(migrated.items).get(), hasLength(1));
    expect(await migrated.select(migrated.futureMatters).get(), isEmpty);
    expect(
      await migrated.select(migrated.futureMatterCreatedEvents).get(),
      isEmpty,
    );
  });

  test(
    'schema v9 restore preserves FutureMatter values and constraints',
    () async {
      final service = DriftDatabaseBackupService();
      await service.createBackup(source: source, destination: backup);
      await service.restore(backup: backup, destination: destination);

      final restored = AppDatabase(NativeDatabase(destination));
      await restored.customSelect('SELECT 1').get();
      final matters = await restored.select(restored.futureMatters).get();
      final events = await restored
          .select(restored.futureMatterCreatedEvents)
          .get();
      final changeEvents = await restored
          .select(restored.futureMatterChangeEvents)
          .get();
      final changeSnapshots = await restored
          .select(restored.futureMatterChangeEventSnapshots)
          .get();
      final completedEvents = await restored
          .select(restored.futureMatterCompletedEvents)
          .get();
      await restored.close();

      final specified = matters.singleWhere(
        (row) => row.id == 'future-specified-source-item',
      );
      expect(specified.specifiedDate, '2026-02-28');
      expect(specified.specifiedMinuteOfDay, isNull);
      final recurring = matters.singleWhere(
        (row) => row.id == 'future-recurring-source-item',
      );
      expect(recurring.recurringAnchorDate, '2028-02-29');
      expect(recurring.recurringAnchorMinuteOfDay, 0);
      final condition = matters.singleWhere(
        (row) => row.id == 'future-condition-source-item',
      );
      expect(
        condition.conditionMaintenanceRecordId,
        'maintenance-record-source-item',
      );

      final specifiedEvent = events.singleWhere(
        (row) => row.futureMatterId == 'future-specified-source-item',
      );
      expect(specifiedEvent.specifiedDateSnapshot, '2026-02-28');
      expect(specifiedEvent.specifiedMinuteOfDaySnapshot, isNull);
      final recurringEvent = events.singleWhere(
        (row) => row.futureMatterId == 'future-recurring-source-item',
      );
      expect(recurringEvent.recurringAnchorDateSnapshot, '2028-02-29');
      expect(recurringEvent.recurringAnchorMinuteOfDaySnapshot, 0);
      final conditionEvent = events.singleWhere(
        (row) => row.futureMatterId == 'future-condition-source-item',
      );
      expect(
        conditionEvent.conditionMaintenanceRecordIdSnapshot,
        'maintenance-record-source-item',
      );
      expect(changeEvents.single.id, 'future-change-source-item');
      final beforeSnapshot = changeSnapshots.singleWhere(
        (row) => row.snapshotSide == 'before',
      );
      final afterSnapshot = changeSnapshots.singleWhere(
        (row) => row.snapshotSide == 'after',
      );
      expect(beforeSnapshot.specifiedDate, '2026-02-28');
      expect(beforeSnapshot.specifiedMinuteOfDay, isNull);
      expect(afterSnapshot.specifiedDate, '2026-02-28');
      expect(afterSnapshot.specifiedMinuteOfDay, 0);
      expect(afterSnapshot.itemId, 'source-item');
      final completedEvent = completedEvents.single;
      expect(completedEvent.completedDate, '2026-07-21');
      expect(completedEvent.completedMinuteOfDay, 0);
      expect(completedEvent.confirmedAt, DateTime.utc(2026, 7, 22));
      expect(
        completedEvent.futureMatterUpdatedAtSnapshot,
        DateTime.utc(2026, 7, 21),
      );

      final raw = sqlite3.open(destination.path);
      try {
        final indexes = raw
            .select('''
            SELECT name FROM sqlite_schema
            WHERE type = 'index' AND name IN (
              'future_matters_item_idx',
              'future_matters_timing_mode_idx',
              'future_matter_created_events_matter_unique_idx',
              'future_matter_created_events_item_idx',
              'future_matter_change_events_matter_idx',
              'future_matter_change_event_snapshots_item_idx'
            )
          ''')
            .map((row) => row['name'])
            .toSet();
        expect(indexes, hasLength(6));
        expect(
          () => raw.execute(
            "UPDATE future_matter_created_events SET title_snapshot = '改寫' "
            "WHERE id = 'future-created-specified-source-item'",
          ),
          throwsA(isA<SqliteException>()),
        );
        expect(
          () => raw.execute(
            "UPDATE future_matter_change_event_snapshots SET title = '改寫' "
            "WHERE event_id = 'future-change-source-item'",
          ),
          throwsA(isA<SqliteException>()),
        );
        expect(
          () => raw.execute(
            "DELETE FROM future_matter_created_events "
            "WHERE id = 'future-created-specified-source-item'",
          ),
          throwsA(isA<SqliteException>()),
        );
        expect(
          () => raw.execute('''
          INSERT INTO future_matters (
            id, title, timing_mode, specified_date, created_at, updated_at
          ) VALUES (
            'invalid-restored-date', '非法日期', 'specifiedDate',
            '2026-02-29', 0, 0
          )
        '''),
          throwsA(isA<SqliteException>()),
        );
      } finally {
        raw.close();
      }
    },
  );

  test('restores schema v9 with null provenance and migrates to v10', () async {
    await _downgradeToSchemaV9(source);
    final service = DriftDatabaseBackupService();
    final validation = await service.createBackup(
      source: source,
      destination: backup,
    );
    expect(validation.formatVersion, 9);
    await service.restore(backup: backup, destination: destination);

    final migrated = AppDatabase(NativeDatabase(destination));
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 10);
    final matters = await migrated.select(migrated.futureMatters).get();
    expect(matters, isNotEmpty);
    expect(matters.every((row) => row.createdSource == null), isTrue);
    expect(
      await migrated.select(migrated.futureMatterAmendmentEvents).get(),
      isEmpty,
    );
    await migrated.close();
  });

  test(
    'schema v10 backup round trips amendment structured snapshots',
    () async {
      final sourceDatabase = AppDatabase(NativeDatabase(source));
      await sourceDatabase.customSelect('SELECT 1').get();
      await sourceDatabase
          .into(sourceDatabase.futureMatterAmendmentEvents)
          .insert(
            FutureMatterAmendmentEventsCompanion.insert(
              id: 'backup-amendment',
              futureMatterId: 'future-specified-source-item',
              eventType: 'supplement',
              targetEventKind: 'completed',
              targetEventId: 'future-completed-source-item',
              recordedAt: DateTime.utc(2026, 7, 22),
              eventSource: 'backfill',
              sourceReferenceKind: const Value('maintenanceRecord'),
              sourceReferenceId: const Value('maintenance-record-source-item'),
            ),
          );
      for (final entry in const [
        ('attachments', 'attachmentCollection'),
        ('cost', 'money'),
        ('relatedPeople', 'relatedPeopleCollection'),
      ]) {
        await sourceDatabase
            .into(sourceDatabase.futureMatterAmendmentFieldChanges)
            .insert(
              FutureMatterAmendmentFieldChangesCompanion.insert(
                eventId: 'backup-amendment',
                fieldKey: entry.$1,
                valueType: entry.$2,
                oldState: 'absent',
                newState: 'value',
              ),
            );
      }
      await sourceDatabase
          .into(sourceDatabase.futureMatterAmendmentAttachmentValues)
          .insert(
            FutureMatterAmendmentAttachmentValuesCompanion.insert(
              eventId: 'backup-amendment',
              valueSide: 'new',
              attachmentId: 'historic-attachment-id',
            ),
          );
      await sourceDatabase
          .into(sourceDatabase.futureMatterAmendmentMoneyValues)
          .insert(
            FutureMatterAmendmentMoneyValuesCompanion.insert(
              eventId: 'backup-amendment',
              valueSide: 'new',
              amountMinor: 0,
              currency: 'TWD',
            ),
          );
      await sourceDatabase
          .into(sourceDatabase.futureMatterAmendmentRelatedPeople)
          .insert(
            FutureMatterAmendmentRelatedPeopleCompanion.insert(
              id: 'backup-person',
              eventId: 'backup-amendment',
              valueSide: 'new',
              displayName: '王先生',
              relationNote: const Value('聯絡人'),
            ),
          );
      await sourceDatabase.close();

      final service = DriftDatabaseBackupService();
      await service.createBackup(source: source, destination: backup);
      await service.restore(backup: backup, destination: destination);
      final restored = AppDatabase(NativeDatabase(destination));
      await restored.customSelect('SELECT 1').get();
      expect(
        (await restored
                .select(restored.futureMatterAmendmentEvents)
                .getSingle())
            .sourceReferenceId,
        'maintenance-record-source-item',
      );
      expect(
        (await restored
                .select(restored.futureMatterAmendmentAttachmentValues)
                .getSingle())
            .attachmentId,
        'historic-attachment-id',
      );
      final money = await restored
          .select(restored.futureMatterAmendmentMoneyValues)
          .getSingle();
      expect((money.amountMinor, money.currency), (0, 'TWD'));
      final person = await restored
          .select(restored.futureMatterAmendmentRelatedPeople)
          .getSingle();
      expect((person.displayName, person.relationNote), ('王先生', '聯絡人'));
      await restored.close();
    },
  );

  test('restores a schema v7 backup that migrates cleanly to v9', () async {
    await _downgradeToSchemaV7(source);
    final service = DriftDatabaseBackupService();
    final validation = await service.restore(
      backup: source,
      destination: destination,
    );
    expect(validation.formatVersion, 7);
    expect(
      validation.rowCounts,
      isNot(contains('future_matter_change_events')),
    );

    final migrated = AppDatabase(NativeDatabase(destination));
    addTearDown(migrated.close);
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 10);
    expect(await migrated.select(migrated.futureMatters).get(), hasLength(3));
    expect(
      await migrated.select(migrated.futureMatterChangeEvents).get(),
      isEmpty,
    );
  });

  test('restores a schema v8 backup without fabricating completion', () async {
    await _downgradeToSchemaV8(source);
    final service = DriftDatabaseBackupService();
    final validation = await service.restore(
      backup: source,
      destination: destination,
    );
    expect(validation.formatVersion, 8);
    expect(
      validation.rowCounts,
      isNot(contains('future_matter_completed_events')),
    );

    final migrated = AppDatabase(NativeDatabase(destination));
    addTearDown(migrated.close);
    await migrated.customSelect('SELECT 1').get();
    expect(migrated.schemaVersion, 10);
    expect(
      (await migrated.select(migrated.futureMatters).get()).every(
        (row) => row.lifecycleStatus == 'active',
      ),
      isTrue,
    );
    expect(
      await migrated.select(migrated.futureMatterCompletedEvents).get(),
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
  await database
      .into(database.itemManagementPeriodChangeEvents)
      .insert(
        ItemManagementPeriodChangeEventsCompanion.insert(
          id: 'period-change-$itemId',
          itemId: itemId,
          occurredAt: now,
          createdAt: now,
        ),
      );
  for (final side in const ['before', 'after']) {
    await database
        .into(database.itemManagementPeriodChangeEventPeriods)
        .insert(
          ItemManagementPeriodChangeEventPeriodsCompanion.insert(
            eventId: 'period-change-$itemId',
            snapshotSide: side,
            period: 'month',
          ),
        );
    await database
        .into(database.itemManagementPeriodChangeEventCustomPeriods)
        .insert(
          ItemManagementPeriodChangeEventCustomPeriodsCompanion.insert(
            eventId: 'period-change-$itemId',
            snapshotSide: side,
            intervalValue: 2,
            intervalUnit: 'week',
            canonicalFamily: 'day',
            canonicalValue: 14,
          ),
        );
  }
  await database
      .into(database.maintenanceRecords)
      .insert(
        MaintenanceRecordsCompanion.insert(
          id: 'maintenance-record-$itemId',
          itemId: itemId,
          recordType: 'other',
          date: now,
          title: '正式完成來源',
          createdAt: now,
        ),
      );
  await database
      .into(database.futureMatters)
      .insert(
        FutureMattersCompanion.insert(
          id: 'future-specified-$itemId',
          title: '指定日期事項',
          itemId: Value(itemId),
          timingMode: 'specifiedDate',
          specifiedDate: const Value('2026-02-28'),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await database
      .into(database.futureMatterCreatedEvents)
      .insert(
        FutureMatterCreatedEventsCompanion.insert(
          id: 'future-created-specified-$itemId',
          futureMatterId: 'future-specified-$itemId',
          titleSnapshot: '指定日期事項',
          itemIdSnapshot: Value(itemId),
          timingModeSnapshot: 'specifiedDate',
          specifiedDateSnapshot: const Value('2026-02-28'),
          occurredAt: now,
          createdAt: now,
        ),
      );
  await database
      .into(database.futureMatterChangeEvents)
      .insert(
        FutureMatterChangeEventsCompanion.insert(
          id: 'future-change-$itemId',
          futureMatterId: 'future-specified-$itemId',
          occurredAt: now.add(const Duration(minutes: 1)),
          createdAt: now.add(const Duration(minutes: 1)),
        ),
      );
  for (final side in const ['before', 'after']) {
    await database
        .into(database.futureMatterChangeEventSnapshots)
        .insert(
          FutureMatterChangeEventSnapshotsCompanion.insert(
            eventId: 'future-change-$itemId',
            snapshotSide: side,
            title: '指定日期事項',
            itemId: Value(itemId),
            timingMode: 'specifiedDate',
            specifiedDate: const Value('2026-02-28'),
            specifiedMinuteOfDay: Value(side == 'before' ? null : 0),
            futureMatterCreatedAt: now,
            futureMatterUpdatedAt: side == 'before'
                ? now
                : now.add(const Duration(minutes: 1)),
          ),
        );
  }
  await database
      .into(database.futureMatters)
      .insert(
        FutureMattersCompanion.insert(
          id: 'future-recurring-$itemId',
          title: '固定重複事項',
          itemId: Value(itemId),
          timingMode: 'recurring',
          recurringIntervalValue: const Value(2),
          recurringIntervalUnit: const Value('month'),
          recurringAnchorDate: const Value('2028-02-29'),
          recurringAnchorMinuteOfDay: const Value(0),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await database
      .into(database.futureMatterCreatedEvents)
      .insert(
        FutureMatterCreatedEventsCompanion.insert(
          id: 'future-created-recurring-$itemId',
          futureMatterId: 'future-recurring-$itemId',
          titleSnapshot: '固定重複事項',
          itemIdSnapshot: Value(itemId),
          timingModeSnapshot: 'recurring',
          recurringIntervalValueSnapshot: const Value(2),
          recurringIntervalUnitSnapshot: const Value('month'),
          recurringAnchorDateSnapshot: const Value('2028-02-29'),
          recurringAnchorMinuteOfDaySnapshot: const Value(0),
          occurredAt: now,
          createdAt: now,
        ),
      );
  await database
      .into(database.futureMatters)
      .insert(
        FutureMattersCompanion.insert(
          id: 'future-condition-$itemId',
          title: '完成後事項',
          itemId: Value(itemId),
          timingMode: 'condition',
          conditionType: const Value('afterFormalCompletion'),
          conditionMaintenanceRecordId: Value('maintenance-record-$itemId'),
          conditionDelayValue: const Value(1),
          conditionDelayUnit: const Value('day'),
          createdAt: now,
          updatedAt: now,
        ),
      );
  await database
      .into(database.futureMatterCreatedEvents)
      .insert(
        FutureMatterCreatedEventsCompanion.insert(
          id: 'future-created-condition-$itemId',
          futureMatterId: 'future-condition-$itemId',
          titleSnapshot: '完成後事項',
          itemIdSnapshot: Value(itemId),
          timingModeSnapshot: 'condition',
          conditionTypeSnapshot: const Value('afterFormalCompletion'),
          conditionMaintenanceRecordIdSnapshot: Value(
            'maintenance-record-$itemId',
          ),
          conditionDelayValueSnapshot: const Value(1),
          conditionDelayUnitSnapshot: const Value('day'),
          occurredAt: now,
          createdAt: now,
        ),
      );
  final confirmedAt = now.add(const Duration(days: 1));
  await database
      .into(database.futureMatterCompletedEvents)
      .insert(
        FutureMatterCompletedEventsCompanion.insert(
          id: 'future-completed-$itemId',
          futureMatterId: 'future-specified-$itemId',
          completedDate: '2026-07-21',
          completedMinuteOfDay: const Value(0),
          confirmedAt: confirmedAt,
          createdAt: confirmedAt,
          titleSnapshot: '指定日期事項',
          itemIdSnapshot: Value(itemId),
          timingModeSnapshot: 'specifiedDate',
          specifiedDateSnapshot: const Value('2026-02-28'),
          futureMatterCreatedAtSnapshot: now,
          futureMatterUpdatedAtSnapshot: now,
        ),
      );
  await (database.update(
    database.futureMatters,
  )..where((table) => table.id.equals('future-specified-$itemId'))).write(
    FutureMattersCompanion(
      lifecycleStatus: const Value('completed'),
      updatedAt: Value(confirmedAt),
    ),
  );
  await database.close();
}

Future<void> _downgradeToSchemaV4(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV9(raw);
  _dropSchemaV8(raw);
  _dropSchemaV7(raw);
  _dropSchemaV6(raw);
  raw.execute('DROP TRIGGER item_management_periods_no_custom_equivalent');
  raw.execute('DROP TRIGGER item_lifecycle_event_periods_no_custom_equivalent');
  raw.execute('DROP TABLE item_lifecycle_event_custom_periods');
  raw.execute('DROP TABLE item_custom_management_periods');
  raw.execute('PRAGMA user_version = 4');
  raw.close();
}

Future<void> _downgradeToSchemaV9(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV10(raw);
  raw.execute('PRAGMA user_version = 9');
  raw.close();
}

Future<void> _downgradeToSchemaV5(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV9(raw);
  _dropSchemaV8(raw);
  _dropSchemaV7(raw);
  _dropSchemaV6(raw);
  raw.execute('PRAGMA user_version = 5');
  raw.close();
}

Future<void> _downgradeToSchemaV6(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV9(raw);
  _dropSchemaV8(raw);
  _dropSchemaV7(raw);
  raw.execute('PRAGMA user_version = 6');
  raw.close();
}

Future<void> _downgradeToSchemaV7(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV9(raw);
  _dropSchemaV8(raw);
  raw.execute('PRAGMA user_version = 7');
  raw.close();
}

Future<void> _downgradeToSchemaV8(File file) async {
  final raw = sqlite3.open(file.path);
  _dropSchemaV9(raw);
  raw.execute('PRAGMA user_version = 8');
  raw.close();
}

void _dropSchemaV8(Database database) {
  database.execute('DROP TABLE future_matter_change_event_snapshots');
  database.execute('DROP TABLE future_matter_change_events');
}

void _dropSchemaV9(Database database) {
  _dropSchemaV10(database);
  database.execute('DROP TRIGGER IF EXISTS future_matters_completed_no_update');
  database.execute(
    'DROP TRIGGER IF EXISTS future_matter_completed_events_no_update',
  );
  database.execute(
    'DROP TRIGGER IF EXISTS future_matter_completed_events_no_delete',
  );
  database.execute('DROP TABLE future_matter_completed_events');
  database.execute("UPDATE future_matters SET lifecycle_status = 'active'");
}

void _dropSchemaV10(Database database) {
  database.execute(
    'DROP TRIGGER IF EXISTS future_matters_created_provenance_no_update',
  );
  database.execute(
    'DROP TRIGGER IF EXISTS future_matters_created_provenance_validate_insert',
  );
  database.execute(
    'DROP TRIGGER IF EXISTS future_matters_created_provenance_validate_update',
  );
  for (final table in const [
    'future_matter_amendment_money_values',
    'future_matter_amendment_related_people',
    'future_matter_amendment_attachment_values',
    'future_matter_amendment_field_changes',
    'future_matter_amendment_events',
  ]) {
    database.execute('DROP TABLE IF EXISTS $table');
  }
  final columns = database
      .select("PRAGMA table_info('future_matters')")
      .map((row) => row['name'])
      .toSet();
  if (columns.contains('created_source')) {
    database.execute('ALTER TABLE future_matters DROP COLUMN created_source');
    database.execute(
      'ALTER TABLE future_matters DROP COLUMN created_source_reference_kind',
    );
    database.execute(
      'ALTER TABLE future_matters DROP COLUMN created_source_reference_id',
    );
  }
}

void _dropSchemaV7(Database database) {
  database.execute('DROP TABLE future_matter_created_events');
  database.execute('DROP TABLE future_matters');
}

void _dropSchemaV6(Database database) {
  database.execute(
    'DROP TABLE item_management_period_change_event_custom_periods',
  );
  database.execute('DROP TABLE item_management_period_change_event_periods');
  database.execute('DROP TABLE item_management_period_change_events');
}

Future<List<String>> _itemNames(File file) async {
  final database = AppDatabase(NativeDatabase(file));
  final rows = await database.select(database.items).get();
  await database.close();
  return rows.map((row) => row.name).toList(growable: false);
}
