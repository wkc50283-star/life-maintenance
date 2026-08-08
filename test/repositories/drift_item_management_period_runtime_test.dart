import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/item_custom_management_period.dart';
import 'package:life_maintenance/models/item_management_period.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_item_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_item_management_period_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/item_creation_runtime.dart';
import 'package:life_maintenance/repositories/item_management_period_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftItemCreationRuntime creationRuntime;
  late DriftItemManagementPeriodRuntime runtime;
  late DriftSchemaV2Repositories repositories;
  final createdAt = DateTime.utc(2026, 8, 8, 8);

  ItemCustomManagementPeriod custom(
    int value,
    ItemManagementIntervalUnit unit,
  ) => ItemCustomManagementPeriod(intervalValue: value, intervalUnit: unit);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    creationRuntime = DriftItemCreationRuntime(database);
    runtime = DriftItemManagementPeriodRuntime(database);
    repositories = DriftSchemaV2Repositories(database);
    await database.customSelect('SELECT 1').get();
    await creationRuntime.create(
      ItemCreationRequest(
        itemId: 'item-1',
        name: '客廳冷氣',
        createdAt: createdAt,
        managementPeriods: const {ItemManagementPeriod.month},
        customManagementPeriods: [custom(2, ItemManagementIntervalUnit.week)],
      ),
    );
  });

  tearDown(() => database.close());

  ItemManagementPeriodChangeRequest request({
    String eventId = 'change-1',
    DateTime? occurredAt,
    Set<ItemManagementPeriod> fixed = const {ItemManagementPeriod.year},
    List<ItemCustomManagementPeriod>? customPeriods,
  }) => ItemManagementPeriodChangeRequest(
    eventId: eventId,
    itemId: 'item-1',
    occurredAt: occurredAt ?? createdAt.add(const Duration(hours: 1)),
    fixed: fixed,
    custom: customPeriods ?? [custom(3, ItemManagementIntervalUnit.quarter)],
  );

  test(
    'replaces fixed and custom periods with immutable before and after snapshots',
    () async {
      final createdEventBefore = await creationRuntime.findCreatedEvent(
        'item-1',
      );

      final event = await runtime.replace(request());

      expect(event, isNotNull);
      expect(event!.before.fixed, {ItemManagementPeriod.month});
      expect(event.before.custom, {custom(2, ItemManagementIntervalUnit.week)});
      expect(event.after.fixed, {ItemManagementPeriod.year});
      expect(event.after.custom, {
        custom(3, ItemManagementIntervalUnit.quarter),
      });
      final current = await runtime.readCurrent('item-1');
      expect(current.fixed, event.after.fixed);
      expect(current.custom, event.after.custom);
      expect(await runtime.listChanges('item-1'), hasLength(1));

      final createdEventAfter = await creationRuntime.findCreatedEvent(
        'item-1',
      );
      expect(
        createdEventAfter!.managementPeriods,
        createdEventBefore!.managementPeriods,
      );
      expect(
        createdEventAfter.customManagementPeriods,
        createdEventBefore.customManagementPeriods,
      );
    },
  );

  test('supports adding deleting and clearing all periods', () async {
    await runtime.replace(request());
    await runtime.replace(
      request(
        eventId: 'change-2',
        occurredAt: createdAt.add(const Duration(hours: 2)),
        fixed: const {},
        customPeriods: const [],
      ),
    );

    final current = await runtime.readCurrent('item-1');
    expect(current.fixed, isEmpty);
    expect(current.custom, isEmpty);
    final changes = await runtime.listChanges('item-1');
    expect(changes, hasLength(2));
    expect(changes.last.before.fixed, {ItemManagementPeriod.year});
    expect(changes.last.after.fixed, isEmpty);
    expect(changes.last.after.custom, isEmpty);
  });

  test('N equals one is normalized to a fixed period', () async {
    final event = await runtime.replace(
      request(
        fixed: const {},
        customPeriods: [custom(1, ItemManagementIntervalUnit.halfYear)],
      ),
    );

    expect(event!.after.fixed, {ItemManagementPeriod.halfYear});
    expect(event.after.custom, isEmpty);
    expect((await runtime.readCurrent('item-1')).fixed, {
      ItemManagementPeriod.halfYear,
    });
  });

  test('equivalent duplicates reject the whole transaction', () async {
    final before = await runtime.readCurrent('item-1');

    await expectLater(
      runtime.replace(
        request(
          fixed: const {ItemManagementPeriod.week},
          customPeriods: [custom(7, ItemManagementIntervalUnit.day)],
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );

    final after = await runtime.readCurrent('item-1');
    expect(after.fixed, before.fixed);
    expect(after.custom, before.custom);
    expect(await runtime.listChanges('item-1'), isEmpty);
  });

  test('an unchanged normalized set does not create history', () async {
    final result = await runtime.replace(
      request(
        fixed: const {ItemManagementPeriod.month},
        customPeriods: [custom(2, ItemManagementIntervalUnit.week)],
      ),
    );

    expect(result, isNull);
    expect(await runtime.listChanges('item-1'), isEmpty);
  });

  test('a changed original custom representation creates history', () async {
    final event = await runtime.replace(
      request(
        fixed: const {ItemManagementPeriod.month},
        customPeriods: [custom(14, ItemManagementIntervalUnit.day)],
      ),
    );

    expect(event, isNotNull);
    expect(event!.before.custom, {custom(2, ItemManagementIntervalUnit.week)});
    expect(event.after.custom, {custom(14, ItemManagementIntervalUnit.day)});
  });

  test('an archived Item remains unavailable for changes', () async {
    await (database.update(
      database.items,
    )..where((table) => table.id.equals('item-1'))).write(
      ItemsCompanion(
        status: const Value('archived'),
        archivedAt: Value(createdAt),
      ),
    );

    await expectLater(
      runtime.replace(request()),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await runtime.listChanges('item-1'), isEmpty);
  });

  test(
    'event write failure rolls current periods and snapshots back',
    () async {
      await runtime.replace(request());
      final before = await runtime.readCurrent('item-1');

      await expectLater(
        runtime.replace(
          request(
            eventId: 'change-1',
            fixed: const {ItemManagementPeriod.day},
            customPeriods: const [],
          ),
        ),
        throwsA(anything),
      );

      final after = await runtime.readCurrent('item-1');
      expect(after.fixed, before.fixed);
      expect(after.custom, before.custom);
      expect(await runtime.listChanges('item-1'), hasLength(1));
    },
  );

  test('change events and both snapshot tables are immutable', () async {
    await runtime.replace(request());

    await expectLater(
      (database.update(
        database.itemManagementPeriodChangeEvents,
      )..where((table) => table.id.equals('change-1'))).write(
        ItemManagementPeriodChangeEventsCompanion(occurredAt: Value(createdAt)),
      ),
      throwsA(anything),
    );
    await expectLater(
      (database.delete(
        database.itemManagementPeriodChangeEventPeriods,
      )..where((table) => table.eventId.equals('change-1'))).go(),
      throwsA(anything),
    );
    await expectLater(
      (database.delete(
        database.itemManagementPeriodChangeEventCustomPeriods,
      )..where((table) => table.eventId.equals('change-1'))).go(),
      throwsA(anything),
    );
  });

  test('change snapshot tables reject fixed and custom equivalents', () async {
    await runtime.replace(request());

    await expectLater(
      database
          .into(database.itemManagementPeriodChangeEventCustomPeriods)
          .insert(
            const ItemManagementPeriodChangeEventCustomPeriodsCompanion(
              eventId: Value('change-1'),
              snapshotSide: Value('after'),
              intervalValue: Value(12),
              intervalUnit: Value('month'),
              canonicalFamily: Value('calendarMonth'),
              canonicalValue: Value(12),
            ),
          ),
      throwsA(anything),
    );
  });

  test(
    'History projection exposes complete before and after snapshots',
    () async {
      await runtime.replace(request());
      final history = DriftHistoryProjectionRepository(
        database: database,
        attachments: repositories.attachments,
      );

      final projection = await history.projectForItem('item-1');

      expect(projection.itemCreatedEntries, hasLength(1));
      expect(projection.itemManagementPeriodChangeEntries, hasLength(1));
      final entry = projection.itemManagementPeriodChangeEntries.single;
      expect(entry.sourceId, 'change-1');
      expect(entry.event.before.fixed, {ItemManagementPeriod.month});
      expect(entry.event.after.fixed, {ItemManagementPeriod.year});
      expect(entry.event.before.custom, {
        custom(2, ItemManagementIntervalUnit.week),
      });
      expect(entry.event.after.custom, {
        custom(3, ItemManagementIntervalUnit.quarter),
      });
    },
  );
}
