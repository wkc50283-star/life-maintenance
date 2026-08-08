import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/future_matter.dart';
import '../future_matter_completion_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftFutureMatterCompletionRuntime
    implements FutureMatterCompletionRuntime {
  DriftFutureMatterCompletionRuntime(this._database);

  final AppDatabase _database;

  @override
  Future<FutureMatter?> readCurrent(String futureMatterId) async {
    final id = futureMatterId.trim();
    if (id.isEmpty) return null;
    final query = _database.select(_database.futureMatters)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _matter(row);
  }

  @override
  Future<FutureMatterCompletedEvent> complete(
    FutureMatterCompletionRequest request,
  ) {
    return _database.transaction(() async {
      final futureMatterId = request.futureMatterId.trim();
      final eventId = request.eventId.trim();
      if (futureMatterId.isEmpty || eventId.isEmpty) {
        throw const RepositoryConstraintException(
          'Future matter ID and completion event ID must not be empty.',
        );
      }
      if (!request.completedDate.isValid) {
        throw const RepositoryConstraintException(
          'Completion date must be a valid calendar date.',
        );
      }
      _validateMinute(request.completedMinuteOfDay);

      final snapshot = await readCurrent(futureMatterId);
      if (snapshot == null) {
        throw RepositoryConstraintException(
          'FutureMatter $futureMatterId does not exist.',
        );
      }
      if (snapshot.lifecycleStatus != FutureMatterLifecycleStatus.active) {
        throw RepositoryConstraintException(
          'FutureMatter $futureMatterId is not active.',
        );
      }

      await _database
          .into(_database.futureMatterCompletedEvents)
          .insert(
            FutureMatterCompletedEventsCompanion.insert(
              id: eventId,
              futureMatterId: futureMatterId,
              completedDate: request.completedDate.storageValue,
              completedMinuteOfDay: Value(request.completedMinuteOfDay),
              confirmedAt: request.confirmedAt,
              createdAt: request.confirmedAt,
              titleSnapshot: snapshot.title,
              itemIdSnapshot: Value(snapshot.itemId),
              timingModeSnapshot: snapshot.timingMode.name,
              specifiedDateSnapshot: Value(
                snapshot.specifiedDate?.storageValue,
              ),
              specifiedMinuteOfDaySnapshot: Value(
                snapshot.specifiedMinuteOfDay,
              ),
              recurringIntervalValueSnapshot: Value(
                snapshot.recurringIntervalValue,
              ),
              recurringIntervalUnitSnapshot: Value(
                snapshot.recurringIntervalUnit?.name,
              ),
              recurringAnchorDateSnapshot: Value(
                snapshot.recurringAnchorDate?.storageValue,
              ),
              recurringAnchorMinuteOfDaySnapshot: Value(
                snapshot.recurringAnchorMinuteOfDay,
              ),
              conditionTypeSnapshot: Value(snapshot.conditionType?.name),
              conditionMaintenanceRecordIdSnapshot: Value(
                snapshot.conditionMaintenanceRecordId,
              ),
              conditionDelayValueSnapshot: Value(snapshot.conditionDelayValue),
              conditionDelayUnitSnapshot: Value(
                snapshot.conditionDelayUnit?.name,
              ),
              futureMatterCreatedAtSnapshot: snapshot.createdAt,
              futureMatterUpdatedAtSnapshot: snapshot.updatedAt,
            ),
          );
      final changed =
          await (_database.update(
            _database.futureMatters,
          )..where((table) => table.id.equals(futureMatterId))).write(
            FutureMattersCompanion(
              lifecycleStatus: Value(
                FutureMatterLifecycleStatus.completed.name,
              ),
              updatedAt: Value(request.confirmedAt),
            ),
          );
      if (changed != 1) {
        throw StateError(
          'FutureMatter completion update did not affect one row.',
        );
      }
      return FutureMatterCompletedEvent(
        id: eventId,
        futureMatterId: futureMatterId,
        completedDate: request.completedDate,
        completedMinuteOfDay: request.completedMinuteOfDay,
        confirmedAt: request.confirmedAt,
        createdAt: request.confirmedAt,
        snapshot: snapshot,
      );
    });
  }

  @override
  Future<FutureMatterCompletedEvent?> findCompletedEvent(
    String futureMatterId,
  ) async {
    final query = _database.select(_database.futureMatterCompletedEvents)
      ..where((table) => table.futureMatterId.equals(futureMatterId.trim()));
    final row = await query.getSingleOrNull();
    return row == null ? null : _event(row);
  }

  void _validateMinute(int? value) {
    if (value != null && (value < 0 || value > 1439)) {
      throw const RepositoryConstraintException(
        'Time must be stored as a minute between 0 and 1439.',
      );
    }
  }
}

