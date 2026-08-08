import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/future_matter.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftFutureMatterCreationRuntime creation;
  late DriftFutureMatterChangeRuntime changes;
  late DriftHistoryProjectionRepository history;
  final createdAt = DateTime.utc(2026, 8, 8, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    creation = DriftFutureMatterCreationRuntime(database);
    changes = DriftFutureMatterChangeRuntime(database);
    history = DriftHistoryProjectionRepository(
      database: database,
      attachments: DriftSchemaV2Repositories(database).attachments,
    );
    for (final id in ['item-a', 'item-b']) {
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: id,
              name: id,
              categoryId: ItemSystemCategory.unclassifiedId,
              createdAt: createdAt,
              updatedAt: createdAt,
              status: 'active',
            ),
          );
    }
    await database
        .into(database.maintenanceRecords)
        .insert(
          MaintenanceRecordsCompanion.insert(
            id: 'record-1',
            itemId: 'item-a',
            recordType: 'other',
            date: createdAt,
            title: '正式完成',
            createdAt: createdAt,
          ),
        );
    await creation.create(
      FutureMatterCreationRequest(
        id: 'matter-1',
        eventId: 'created-1',
        title: '未來事項',
        timingMode: FutureMatterTimingMode.later,
        createdAt: createdAt,
      ),
    );
  });

  tearDown(() => database.close());

  FutureMatterChangeRequest request({
    required String eventId,
    required FutureMatterTimingMode mode,
    String? itemId,
    FutureMatterDate? specifiedDate,
    int? specifiedMinute,
    int? recurringValue,
    FutureMatterIntervalUnit? recurringUnit,
    FutureMatterDate? anchorDate,
    int? anchorMinute,
    FutureMatterConditionType? conditionType,
    String? conditionRecordId,
    int? conditionValue,
    FutureMatterIntervalUnit? conditionUnit,
  }) => FutureMatterChangeRequest(
    futureMatterId: 'matter-1',
    eventId: eventId,
    itemId: itemId,
    timingMode: mode,
    specifiedDate: specifiedDate,
    specifiedMinuteOfDay: specifiedMinute,
    recurringIntervalValue: recurringValue,
    recurringIntervalUnit: recurringUnit,
    recurringAnchorDate: anchorDate,
    recurringAnchorMinuteOfDay: anchorMinute,
    conditionType: conditionType,
    conditionMaintenanceRecordId: conditionRecordId,
    conditionDelayValue: conditionValue,
    conditionDelayUnit: conditionUnit,
    occurredAt: createdAt.add(Duration(minutes: eventId.length)),
  );

  test(
    'later changes to specified date with null or midnight minute',
    () async {
      const date = FutureMatterDate(2026, 9, 12);
      final first = await changes.replace(
        request(
          eventId: 'change-specified-null',
          mode: FutureMatterTimingMode.specifiedDate,
          specifiedDate: date,
        ),
      );
      expect(first!.before.timingMode, FutureMatterTimingMode.later);
      expect(first.after.specifiedDate, date);
      expect(first.after.specifiedMinuteOfDay, isNull);

      final second = await changes.replace(
        request(
          eventId: 'change-specified-midnight',
          mode: FutureMatterTimingMode.specifiedDate,
          specifiedDate: date,
          specifiedMinute: 0,
        ),
      );
      expect(second!.before.specifiedMinuteOfDay, isNull);
      expect(second.after.specifiedMinuteOfDay, 0);
    },
  );

  test(
    'recurring allows no anchor and year while condition rejects year',
    () async {
      final recurring = await changes.replace(
        request(
          eventId: 'change-recurring',
          mode: FutureMatterTimingMode.recurring,
          recurringValue: 2,
          recurringUnit: FutureMatterIntervalUnit.year,
        ),
      );
      expect(recurring!.after.recurringAnchorDate, isNull);
      expect(
        recurring.after.recurringIntervalUnit,
        FutureMatterIntervalUnit.year,
      );

      await expectLater(
        changes.replace(
          request(
            eventId: 'change-condition-year',
            mode: FutureMatterTimingMode.condition,
            conditionType: FutureMatterConditionType.afterFormalCompletion,
            conditionRecordId: 'record-1',
            conditionValue: 1,
            conditionUnit: FutureMatterIntervalUnit.year,
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(await changes.listChanges('matter-1'), hasLength(1));
    },
  );

  test(
    'condition requires an existing MaintenanceRecord and clears on exit',
    () async {
      await expectLater(
        changes.replace(
          request(
            eventId: 'missing-record',
            mode: FutureMatterTimingMode.condition,
            conditionType: FutureMatterConditionType.afterFormalCompletion,
            conditionRecordId: 'missing',
            conditionValue: 2,
            conditionUnit: FutureMatterIntervalUnit.day,
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      final condition = await changes.replace(
        request(
          eventId: 'valid-condition',
          mode: FutureMatterTimingMode.condition,
          conditionType: FutureMatterConditionType.afterFormalCompletion,
          conditionRecordId: 'record-1',
          conditionValue: 2,
          conditionUnit: FutureMatterIntervalUnit.day,
        ),
      );
      expect(condition!.after.conditionMaintenanceRecordId, 'record-1');
      final later = await changes.replace(
        request(
          eventId: 'condition-to-later',
          mode: FutureMatterTimingMode.later,
        ),
      );
      expect(later!.after.conditionType, isNull);
      expect(later.after.conditionMaintenanceRecordId, isNull);
      expect(later.after.conditionDelayValue, isNull);
      expect(later.after.conditionDelayUnit, isNull);
    },
  );

  test(
    'item scope changes null to A to B to null in item and global History',
    () async {
      await changes.replace(
        request(
          eventId: 'null-a',
          mode: FutureMatterTimingMode.later,
          itemId: 'item-a',
        ),
      );
      await changes.replace(
        request(
          eventId: 'a-b',
          mode: FutureMatterTimingMode.later,
          itemId: 'item-b',
        ),
      );
      await changes.replace(
        request(eventId: 'b-null', mode: FutureMatterTimingMode.later),
      );

      expect(
        await history.projectGlobalFutureMatterChangeEntries(),
        hasLength(3),
      );
      expect(
        (await history.projectForItem('item-a')).futureMatterChangeEntries,
        hasLength(2),
      );
      expect(
        (await history.projectForItem('item-b')).futureMatterChangeEntries,
        hasLength(2),
      );
    },
  );

  test('existing timing modes change through every approved shape', () async {
    const date = FutureMatterDate(2026, 10, 3);
    final specified = await changes.replace(
      request(
        eventId: 'shape-specified',
        mode: FutureMatterTimingMode.specifiedDate,
        specifiedDate: date,
        specifiedMinute: 9 * 60,
      ),
    );
    expect(specified!.after.timingMode, FutureMatterTimingMode.specifiedDate);
    final recurring = await changes.replace(
      request(
        eventId: 'shape-recurring',
        mode: FutureMatterTimingMode.recurring,
        recurringValue: 3,
        recurringUnit: FutureMatterIntervalUnit.month,
        anchorDate: date,
        anchorMinute: 0,
      ),
    );
    expect(recurring!.before.timingMode, FutureMatterTimingMode.specifiedDate);
    expect(recurring.after.timingMode, FutureMatterTimingMode.recurring);
    final condition = await changes.replace(
      request(
        eventId: 'shape-condition',
        mode: FutureMatterTimingMode.condition,
        conditionType: FutureMatterConditionType.afterFormalCompletion,
        conditionRecordId: 'record-1',
        conditionValue: 1,
        conditionUnit: FutureMatterIntervalUnit.hour,
      ),
    );
    expect(condition!.before.timingMode, FutureMatterTimingMode.recurring);
    expect(condition.after.timingMode, FutureMatterTimingMode.condition);
  });

  test('same before and after Item projects one history entry', () async {
    await changes.replace(
      request(
        eventId: 'attach-a',
        mode: FutureMatterTimingMode.later,
        itemId: 'item-a',
      ),
    );
    await changes.replace(
      request(
        eventId: 'same-a',
        mode: FutureMatterTimingMode.specifiedDate,
        itemId: 'item-a',
        specifiedDate: const FutureMatterDate(2026, 11, 1),
      ),
    );
    final entries = (await history.projectForItem(
      'item-a',
    )).futureMatterChangeEntries;
    expect(entries.where((entry) => entry.sourceId == 'same-a'), hasLength(1));
  });

  test(
    'missing Item rolls back without updating current or writing history',
    () async {
      final before = await changes.readCurrent('matter-1');
      await expectLater(
        changes.replace(
          request(
            eventId: 'missing-item',
            mode: FutureMatterTimingMode.later,
            itemId: 'missing',
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      final after = await changes.readCurrent('matter-1');
      expect(after!.updatedAt, before!.updatedAt);
      expect(await changes.listChanges('matter-1'), isEmpty);
    },
  );

  test('no-op leaves updatedAt and created history unchanged', () async {
    final createdEventBefore = await creation.findCreatedEvent('matter-1');
    final currentBefore = await changes.readCurrent('matter-1');
    final result = await changes.replace(
      request(eventId: 'noop', mode: FutureMatterTimingMode.later),
    );
    expect(result, isNull);
    expect(
      (await changes.readCurrent('matter-1'))!.updatedAt,
      currentBefore!.updatedAt,
    );
    expect(await changes.listChanges('matter-1'), isEmpty);
    final createdEventAfter = await creation.findCreatedEvent('matter-1');
    expect(createdEventAfter!.id, createdEventBefore!.id);
    expect(createdEventAfter.occurredAt, createdEventBefore.occurredAt);
  });

  test(
    'event failure rolls back main update and leaves exactly two snapshots per change',
    () async {
      await changes.replace(
        request(
          eventId: 'event-1',
          mode: FutureMatterTimingMode.later,
          itemId: 'item-a',
        ),
      );
      expect(
        await database.select(database.futureMatterChangeEvents).get(),
        hasLength(1),
      );
      expect(
        await database.select(database.futureMatterChangeEventSnapshots).get(),
        hasLength(2),
      );

      await expectLater(
        changes.replace(
          request(
            eventId: 'event-1',
            mode: FutureMatterTimingMode.later,
            itemId: 'item-b',
          ),
        ),
        throwsA(anything),
      );
      expect((await changes.readCurrent('matter-1'))!.itemId, 'item-a');
      expect(
        await database.select(database.futureMatterChangeEventSnapshots).get(),
        hasLength(2),
      );
    },
  );

  test(
    'change event and snapshots are immutable and create no Task or Schedule',
    () async {
      await changes.replace(
        request(
          eventId: 'immutable',
          mode: FutureMatterTimingMode.later,
          itemId: 'item-a',
        ),
      );
      await expectLater(
        (database.update(
          database.futureMatterChangeEvents,
        )..where((table) => table.id.equals('immutable'))).write(
          FutureMatterChangeEventsCompanion(createdAt: Value(createdAt)),
        ),
        throwsA(anything),
      );
      await expectLater(
        (database.delete(
          database.futureMatterChangeEventSnapshots,
        )..where((table) => table.eventId.equals('immutable'))).go(),
        throwsA(anything),
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.schedules).get(), isEmpty);
    },
  );
}
