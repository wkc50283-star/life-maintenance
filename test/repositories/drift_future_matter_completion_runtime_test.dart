import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/future_matter.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_completion_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_completion_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftFutureMatterCreationRuntime creation;
  late DriftFutureMatterChangeRuntime changes;
  late DriftFutureMatterCompletionRuntime completion;
  late DriftHistoryProjectionRepository history;
  final createdAt = DateTime.utc(2026, 8, 8, 8);
  final changedAt = DateTime.utc(2026, 8, 9, 9);
  final confirmedAt = DateTime.utc(2026, 8, 10, 10, 11, 12, 13, 14);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    creation = DriftFutureMatterCreationRuntime(database);
    changes = DriftFutureMatterChangeRuntime(database);
    completion = DriftFutureMatterCompletionRuntime(database);
    history = DriftHistoryProjectionRepository(
      database: database,
      attachments: DriftSchemaV2Repositories(database).attachments,
    );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-1',
            name: '冷氣',
            categoryId: ItemSystemCategory.unclassifiedId,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: 'active',
          ),
        );
  });

  tearDown(() => database.close());

  Future<void> createMatter({
    String id = 'matter-1',
    String? itemId = 'item-1',
    FutureMatterTimingMode timingMode = FutureMatterTimingMode.later,
    int? recurringValue,
    FutureMatterIntervalUnit? recurringUnit,
  }) => creation.create(
    FutureMatterCreationRequest(
      id: id,
      eventId: 'created-$id',
      title: '未來事項 $id',
      itemId: itemId,
      timingMode: timingMode,
      recurringIntervalValue: recurringValue,
      recurringIntervalUnit: recurringUnit,
      createdAt: createdAt,
    ),
  );

  FutureMatterCompletionRequest request({
    String matterId = 'matter-1',
    String eventId = 'completed-1',
    FutureMatterDate date = const FutureMatterDate(2026, 8, 10),
    int? minute,
  }) => FutureMatterCompletionRequest(
    futureMatterId: matterId,
    eventId: eventId,
    completedDate: date,
    completedMinuteOfDay: minute,
    confirmedAt: confirmedAt,
  );

  test(
    'new matters are active and completion changes only lifecycle fields',
    () async {
      await createMatter();
      final before = (await completion.readCurrent('matter-1'))!;
      expect(before.lifecycleStatus, FutureMatterLifecycleStatus.active);

      final event = await completion.complete(request());
      final after = (await completion.readCurrent('matter-1'))!;
      expect(after.lifecycleStatus, FutureMatterLifecycleStatus.completed);
      expect(after.updatedAt, confirmedAt);
      expect(after.title, before.title);
      expect(after.itemId, before.itemId);
      expect(after.timingMode, before.timingMode);
      expect(after.createdAt, before.createdAt);
      expect(event.confirmedAt, confirmedAt);
      expect(event.createdAt, confirmedAt);
      expect(event.snapshot.updatedAt, before.updatedAt);
      expect(
        event.snapshot.lifecycleStatus,
        FutureMatterLifecycleStatus.active,
      );
    },
  );

  test(
    'date-only and nullable versus explicit midnight minute round trip',
    () async {
      for (final value in <int?>[null, 0, 1439]) {
        final id = 'matter-${value ?? 'null'}';
        await createMatter(id: id);
        await completion.complete(
          request(matterId: id, eventId: 'event-$id', minute: value),
        );
        final event = await completion.findCompletedEvent(id);
        expect(event!.completedDate, const FutureMatterDate(2026, 8, 10));
        expect(event.completedMinuteOfDay, value);
      }
      for (final value in [-1, 1440]) {
        await createMatter(id: 'invalid-$value');
        await expectLater(
          completion.complete(
            request(
              matterId: 'invalid-$value',
              eventId: 'invalid-event-$value',
              minute: value,
            ),
          ),
          throwsA(isA<RepositoryConstraintException>()),
        );
      }
    },
  );

  test('invalid completion calendar date rejects and rolls back', () async {
    await createMatter();
    await expectLater(
      completion.complete(request(date: const FutureMatterDate(2026, 2, 29))),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(
      (await completion.readCurrent('matter-1'))!.lifecycleStatus,
      FutureMatterLifecycleStatus.active,
    );
    expect(
      await database.select(database.futureMatterCompletedEvents).get(),
      isEmpty,
    );
  });

  test(
    'duplicate completion and completed replace including no-op reject',
    () async {
      await createMatter();
      await completion.complete(request());
      await expectLater(
        completion.complete(request(eventId: 'completed-2')),
        throwsA(isA<RepositoryConstraintException>()),
      );
      await expectLater(
        changes.replace(
          FutureMatterChangeRequest(
            futureMatterId: 'matter-1',
            eventId: 'noop-after-complete',
            itemId: 'item-1',
            timingMode: FutureMatterTimingMode.later,
            occurredAt: confirmedAt.add(const Duration(minutes: 1)),
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(
        await database.select(database.futureMatterCompletedEvents).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.futureMatterChangeEvents).get(),
        isEmpty,
      );
    },
  );

  test(
    'snapshot is immutable and preserves prior create and change facts',
    () async {
      await createMatter();
      await changes.replace(
        FutureMatterChangeRequest(
          futureMatterId: 'matter-1',
          eventId: 'change-1',
          itemId: 'item-1',
          timingMode: FutureMatterTimingMode.specifiedDate,
          specifiedDate: const FutureMatterDate(2026, 8, 20),
          occurredAt: changedAt,
        ),
      );
      final createdBefore = await creation.findCreatedEvent('matter-1');
      final changesBefore = await changes.listChanges('matter-1');
      final event = await completion.complete(request());
      expect(event.snapshot.updatedAt, changedAt);
      expect(event.snapshot.specifiedDate, const FutureMatterDate(2026, 8, 20));
      expect(
        (await creation.findCreatedEvent('matter-1'))!.id,
        createdBefore!.id,
      );
      expect(
        await changes.listChanges('matter-1'),
        hasLength(changesBefore.length),
      );
      await expectLater(
        (database.update(
          database.futureMatterCompletedEvents,
        )..where((table) => table.id.equals('completed-1'))).write(
          const FutureMatterCompletedEventsCompanion(
            titleSnapshot: Value('改寫'),
          ),
        ),
        throwsA(anything),
      );
      await expectLater(
        (database.delete(
          database.futureMatterCompletedEvents,
        )..where((table) => table.id.equals('completed-1'))).go(),
        throwsA(anything),
      );
    },
  );

  test('event insert failure rolls back main lifecycle update', () async {
    await createMatter(id: 'matter-a');
    await createMatter(id: 'matter-b');
    await completion.complete(
      request(matterId: 'matter-a', eventId: 'duplicate'),
    );
    await expectLater(
      completion.complete(request(matterId: 'matter-b', eventId: 'duplicate')),
      throwsA(anything),
    );
    final matterB = await completion.readCurrent('matter-b');
    expect(matterB!.lifecycleStatus, FutureMatterLifecycleStatus.active);
    expect(matterB.updatedAt, createdAt);
  });

  test('global and item History use snapshot scope and confirmedAt', () async {
    await createMatter();
    await createMatter(id: 'global-only', itemId: null);
    await completion.complete(request());
    await completion.complete(
      request(matterId: 'global-only', eventId: 'completed-global'),
    );
    final global = await history.projectGlobalFutureMatterCompletedEntries();
    expect(global, hasLength(2));
    expect(global.first.occurredAt, confirmedAt);
    final item = await history.projectForItem('item-1');
    expect(item.futureMatterCompletedEntries, hasLength(1));
    expect(
      item.futureMatterCompletedEntries.single.event.futureMatterId,
      'matter-1',
    );
  });

  test(
    'recurring completion creates no next matter, record, task, or schedule',
    () async {
      await createMatter(
        timingMode: FutureMatterTimingMode.recurring,
        recurringValue: 1,
        recurringUnit: FutureMatterIntervalUnit.year,
      );
      await completion.complete(request());
      expect(await database.select(database.futureMatters).get(), hasLength(1));
      expect(await database.select(database.maintenanceRecords).get(), isEmpty);
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.schedules).get(), isEmpty);
    },
  );
}