FutureMatter _matter(FutureMatterRow row) => FutureMatter(
  id: row.id,
  title: row.title,
  itemId: row.itemId,
  lifecycleStatus: FutureMatterLifecycleStatus.values.byName(
    row.lifecycleStatus,
  ),
  timingMode: FutureMatterTimingMode.values.byName(row.timingMode),
  specifiedDate: _date(row.specifiedDate),
  specifiedMinuteOfDay: row.specifiedMinuteOfDay,
  recurringIntervalValue: row.recurringIntervalValue,
  recurringIntervalUnit: _unit(row.recurringIntervalUnit),
  recurringAnchorDate: _date(row.recurringAnchorDate),
  recurringAnchorMinuteOfDay: row.recurringAnchorMinuteOfDay,
  conditionType: row.conditionType == null
      ? null
      : FutureMatterConditionType.values.byName(row.conditionType!),
  conditionMaintenanceRecordId: row.conditionMaintenanceRecordId,
  conditionDelayValue: row.conditionDelayValue,
  conditionDelayUnit: _unit(row.conditionDelayUnit),
  createdAt: row.createdAt,
  updatedAt: row.updatedAt,
);

FutureMatterCompletedEvent _event(
  FutureMatterCompletedEventRow row,
) => FutureMatterCompletedEvent(
  id: row.id,
  futureMatterId: row.futureMatterId,
  completedDate: FutureMatterDate.parse(row.completedDate),
  completedMinuteOfDay: row.completedMinuteOfDay,
  confirmedAt: row.confirmedAt,
  createdAt: row.createdAt,
  snapshot: FutureMatter(
    id: row.futureMatterId,
    title: row.titleSnapshot,
    itemId: row.itemIdSnapshot,
    timingMode: FutureMatterTimingMode.values.byName(row.timingModeSnapshot),
    specifiedDate: _date(row.specifiedDateSnapshot),
    specifiedMinuteOfDay: row.specifiedMinuteOfDaySnapshot,
    recurringIntervalValue: row.recurringIntervalValueSnapshot,
    recurringIntervalUnit: _unit(row.recurringIntervalUnitSnapshot),
    recurringAnchorDate: _date(row.recurringAnchorDateSnapshot),
    recurringAnchorMinuteOfDay: row.recurringAnchorMinuteOfDaySnapshot,
    conditionType: row.conditionTypeSnapshot == null
        ? null
        : FutureMatterConditionType.values.byName(row.conditionTypeSnapshot!),
    conditionMaintenanceRecordId: row.conditionMaintenanceRecordIdSnapshot,
    conditionDelayValue: row.conditionDelayValueSnapshot,
    conditionDelayUnit: _unit(row.conditionDelayUnitSnapshot),
    createdAt: row.futureMatterCreatedAtSnapshot,
    updatedAt: row.futureMatterUpdatedAtSnapshot,
  ),
);

FutureMatterDate? _date(String? value) =>
    value == null ? null : FutureMatterDate.parse(value);

FutureMatterIntervalUnit? _unit(String? value) =>
    value == null ? null : FutureMatterIntervalUnit.values.byName(value);
