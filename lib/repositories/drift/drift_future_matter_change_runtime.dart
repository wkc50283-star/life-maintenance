import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/future_matter.dart';
import '../future_matter_change_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftFutureMatterChangeRuntime implements FutureMatterChangeRuntime {
  DriftFutureMatterChangeRuntime(this._database);

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
  Future<FutureMatterChangeEvent?> replace(FutureMatterChangeRequest request) {
    return _database.transaction(() async {
      final futureMatterId = request.futureMatterId.trim();
      final eventId = request.eventId.trim();
      final itemId = _textOrNull(request.itemId);
      final conditionMaintenanceRecordId = _textOrNull(
        request.conditionMaintenanceRecordId,
      );
      if (futureMatterId.isEmpty || eventId.isEmpty) {
        throw const RepositoryConstraintException(
          'Future matter ID and event ID must not be empty.',
        );
      }

      final before = await readCurrent(futureMatterId);
      if (before == null) {
        throw RepositoryConstraintException(
          'FutureMatter $futureMatterId does not exist.',
        );
      }
      if (before.lifecycleStatus != FutureMatterLifecycleStatus.active) {
        throw RepositoryConstraintException(
          'FutureMatter $futureMatterId is completed and cannot be changed.',
        );
      }
      if (itemId != null) {
        final itemQuery = _database.select(_database.items)
          ..where((table) => table.id.equals(itemId));
        if (await itemQuery.getSingleOrNull() == null) {
          throw RepositoryConstraintException('Item $itemId does not exist.');
        }
      }
      _validateTiming(request, conditionMaintenanceRecordId);
      if (conditionMaintenanceRecordId != null) {
        final recordQuery = _database.select(_database.maintenanceRecords)
          ..where((table) => table.id.equals(conditionMaintenanceRecordId));
        if (await recordQuery.getSingleOrNull() == null) {
          throw RepositoryConstraintException(
            'MaintenanceRecord $conditionMaintenanceRecordId does not exist.',
          );
        }
      }

      final after = FutureMatter(
        id: before.id,
        title: before.title,
        itemId: itemId,
        timingMode: request.timingMode,
        specifiedDate: request.specifiedDate,
        specifiedMinuteOfDay: request.specifiedMinuteOfDay,
        recurringIntervalValue: request.recurringIntervalValue,
        recurringIntervalUnit: request.recurringIntervalUnit,
        recurringAnchorDate: request.recurringAnchorDate,
        recurringAnchorMinuteOfDay: request.recurringAnchorMinuteOfDay,
        conditionType: request.conditionType,
        conditionMaintenanceRecordId: conditionMaintenanceRecordId,
        conditionDelayValue: request.conditionDelayValue,
        conditionDelayUnit: request.conditionDelayUnit,
        createdAt: before.createdAt,
        updatedAt: request.occurredAt,
        lifecycleStatus: before.lifecycleStatus,
      );
      if (_sameFormalValues(before, after)) return null;

      await (_database.update(
        _database.futureMatters,
      )..where((table) => table.id.equals(futureMatterId))).write(
        FutureMattersCompanion(
          itemId: Value(itemId),
          timingMode: Value(after.timingMode.name),
          specifiedDate: Value(after.specifiedDate?.storageValue),
          specifiedMinuteOfDay: Value(after.specifiedMinuteOfDay),
          recurringIntervalValue: Value(after.recurringIntervalValue),
          recurringIntervalUnit: Value(after.recurringIntervalUnit?.name),
          recurringAnchorDate: Value(after.recurringAnchorDate?.storageValue),
          recurringAnchorMinuteOfDay: Value(after.recurringAnchorMinuteOfDay),
          conditionType: Value(after.conditionType?.name),
          conditionMaintenanceRecordId: Value(
            after.conditionMaintenanceRecordId,
          ),
          conditionDelayValue: Value(after.conditionDelayValue),
          conditionDelayUnit: Value(after.conditionDelayUnit?.name),
          updatedAt: Value(after.updatedAt),
        ),
      );
      await _database
          .into(_database.futureMatterChangeEvents)
          .insert(
            FutureMatterChangeEventsCompanion.insert(
              id: eventId,
              futureMatterId: futureMatterId,
              occurredAt: request.occurredAt,
              createdAt: request.occurredAt,
            ),
          );
      await _writeSnapshot(eventId, 'before', before);
      await _writeSnapshot(eventId, 'after', after);

      return FutureMatterChangeEvent(
        id: eventId,
        futureMatterId: futureMatterId,
        occurredAt: request.occurredAt,
        createdAt: request.occurredAt,
        before: before,
        after: after,
      );
    });
  }

  @override
  Future<List<FutureMatterChangeEvent>> listChanges(
    String futureMatterId,
  ) async {
    final query = _database.select(_database.futureMatterChangeEvents)
      ..where((table) => table.futureMatterId.equals(futureMatterId.trim()))
      ..orderBy([
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.id),
      ]);
    final events = <FutureMatterChangeEvent>[];
    for (final row in await query.get()) {
      events.add(
        FutureMatterChangeEvent(
          id: row.id,
          futureMatterId: row.futureMatterId,
          occurredAt: row.occurredAt,
          createdAt: row.createdAt,
          before: await _readSnapshot(row.id, row.futureMatterId, 'before'),
          after: await _readSnapshot(row.id, row.futureMatterId, 'after'),
        ),
      );
    }
    return List.unmodifiable(events);
  }

  Future<void> _writeSnapshot(
    String eventId,
    String side,
    FutureMatter value,
  ) => _database
      .into(_database.futureMatterChangeEventSnapshots)
      .insert(
        FutureMatterChangeEventSnapshotsCompanion.insert(
          eventId: eventId,
          snapshotSide: side,
          title: value.title,
          itemId: Value(value.itemId),
          timingMode: value.timingMode.name,
          specifiedDate: Value(value.specifiedDate?.storageValue),
          specifiedMinuteOfDay: Value(value.specifiedMinuteOfDay),
          recurringIntervalValue: Value(value.recurringIntervalValue),
          recurringIntervalUnit: Value(value.recurringIntervalUnit?.name),
          recurringAnchorDate: Value(value.recurringAnchorDate?.storageValue),
          recurringAnchorMinuteOfDay: Value(value.recurringAnchorMinuteOfDay),
          conditionType: Value(value.conditionType?.name),
          conditionMaintenanceRecordId: Value(
            value.conditionMaintenanceRecordId,
          ),
          conditionDelayValue: Value(value.conditionDelayValue),
          conditionDelayUnit: Value(value.conditionDelayUnit?.name),
          futureMatterCreatedAt: value.createdAt,
          futureMatterUpdatedAt: value.updatedAt,
        ),
      );

  Future<FutureMatter> _readSnapshot(
    String eventId,
    String futureMatterId,
    String side,
  ) async {
    final query = _database.select(_database.futureMatterChangeEventSnapshots)
      ..where(
        (table) =>
            table.eventId.equals(eventId) & table.snapshotSide.equals(side),
      );
    return _snapshot(await query.getSingle(), futureMatterId);
  }

  void _validateTiming(
    FutureMatterChangeRequest request,
    String? conditionMaintenanceRecordId,
  ) {
    _validateDate(request.specifiedDate);
    _validateDate(request.recurringAnchorDate);
    _validateMinute(request.specifiedMinuteOfDay);
    _validateMinute(request.recurringAnchorMinuteOfDay);
    if (request.recurringAnchorMinuteOfDay != null &&
        request.recurringAnchorDate == null) {
      throw const RepositoryConstraintException(
        'A recurring anchor time requires an anchor date.',
      );
    }
    final hasSpecified =
        request.specifiedDate != null || request.specifiedMinuteOfDay != null;
    final hasRecurring =
        request.recurringIntervalValue != null ||
        request.recurringIntervalUnit != null ||
        request.recurringAnchorDate != null ||
        request.recurringAnchorMinuteOfDay != null;
    final hasCondition =
        request.conditionType != null ||
        conditionMaintenanceRecordId != null ||
        request.conditionDelayValue != null ||
        request.conditionDelayUnit != null;
    switch (request.timingMode) {
      case FutureMatterTimingMode.later:
        if (hasSpecified || hasRecurring || hasCondition) _invalidTiming();
      case FutureMatterTimingMode.specifiedDate:
        if (request.specifiedDate == null || hasRecurring || hasCondition) {
          _invalidTiming();
        }
      case FutureMatterTimingMode.recurring:
        if (hasSpecified ||
            hasCondition ||
            request.recurringIntervalValue == null ||
            request.recurringIntervalValue! <= 0 ||
            request.recurringIntervalUnit == null) {
          _invalidTiming();
        }
      case FutureMatterTimingMode.condition:
        if (hasSpecified ||
            hasRecurring ||
            request.conditionType !=
                FutureMatterConditionType.afterFormalCompletion ||
            conditionMaintenanceRecordId == null ||
            request.conditionDelayValue == null ||
            request.conditionDelayValue! <= 0 ||
            request.conditionDelayUnit == null ||
            request.conditionDelayUnit == FutureMatterIntervalUnit.year) {
          _invalidTiming();
        }
    }
  }

  void _validateDate(FutureMatterDate? value) {
    if (value != null && !value.isValid) {
      throw const RepositoryConstraintException(
        'Date fields must contain a valid calendar date.',
      );
    }
  }

  void _validateMinute(int? value) {
    if (value != null && (value < 0 || value > 1439)) {
      throw const RepositoryConstraintException(
        'Time must be stored as a minute between 0 and 1439.',
      );
    }
  }

  Never _invalidTiming() => throw const RepositoryConstraintException(
    'Future matter timing fields do not match the selected timing mode.',
  );
}

