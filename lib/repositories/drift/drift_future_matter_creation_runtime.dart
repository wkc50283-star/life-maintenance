import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/future_matter.dart';
import '../future_matter_creation_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftFutureMatterCreationRuntime implements FutureMatterCreationRuntime {
  DriftFutureMatterCreationRuntime(this._database);

  final AppDatabase _database;

  @override
  Future<FutureMatterCreationResult> create(
    FutureMatterCreationRequest request,
  ) {
    return _database.transaction(() async {
      final id = request.id.trim();
      final eventId = request.eventId.trim();
      final title = request.title.trim();
      final itemId = _textOrNull(request.itemId);
      final conditionMaintenanceRecordId = _textOrNull(
        request.conditionMaintenanceRecordId,
      );
      if (id.isEmpty || eventId.isEmpty || title.isEmpty) {
        throw const RepositoryConstraintException(
          'Future matter ID, event ID, and title must not be empty.',
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

      await _database
          .into(_database.futureMatters)
          .insert(
            FutureMattersCompanion.insert(
              id: id,
              title: title,
              itemId: Value(itemId),
              timingMode: request.timingMode.name,
              specifiedDate: Value(request.specifiedDate?.storageValue),
              specifiedMinuteOfDay: Value(request.specifiedMinuteOfDay),
              recurringIntervalValue: Value(request.recurringIntervalValue),
              recurringIntervalUnit: Value(request.recurringIntervalUnit?.name),
              recurringAnchorDate: Value(
                request.recurringAnchorDate?.storageValue,
              ),
              recurringAnchorMinuteOfDay: Value(
                request.recurringAnchorMinuteOfDay,
              ),
              conditionType: Value(request.conditionType?.name),
              conditionMaintenanceRecordId: Value(conditionMaintenanceRecordId),
              conditionDelayValue: Value(request.conditionDelayValue),
              conditionDelayUnit: Value(request.conditionDelayUnit?.name),
              createdAt: request.createdAt,
              updatedAt: request.createdAt,
            ),
          );
      await _database
          .into(_database.futureMatterCreatedEvents)
          .insert(
            FutureMatterCreatedEventsCompanion.insert(
              id: eventId,
              futureMatterId: id,
              titleSnapshot: title,
              itemIdSnapshot: Value(itemId),
              timingModeSnapshot: request.timingMode.name,
              specifiedDateSnapshot: Value(request.specifiedDate?.storageValue),
              specifiedMinuteOfDaySnapshot: Value(request.specifiedMinuteOfDay),
              recurringIntervalValueSnapshot: Value(
                request.recurringIntervalValue,
              ),
              recurringIntervalUnitSnapshot: Value(
                request.recurringIntervalUnit?.name,
              ),
              recurringAnchorDateSnapshot: Value(
                request.recurringAnchorDate?.storageValue,
              ),
              recurringAnchorMinuteOfDaySnapshot: Value(
                request.recurringAnchorMinuteOfDay,
              ),
              conditionTypeSnapshot: Value(request.conditionType?.name),
              conditionMaintenanceRecordIdSnapshot: Value(
                conditionMaintenanceRecordId,
              ),
              conditionDelayValueSnapshot: Value(request.conditionDelayValue),
              conditionDelayUnitSnapshot: Value(
                request.conditionDelayUnit?.name,
              ),
              occurredAt: request.createdAt,
              createdAt: request.createdAt,
            ),
          );

      final matter = await findById(id);
      final event = await findCreatedEvent(id);
      if (matter == null || event == null) {
        throw StateError('Created future matter could not be read back.');
      }
      return FutureMatterCreationResult(
        futureMatter: matter,
        createdEvent: event,
      );
    });
  }

  @override
  Future<FutureMatter?> findById(String id) async {
    final query = _database.select(_database.futureMatters)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _matter(row);
  }

  @override
  Future<FutureMatterCreatedEvent?> findCreatedEvent(
    String futureMatterId,
  ) async {
    final query = _database.select(_database.futureMatterCreatedEvents)
      ..where((table) => table.futureMatterId.equals(futureMatterId));
    final row = await query.getSingleOrNull();
    return row == null ? null : _event(row);
  }

  void _validateTiming(
    FutureMatterCreationRequest request,
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

  Never _invalidTiming() => throw const RepositoryConstraintException(
    'Future matter timing fields do not match the selected timing mode.',
  );

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

FutureMatterCreatedEvent _event(FutureMatterCreatedEventRow row) =>
    FutureMatterCreatedEvent(
      id: row.id,
      futureMatterId: row.futureMatterId,
      titleSnapshot: row.titleSnapshot,
      itemIdSnapshot: row.itemIdSnapshot,
      timingModeSnapshot: FutureMatterTimingMode.values.byName(
        row.timingModeSnapshot,
      ),
      specifiedDateSnapshot: _date(row.specifiedDateSnapshot),
      specifiedMinuteOfDaySnapshot: row.specifiedMinuteOfDaySnapshot,
      recurringIntervalValueSnapshot: row.recurringIntervalValueSnapshot,
      recurringIntervalUnitSnapshot: _unit(row.recurringIntervalUnitSnapshot),
      recurringAnchorDateSnapshot: _date(row.recurringAnchorDateSnapshot),
      recurringAnchorMinuteOfDaySnapshot:
          row.recurringAnchorMinuteOfDaySnapshot,
      conditionTypeSnapshot: row.conditionTypeSnapshot == null
          ? null
          : FutureMatterConditionType.values.byName(row.conditionTypeSnapshot!),
      conditionMaintenanceRecordIdSnapshot:
          row.conditionMaintenanceRecordIdSnapshot,
      conditionDelayValueSnapshot: row.conditionDelayValueSnapshot,
      conditionDelayUnitSnapshot: _unit(row.conditionDelayUnitSnapshot),
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
    );

FutureMatterIntervalUnit? _unit(String? value) =>
    value == null ? null : FutureMatterIntervalUnit.values.byName(value);

FutureMatterDate? _date(String? value) =>
    value == null ? null : FutureMatterDate.parse(value);

String? _textOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
