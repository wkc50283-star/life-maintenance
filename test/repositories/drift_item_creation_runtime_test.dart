import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/item_management_period.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_item_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/item_creation_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftItemCreationRuntime runtime;
  final now = DateTime.utc(2026, 7, 30, 8, 30);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    runtime = DriftItemCreationRuntime(database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() => database.close());

  ItemCreationRequest request({
    String itemId = 'item-created',
    String name = '  測試冷氣  ',
    String? categoryId,
    Set<ItemManagementPeriod> periods = const {
      ItemManagementPeriod.halfYear,
      ItemManagementPeriod.month,
    },
  }) => ItemCreationRequest(
    itemId: itemId,
    name: name,
    categoryId: categoryId,
    createdAt: now,
    managementPeriods: periods,
  );

  test('schema v4 seeds immutable unclassified system category', () async {
    final category = await repositories.itemCategories.findById(
      ItemSystemCategory.unclassifiedId,
    );

    expect(category, isNotNull);
    expect(category!.systemCode, ItemSystemCategory.unclassifiedCode);
    expect(category.displayName, ItemSystemCategory.unclassifiedDisplayName);
    expect(category.status, 'active');
    await expectLater(
      repositories.itemCategories.archive(category.id, now),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      repositories.itemCategories.deleteUnused(category.id),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test(
    'creates Item, normalized periods, and immutable snapshot atomically',
    () async {
      final result = await runtime.create(request());
      final item = await repositories.items.findById(result.itemId);
      final event = await runtime.findCreatedEvent(result.itemId);

      expect(item!.name, '測試冷氣');
      expect(item.categoryId, ItemSystemCategory.unclassifiedId);
      expect(await runtime.listManagementPeriods(item.id), {
        ItemManagementPeriod.halfYear,
        ItemManagementPeriod.month,
      });
      expect(event, isNotNull);
      expect(event!.id, 'item-created-${item.id}');
      expect(event.itemNameSnapshot, '測試冷氣');
      expect(event.categoryIdSnapshot, ItemSystemCategory.unclassifiedId);
      expect(
        event.categoryDisplayNameSnapshot,
        ItemSystemCategory.unclassifiedDisplayName,
      );
      expect(event.occurredAt, now);
      expect(event.managementPeriods, {
        ItemManagementPeriod.halfYear,
        ItemManagementPeriod.month,
      });
      expect(await database.select(database.schedules).get(), isEmpty);
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.generalReminders).get(), isEmpty);
      expect(await database.select(database.maintenancePlans).get(), isEmpty);
    },
  );

  test(
    'created event snapshots survive later Item and category edits',
    () async {
      await repositories.itemCategories.save(
        ItemCategoryRow(
          id: 'category-custom',
          customName: '家電',
          displayName: '家電',
          sortOrder: 1,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await runtime.create(request(categoryId: 'category-custom'));
      final original = await runtime.findCreatedEvent('item-created');
      final item = (await repositories.items.findById('item-created'))!;
      await repositories.items.save(
        item.copyWith(
          name: '已改名冷氣',
          updatedAt: now.add(const Duration(days: 1)),
        ),
      );
      final category = (await repositories.itemCategories.findById(
        'category-custom',
      ))!;
      await repositories.itemCategories.save(
        category.copyWith(
          customName: const Value('居家設備'),
          displayName: '居家設備',
          updatedAt: now.add(const Duration(days: 1)),
        ),
      );

      final after = await runtime.findCreatedEvent('item-created');
      expect(after!.itemNameSnapshot, original!.itemNameSnapshot);
      expect(
        after.categoryDisplayNameSnapshot,
        original.categoryDisplayNameSnapshot,
      );
    },
  );

  test('old Item is not backfilled with a fabricated created event', () async {
    await repositories.items.save(
      ItemRow(
        id: 'legacy-item',
        name: '舊生活項目',
        categoryId: ItemSystemCategory.unclassifiedId,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );

    expect(await runtime.findCreatedEvent('legacy-item'), isNull);
    final history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );
    expect(
      (await history.projectForItem('legacy-item')).itemCreatedEntries,
      isEmpty,
    );
  });

  test(
    'formal History projection exposes one structured created entry',
    () async {
      await runtime.create(request());
      final history = DriftHistoryProjectionRepository(
        database: database,
        attachments: repositories.attachments,
      );

      final projection = await history.projectForItem('item-created');
      expect(projection.itemCreatedEntries, hasLength(1));
      final entry = projection.itemCreatedEntries.single;
      expect(entry, isA<ItemCreatedHistoryEntry>());
      expect(entry.sourceId, 'item-created-item-created');
      expect(entry.occurredAt, now);
      expect(entry.event.managementPeriods, {
        ItemManagementPeriod.halfYear,
        ItemManagementPeriod.month,
      });
      expect(projection.entries, isEmpty);
    },
  );

  test(
    'created event and its structured period snapshot are immutable',
    () async {
      await runtime.create(request());

      await expectLater(
        (database.update(
          database.itemLifecycleEvents,
        )..where((table) => table.itemId.equals('item-created'))).write(
          const ItemLifecycleEventsCompanion(itemNameSnapshot: Value('改寫')),
        ),
        throwsA(anything),
      );
      await expectLater(
        (database.delete(database.itemLifecycleEventPeriods)..where(
              (table) => table.eventId.equals('item-created-item-created'),
            ))
            .go(),
        throwsA(anything),
      );
      final event = await runtime.findCreatedEvent('item-created');
      expect(event!.itemNameSnapshot, '測試冷氣');
      expect(event.managementPeriods, {
        ItemManagementPeriod.halfYear,
        ItemManagementPeriod.month,
      });
    },
  );

  test('duplicate created fact is rejected', () async {
    await runtime.create(request());
    await expectLater(runtime.create(request()), throwsA(anything));
    expect(
      await database.select(database.itemLifecycleEvents).get(),
      hasLength(1),
    );
  });

  test('creates Item and history with no management periods', () async {
    const itemId = 'empty-periods';
    await runtime.create(request(itemId: itemId, periods: const {}));

    expect(await database.select(database.items).get(), hasLength(1));
    expect(
      await database.select(database.itemLifecycleEvents).get(),
      hasLength(1),
    );
    expect(
      await database.select(database.itemManagementPeriods).get(),
      isEmpty,
    );
    expect(
      await database.select(database.itemLifecycleEventPeriods).get(),
      isEmpty,
    );

    final event = await runtime.findCreatedEvent(itemId);
    expect(event, isNotNull);
    expect(event!.managementPeriods, isEmpty);

    final history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );
    final projection = await history.projectForItem(itemId);
    expect(projection.itemCreatedEntries, hasLength(1));
    expect(
      projection.itemCreatedEntries.single.event.managementPeriods,
      isEmpty,
    );
  });

  test('supports all six formal management periods', () async {
    const periods = {
      ItemManagementPeriod.year,
      ItemManagementPeriod.halfYear,
      ItemManagementPeriod.quarter,
      ItemManagementPeriod.month,
      ItemManagementPeriod.week,
      ItemManagementPeriod.day,
    };
    expect(ItemManagementPeriod.values.toSet(), periods);
    await runtime.create(request(periods: periods));

    final event = await runtime.findCreatedEvent('item-created');
    expect(event, isNotNull);
    expect(event!.managementPeriods, periods);
    expect(await runtime.listManagementPeriods('item-created'), periods);
  });

  test(
    'lifecycle insert failure rolls back Item and both period sets',
    () async {
      await database.customStatement('''
      CREATE TRIGGER fail_item_lifecycle_insert
      BEFORE INSERT ON item_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'simulated lifecycle failure');
      END
    ''');

      await expectLater(runtime.create(request()), throwsA(anything));
      expect(await database.select(database.items).get(), isEmpty);
      expect(
        await database.select(database.itemManagementPeriods).get(),
        isEmpty,
      );
      expect(
        await database.select(database.itemLifecycleEvents).get(),
        isEmpty,
      );
      expect(
        await database.select(database.itemLifecycleEventPeriods).get(),
        isEmpty,
      );
    },
  );

  test(
    'event period failure rolls back every earlier creation write',
    () async {
      await database.customStatement('''
      CREATE TRIGGER fail_item_lifecycle_period_insert
      BEFORE INSERT ON item_lifecycle_event_periods
      BEGIN
        SELECT RAISE(ABORT, 'simulated lifecycle period failure');
      END
    ''');

      await expectLater(runtime.create(request()), throwsA(anything));
      expect(await database.select(database.items).get(), isEmpty);
      expect(
        await database.select(database.itemManagementPeriods).get(),
        isEmpty,
      );
      expect(
        await database.select(database.itemLifecycleEvents).get(),
        isEmpty,
      );
      expect(
        await database.select(database.itemLifecycleEventPeriods).get(),
        isEmpty,
      );
    },
  );
}
