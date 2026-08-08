import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/future_matter.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftFutureMatterCreationRuntime runtime;
  late DriftHistoryProjectionRepository history;
  final createdAt = DateTime.utc(2026, 8, 8, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    runtime = DriftFutureMatterCreationRuntime(database);
    final repositories = DriftSchemaV2Repositories(database);
    history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-1',
            name: '客廳冷氣',
            categoryId: ItemSystemCategory.unclassifiedId,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: 'active',
          ),
        );
    await database
        .into(database.maintenanceRecords)
        .insert(
          MaintenanceRecordsCompanion.insert(
            id: 'record-1',
            itemId: 'item-1',
            recordType: 'other',
            date: DateTime.utc(2026, 8, 7),
            title: '冷氣已完成清潔',
            createdAt: createdAt,
          ),
        );
  });

  tearDown(() => database.close());

  FutureMatterCreationRequest request({
    required String id,
    required FutureMatterTimingMode mode,
    String? itemId,
    FutureMatterDate? specifiedDate,
    int? specifiedMinuteOfDay,
    int? recurringValue,
    FutureMatterIntervalUnit? recurringUnit,
    FutureMatterDate? anchorDate,
    int? anchorMinute,
    FutureMatterConditionType? conditionType,
    String? conditionMaintenanceRecordId,
    int? conditionValue,
    FutureMatterIntervalUnit? conditionUnit,
    String? eventId,
  }) => FutureMatterCreationRequest(
    id: id,
    eventId: eventId ?? 'created-$id',
    title: '  測試事項 $id  ',
    itemId: itemId,
    timingMode: mode,
    specifiedDate: specifiedDate,
    specifiedMinuteOfDay: specifiedMinuteOfDay,
    recurringIntervalValue: recurringValue,
    recurringIntervalUnit: recurringUnit,
    recurringAnchorDate: anchorDate,
    recurringAnchorMinuteOfDay: anchorMinute,
    conditionType: conditionType,
    conditionMaintenanceRecordId: conditionMaintenanceRecordId,
    conditionDelayValue: conditionValue,
    conditionDelayUnit: conditionUnit,
    createdAt: createdAt,
  );

  test('FutureMatterDate accepts canonical valid calendar dates', () {
    expect(
      FutureMatterDate.parse('2026-02-28'),
      const FutureMatterDate(2026, 2, 28),
    );
    expect(
      FutureMatterDate.parse('2028-02-29'),
      const FutureMatterDate(2028, 2, 29),
    );
  });

  test('FutureMatterDate rejects invalid and malformed calendar dates', () {
    for (final value in const [
      '2026-02-29',
      '2026-04-31',
      '2026/02/28',
      '2026-2-28',
      'not-a-date',
    ]) {
      expect(() => FutureMatterDate.parse(value), throwsFormatException);
    }
  });

  test('creates later matter without Item or guessed time data', () async {
    final result = await runtime.create(
      request(id: 'later', mode: FutureMatterTimingMode.later),
    );

    expect(result.futureMatter.title, '測試事項 later');
    expect(result.futureMatter.itemId, isNull);
    expect(result.futureMatter.specifiedDate, isNull);
    expect(result.futureMatter.recurringAnchorDate, isNull);
    expect(result.createdEvent.itemIdSnapshot, isNull);
    expect(await database.select(database.tasks).get(), isEmpty);
    expect(await database.select(database.schedules).get(), isEmpty);
  });

  test('specified date keeps date precision when time is omitted', () async {
    const date = FutureMatterDate(2026, 9, 12);
    final result = await runtime.create(
      request(
        id: 'specified',
        mode: FutureMatterTimingMode.specifiedDate,
        itemId: 'item-1',
        specifiedDate: date,
      ),
    );

    expect(result.futureMatter.specifiedDate, date);
    expect(result.futureMatter.specifiedMinuteOfDay, isNull);
    expect(result.createdEvent.specifiedDateSnapshot, date);
    expect(result.createdEvent.specifiedMinuteOfDaySnapshot, isNull);
  });

  test('recurring preserves N and no, date, or date-time anchors', () async {
    const anchor = FutureMatterDate(2026, 10, 1);
    final inputs = <(String, FutureMatterDate?, int?)>[
      ('none', null, null),
      ('date', anchor, null),
      ('date-time', anchor, 9 * 60 + 30),
    ];
    for (final (id, anchorDate, anchorMinute) in inputs) {
      final result = await runtime.create(
        request(
          id: 'recurring-$id',
          mode: FutureMatterTimingMode.recurring,
          recurringValue: 3,
          recurringUnit: FutureMatterIntervalUnit.month,
          anchorDate: anchorDate,
          anchorMinute: anchorMinute,
        ),
      );
      expect(result.futureMatter.recurringIntervalValue, 3);
      expect(
        result.futureMatter.recurringIntervalUnit,
        FutureMatterIntervalUnit.month,
      );
      expect(result.futureMatter.recurringAnchorDate, anchorDate);
      expect(result.futureMatter.recurringAnchorMinuteOfDay, anchorMinute);
      expect(result.createdEvent.recurringAnchorDateSnapshot, anchorDate);
      expect(
        result.createdEvent.recurringAnchorMinuteOfDaySnapshot,
        anchorMinute,
      );
    }
  });

  test('condition preserves every approved original delay unit', () async {
    for (final unit in FutureMatterIntervalUnit.values.where(
      (unit) => unit != FutureMatterIntervalUnit.year,
    )) {
      final result = await runtime.create(
        request(
          id: 'condition-${unit.name}',
          mode: FutureMatterTimingMode.condition,
          conditionType: FutureMatterConditionType.afterFormalCompletion,
          conditionMaintenanceRecordId: 'record-1',
          conditionValue: 5,
          conditionUnit: unit,
        ),
      );
      expect(result.futureMatter.conditionDelayValue, 5);
      expect(result.futureMatter.conditionDelayUnit, unit);
      expect(
        result.createdEvent.conditionTypeSnapshot,
        FutureMatterConditionType.afterFormalCompletion,
      );
      expect(result.futureMatter.conditionMaintenanceRecordId, 'record-1');
      expect(
        result.createdEvent.conditionMaintenanceRecordIdSnapshot,
        'record-1',
      );
      expect(result.createdEvent.conditionDelayUnitSnapshot, unit);
    }
  });

  test('condition rejects year and rolls back all writes', () async {
    await expectLater(
      runtime.create(
        request(
          id: 'condition-year',
          mode: FutureMatterTimingMode.condition,
          conditionType: FutureMatterConditionType.afterFormalCompletion,
          conditionMaintenanceRecordId: 'record-1',
          conditionValue: 1,
          conditionUnit: FutureMatterIntervalUnit.year,
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await database.select(database.futureMatters).get(), isEmpty);
    expect(
      await database.select(database.futureMatterCreatedEvents).get(),
      isEmpty,
    );
  });

  test('recurring continues to support year', () async {
    final result = await runtime.create(
      request(
        id: 'recurring-year',
        mode: FutureMatterTimingMode.recurring,
        recurringValue: 2,
        recurringUnit: FutureMatterIntervalUnit.year,
      ),
    );

    expect(result.futureMatter.recurringIntervalValue, 2);
    expect(
      result.futureMatter.recurringIntervalUnit,
      FutureMatterIntervalUnit.year,
    );
    expect(
      result.createdEvent.recurringIntervalUnitSnapshot,
      FutureMatterIntervalUnit.year,
    );
  });

  test('database rejects condition year in main and snapshot rows', () async {
    await expectLater(
      database
          .into(database.futureMatters)
          .insert(
            FutureMattersCompanion.insert(
              id: 'direct-condition-year',
              title: '不應寫入的年度條件',
              timingMode: FutureMatterTimingMode.condition.name,
              conditionType: Value(
                FutureMatterConditionType.afterFormalCompletion.name,
              ),
              conditionMaintenanceRecordId: const Value('record-1'),
              conditionDelayValue: const Value(1),
              conditionDelayUnit: Value(FutureMatterIntervalUnit.year.name),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          ),
      throwsA(anything),
    );

    await database
        .into(database.futureMatters)
        .insert(
          FutureMattersCompanion.insert(
            id: 'snapshot-condition-parent',
            title: '事件父資料',
            timingMode: FutureMatterTimingMode.condition.name,
            conditionType: Value(
              FutureMatterConditionType.afterFormalCompletion.name,
            ),
            conditionMaintenanceRecordId: const Value('record-1'),
            conditionDelayValue: const Value(1),
            conditionDelayUnit: Value(FutureMatterIntervalUnit.day.name),
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await expectLater(
      database
          .into(database.futureMatterCreatedEvents)
          .insert(
            FutureMatterCreatedEventsCompanion.insert(
              id: 'direct-condition-year-event',
              futureMatterId: 'snapshot-condition-parent',
              titleSnapshot: '不應寫入的年度條件事件',
              timingModeSnapshot: FutureMatterTimingMode.condition.name,
              conditionTypeSnapshot: Value(
                FutureMatterConditionType.afterFormalCompletion.name,
              ),
              conditionMaintenanceRecordIdSnapshot: const Value('record-1'),
              conditionDelayValueSnapshot: const Value(1),
              conditionDelayUnitSnapshot: Value(
                FutureMatterIntervalUnit.year.name,
              ),
              occurredAt: createdAt,
              createdAt: createdAt,
            ),
          ),
      throwsA(anything),
    );
  });

  test('condition rejects missing or nonexistent MaintenanceRecord', () async {
    await expectLater(
      runtime.create(
        request(
          id: 'missing-condition-source',
          mode: FutureMatterTimingMode.condition,
          conditionType: FutureMatterConditionType.afterFormalCompletion,
          conditionValue: 1,
          conditionUnit: FutureMatterIntervalUnit.day,
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      runtime.create(
        request(
          id: 'unknown-condition-source',
          mode: FutureMatterTimingMode.condition,
          conditionType: FutureMatterConditionType.afterFormalCompletion,
          conditionMaintenanceRecordId: 'missing-record',
          conditionValue: 1,
          conditionUnit: FutureMatterIntervalUnit.day,
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await database.select(database.futureMatters).get(), isEmpty);
    expect(
      await database.select(database.futureMatterCreatedEvents).get(),
      isEmpty,
    );
  });

  test('non-condition timing rejects a MaintenanceRecord source', () async {
    await expectLater(
      runtime.create(
        request(
          id: 'later-with-source',
          mode: FutureMatterTimingMode.later,
          conditionMaintenanceRecordId: 'record-1',
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test('source ID survives MaintenanceRecord deletion as history', () async {
    final result = await runtime.create(
      request(
        id: 'source-lifecycle',
        mode: FutureMatterTimingMode.condition,
        conditionType: FutureMatterConditionType.afterFormalCompletion,
        conditionMaintenanceRecordId: 'record-1',
        conditionValue: 2,
        conditionUnit: FutureMatterIntervalUnit.day,
      ),
    );
    await expectLater(
      (database.update(
        database.futureMatterCreatedEvents,
      )..where((table) => table.id.equals(result.createdEvent.id))).write(
        const FutureMatterCreatedEventsCompanion(
          conditionMaintenanceRecordIdSnapshot: Value('rewritten'),
        ),
      ),
      throwsA(anything),
    );

    await (database.delete(
      database.maintenanceRecords,
    )..where((table) => table.id.equals('record-1'))).go();

    expect(await database.select(database.maintenanceRecords).get(), isEmpty);
    expect(
      (await runtime.findById(
        result.futureMatter.id,
      ))!.conditionMaintenanceRecordId,
      'record-1',
    );
    expect(
      (await runtime.findCreatedEvent(
        result.futureMatter.id,
      ))!.conditionMaintenanceRecordIdSnapshot,
      'record-1',
    );
  });

  test('date-only storage round trips without timezone drift', () async {
    final sourceValues = [
      '2026-09-12T00:00:00Z',
      '2026-09-12T00:00:00+08:00',
      '2026-09-12T00:00:00-04:00',
    ];
    for (var index = 0; index < sourceValues.length; index++) {
      final date = FutureMatterDate.parse(sourceValues[index].substring(0, 10));
      final result = await runtime.create(
        request(
          id: 'timezone-$index',
          mode: FutureMatterTimingMode.specifiedDate,
          specifiedDate: date,
          specifiedMinuteOfDay: index == 0 ? null : 0,
        ),
      );
      expect(result.futureMatter.specifiedDate?.storageValue, '2026-09-12');
      expect(
        result.createdEvent.specifiedDateSnapshot?.storageValue,
        '2026-09-12',
      );
      expect(result.futureMatter.specifiedMinuteOfDay, index == 0 ? null : 0);
    }
    final rows = await database
        .customSelect(
          'SELECT specified_date FROM future_matters '
          "WHERE id LIKE 'timezone-%' ORDER BY id",
        )
        .get();
    expect(
      rows.map((row) => row.read<String>('specified_date')),
      everyElement('2026-09-12'),
    );
  });

  test('database rejects non-date text in main and snapshot dates', () async {
    await expectLater(
      database
          .into(database.futureMatters)
          .insert(
            FutureMattersCompanion.insert(
              id: 'direct-main',
              title: '直接寫入',
              timingMode: FutureMatterTimingMode.specifiedDate.name,
              specifiedDate: const Value('2026-09-12T01:00:00Z'),
              createdAt: createdAt,
              updatedAt: createdAt,
            ),
          ),
      throwsA(anything),
    );
    await database
        .into(database.futureMatters)
        .insert(
          FutureMattersCompanion.insert(
            id: 'direct-event-parent',
            title: '事件父資料',
            timingMode: FutureMatterTimingMode.later.name,
            createdAt: createdAt,
            updatedAt: createdAt,
          ),
        );
    await expectLater(
      database
          .into(database.futureMatterCreatedEvents)
          .insert(
            FutureMatterCreatedEventsCompanion.insert(
              id: 'direct-event',
              futureMatterId: 'direct-event-parent',
              titleSnapshot: '直接事件',
              timingModeSnapshot: FutureMatterTimingMode.specifiedDate.name,
              specifiedDateSnapshot: const Value('2026-09-12T00:00:00.001Z'),
              occurredAt: createdAt,
              createdAt: createdAt,
            ),
          ),
      throwsA(anything),
    );
  });

  test(
    'invalid Item and timing fields reject without partial writes',
    () async {
      await expectLater(
        runtime.create(
          request(
            id: 'missing-item',
            mode: FutureMatterTimingMode.later,
            itemId: 'missing',
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      await expectLater(
        runtime.create(
          request(id: 'bad-date', mode: FutureMatterTimingMode.specifiedDate),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(await database.select(database.futureMatters).get(), isEmpty);
      expect(
        await database.select(database.futureMatterCreatedEvents).get(),
        isEmpty,
      );
    },
  );

  test('created event failure rolls back the matter', () async {
    await runtime.create(
      request(id: 'first', mode: FutureMatterTimingMode.later),
    );
    await expectLater(
      runtime.create(
        request(
          id: 'second',
          eventId: 'created-first',
          mode: FutureMatterTimingMode.later,
        ),
      ),
      throwsA(anything),
    );
    expect(await runtime.findById('second'), isNull);
    expect(await database.select(database.futureMatters).get(), hasLength(1));
  });

  test('created event is immutable and unique per matter', () async {
    await runtime.create(
      request(id: 'immutable', mode: FutureMatterTimingMode.later),
    );
    await expectLater(
      (database.update(
        database.futureMatterCreatedEvents,
      )..where((table) => table.id.equals('created-immutable'))).write(
        const FutureMatterCreatedEventsCompanion(titleSnapshot: Value('改寫')),
      ),
      throwsA(anything),
    );
    await expectLater(
      (database.delete(
        database.futureMatterCreatedEvents,
      )..where((table) => table.id.equals('created-immutable'))).go(),
      throwsA(anything),
    );
    expect(
      (await runtime.findCreatedEvent('immutable'))!.titleSnapshot,
      '測試事項 immutable',
    );
  });

  test(
    'History projects linked entries per Item and all entries globally',
    () async {
      await runtime.create(
        request(id: 'global', mode: FutureMatterTimingMode.later),
      );
      await runtime.create(
        request(
          id: 'linked',
          mode: FutureMatterTimingMode.specifiedDate,
          itemId: 'item-1',
          specifiedDate: const FutureMatterDate(2026, 9, 12),
        ),
      );

      final itemProjection = await history.projectForItem('item-1');
      expect(itemProjection.futureMatterCreatedEntries, hasLength(1));
      expect(
        itemProjection.futureMatterCreatedEntries.single.event.futureMatterId,
        'linked',
      );
      final global = await history.projectGlobalFutureMatterCreatedEntries();
      expect(global.map((entry) => entry.event.futureMatterId), {
        'global',
        'linked',
      });
    },
  );
}
