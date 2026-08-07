import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/item_custom_management_period.dart';
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
    List<ItemCustomManagementPeriod> customPeriods = const [],
  }) => ItemCreationRequest(
    itemId: itemId,
    name: name,
    categoryId: categoryId,
    createdAt: now,
    managementPeriods: periods,
    customManagementPeriods: customPeriods,
  );

  test('schema v5 seeds immutable unclassified system category', () async {
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
    'stores multiple custom periods and immutable created snapshots',
    () async {
      final customPeriods = [
        ItemCustomManagementPeriod(
          intervalValue: 14,
          intervalUnit: ItemManagementIntervalUnit.day,
        ),
        ItemCustomManagementPeriod(
          intervalValue: 5,
          intervalUnit: ItemManagementIntervalUnit.month,
        ),
      ];
      await runtime.create(
        request(periods: const {}, customPeriods: customPeriods),
      );

      expect(await runtime.listCustomManagementPeriods('item-created'), {
        ...customPeriods,
      });
      final event = await runtime.findCreatedEvent('item-created');
      expect(event!.customManagementPeriods, {...customPeriods});
      expect(
        await database.select(database.itemCustomManagementPeriods).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.itemLifecycleEventCustomPeriods).get(),
        hasLength(2),
      );

      await expectLater(
        (database.delete(database.itemLifecycleEventCustomPeriods)..where(
              (table) => table.eventId.equals('item-created-item-created'),
            ))
            .go(),
        throwsA(anything),
      );
    },
  );

  test('N equals one is stored as the existing fixed period', () async {
    await runtime.create(
      request(
        periods: const {},
        customPeriods: [
          ItemCustomManagementPeriod(
            intervalValue: 1,
            intervalUnit: ItemManagementIntervalUnit.year,
          ),
        ],
      ),
    );

    expect(await runtime.listManagementPeriods('item-created'), {
      ItemManagementPeriod.year,
    });
    expect(await runtime.listCustomManagementPeriods('item-created'), isEmpty);
    final event = await runtime.findCreatedEvent('item-created');
    expect(event!.managementPeriods, {ItemManagementPeriod.year});
    expect(event.customManagementPeriods, isEmpty);
  });

  test(
    'rejects equivalent periods within and across representations',
    () async {
      Future<void> expectRejected(
        List<ItemCustomManagementPeriod> custom, {
        Set<ItemManagementPeriod> fixed = const {},
      }) async {
        await expectLater(
          runtime.create(request(periods: fixed, customPeriods: custom)),
          throwsA(isA<RepositoryConstraintException>()),
        );
        expect(await database.select(database.items).get(), isEmpty);
      }

      await expectRejected([
        ItemCustomManagementPeriod(
          intervalValue: 14,
          intervalUnit: ItemManagementIntervalUnit.day,
        ),
        ItemCustomManagementPeriod(
          intervalValue: 2,
          intervalUnit: ItemManagementIntervalUnit.week,
        ),
      ]);
      await expectRejected([
        ItemCustomManagementPeriod(
          intervalValue: 6,
          intervalUnit: ItemManagementIntervalUnit.month,
        ),
        ItemCustomManagementPeriod(
          intervalValue: 2,
          intervalUnit: ItemManagementIntervalUnit.quarter,
        ),
      ]);
      await expectRejected(
        [
          ItemCustomManagementPeriod(
            intervalValue: 7,
            intervalUnit: ItemManagementIntervalUnit.day,
          ),
        ],
        fixed: const {ItemManagementPeriod.week},
      );
    },
  );

  test('duration and calendar families remain distinct', () async {
    await runtime.create(
      request(
        periods: const {},
        customPeriods: [
          ItemCustomManagementPeriod(
            intervalValue: 30,
            intervalUnit: ItemManagementIntervalUnit.day,
          ),
          ItemCustomManagementPeriod(
            intervalValue: 1,
            intervalUnit: ItemManagementIntervalUnit.month,
          ),
        ],
      ),
    );

    expect(await runtime.listManagementPeriods('item-created'), {
      ItemManagementPeriod.month,
    });
    expect(await runtime.listCustomManagementPeriods('item-created'), {
      ItemCustomManagementPeriod(
        intervalValue: 30,
        intervalUnit: ItemManagementIntervalUnit.day,
      ),
    });
  });

  test(
    'database constraints reject equivalent and corrupted direct writes',
    () async {
      final sevenDays = ItemCustomManagementPeriod(
        intervalValue: 7,
        intervalUnit: ItemManagementIntervalUnit.day,
      );
      await runtime.create(
        request(periods: const {}, customPeriods: [sevenDays]),
      );

      await expectLater(
        database
            .into(database.itemManagementPeriods)
            .insert(
              ItemManagementPeriodsCompanion.insert(
                itemId: 'item-created',
                period: ItemManagementPeriod.week.name,
                createdAt: now,
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database
            .into(database.itemLifecycleEventPeriods)
            .insert(
              ItemLifecycleEventPeriodsCompanion.insert(
                eventId: 'item-created-item-created',
                period: ItemManagementPeriod.week.name,
              ),
            ),
        throwsA(anything),
      );
      await expectLater(
        database
            .into(database.itemCustomManagementPeriods)
            .insert(
              ItemCustomManagementPeriodsCompanion.insert(
                itemId: 'item-created',
                intervalValue: 2,
                intervalUnit: ItemManagementIntervalUnit.week.name,
                canonicalFamily: ItemManagementIntervalFamily.day.name,
                canonicalValue: 13,
                createdAt: now,
              ),
            ),
        throwsA(anything),
      );
      await runtime.create(
        request(
          itemId: 'fixed-item',
          periods: const {ItemManagementPeriod.week},
        ),
      );
      await expectLater(
        database
            .into(database.itemCustomManagementPeriods)
            .insert(
              ItemCustomManagementPeriodsCompanion.insert(
                itemId: 'fixed-item',
                intervalValue: 7,
                intervalUnit: ItemManagementIntervalUnit.day.name,
                canonicalFamily: ItemManagementIntervalFamily.day.name,
                canonicalValue: 7,
                createdAt: now,
              ),
            ),
        throwsA(anything),
      );
    },
  );

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
      expect(entry.event.customManagementPeriods, isEmpty);
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

  test('History projects the exact custom period snapshot', () async {
    final custom = ItemCustomManagementPeriod(
      intervalValue: 5,
      intervalUnit: ItemManagementIntervalUnit.month,
    );
    await runtime.create(request(periods: const {}, customPeriods: [custom]));
    final history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );

    final entry = (await history.projectForItem(
      'item-created',
    )).itemCreatedEntries.single;
    expect(entry.event.customManagementPeriods, {custom});
    expect(entry.sourceId, 'item-created-item-created');
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

  test('custom event period failure rolls back every creation write', () async {
    await database.customStatement('''
      CREATE TRIGGER fail_item_lifecycle_custom_period_insert
      BEFORE INSERT ON item_lifecycle_event_custom_periods
      BEGIN
        SELECT RAISE(ABORT, 'simulated custom lifecycle period failure');
      END
    ''');
    final custom = ItemCustomManagementPeriod(
      intervalValue: 5,
      intervalUnit: ItemManagementIntervalUnit.month,
    );

    await expectLater(
      runtime.create(request(periods: const {}, customPeriods: [custom])),
      throwsA(anything),
    );
    expect(await database.select(database.items).get(), isEmpty);
    expect(
      await database.select(database.itemCustomManagementPeriods).get(),
      isEmpty,
    );
    expect(await database.select(database.itemLifecycleEvents).get(), isEmpty);
    expect(
      await database.select(database.itemLifecycleEventCustomPeriods).get(),
      isEmpty,
    );
  });
}