FutureMatter _matter(FutureMatterRow row) => FutureMatter(
  id: row.id,
  title: row.title,
  itemId: row.itemId,
  lifecycleStatus: FutureMatterLifecycleStatus.values.byName(
    row.lifecycleStatus,
  ),
  createdSource: row.createdSource == null
      ? null
      : FutureMatterSource.values.byName(row.createdSource!),
  createdSourceReferenceKind: row.createdSourceReferenceKind == null
      ? null
      : FutureMatterSourceReferenceKind.values.byName(
          row.createdSourceReferenceKind!,
        ),
  createdSourceReferenceId: row.createdSourceReferenceId,
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

FutureMatter _snapshot(
  FutureMatterChangeEventSnapshotRow row,
  String futureMatterId,
) => FutureMatter(
  id: futureMatterId,
  title: row.title,
  itemId: row.itemId,
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
  createdAt: row.futureMatterCreatedAt,
  updatedAt: row.futureMatterUpdatedAt,
);

bool _sameFormalValues(FutureMatter left, FutureMatter right) =>
    left.title == right.title &&
    left.itemId == right.itemId &&
    left.timingMode == right.timingMode &&
    left.specifiedDate == right.specifiedDate &&
    left.specifiedMinuteOfDay == right.specifiedMinuteOfDay &&
    left.recurringIntervalValue == right.recurringIntervalValue &&
    left.recurringIntervalUnit == right.recurringIntervalUnit &&
    left.recurringAnchorDate == right.recurringAnchorDate &&
    left.recurringAnchorMinuteOfDay == right.recurringAnchorMinuteOfDay &&
    left.conditionType == right.conditionType &&
    left.conditionMaintenanceRecordId == right.conditionMaintenanceRecordId &&
    left.conditionDelayValue == right.conditionDelayValue &&
    left.conditionDelayUnit == right.conditionDelayUnit;

FutureMatterIntervalUnit? _unit(String? value) =>
    value == null ? null : FutureMatterIntervalUnit.values.byName(value);

FutureMatterDate? _date(String? value) =>
    value == null ? null : FutureMatterDate.parse(value);

String? _textOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
