import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/future_matter.dart';
import '../future_matter_amendment_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftFutureMatterAmendmentRuntime
    implements FutureMatterAmendmentRuntime {
  DriftFutureMatterAmendmentRuntime(this._database);

  final AppDatabase _database;

  @override
  Future<FutureMatterAmendmentEvent> createSupplement(
    FutureMatterAmendmentRequest request,
  ) => _create(request, FutureMatterAmendmentType.supplement);

  @override
  Future<FutureMatterAmendmentEvent> createCorrection(
    FutureMatterAmendmentRequest request,
  ) => _create(request, FutureMatterAmendmentType.correction);

  Future<FutureMatterAmendmentEvent> _create(
    FutureMatterAmendmentRequest request,
    FutureMatterAmendmentType type,
  ) => _database.transaction(() async {
    final id = request.id.trim();
    final matterId = request.futureMatterId.trim();
    final targetId = request.target.id.trim();
    final sourceId = _textOrNull(request.sourceReferenceId);
    if (id.isEmpty || matterId.isEmpty || targetId.isEmpty) {
      throw const RepositoryConstraintException(
        'Amendment, FutureMatter, and target IDs must not be empty.',
      );
    }
    if (id == targetId) {
      throw const RepositoryConstraintException(
        'An amendment cannot target itself.',
      );
    }
    if ((request.sourceReferenceKind == null) != (sourceId == null)) {
      throw const RepositoryConstraintException(
        'Source reference kind and ID must be provided together.',
      );
    }
    if (request.changes.isEmpty ||
        request.changes.map((change) => change.field).toSet().length !=
            request.changes.length) {
      throw const RepositoryConstraintException(
        'An amendment requires unique field changes.',
      );
    }
    await _requireMatter(matterId);
    final root = await _resolveRoot(request.target, matterId, <String>{});
    if (request.sourceReferenceKind != null) {
      await _requireSourceReference(request.sourceReferenceKind!, sourceId!);
    }
    final current = await _foldRoot(root, matterId);
    for (final change in request.changes) {
      await _validateChange(
        type,
        change,
        current.values[change.field] ?? const FutureMatterFieldValue.absent(),
      );
    }

    await _database
        .into(_database.futureMatterAmendmentEvents)
        .insert(
          FutureMatterAmendmentEventsCompanion.insert(
            id: id,
            futureMatterId: matterId,
            eventType: type.name,
            targetEventKind: request.target.kind.name,
            targetEventId: targetId,
            occurredAt: Value(request.occurredAt),
            recordedAt: request.recordedAt,
            eventSource: request.eventSource.name,
            sourceReferenceKind: Value(request.sourceReferenceKind?.name),
            sourceReferenceId: Value(sourceId),
          ),
        );
    for (final change in request.changes) {
      await _writeChange(id, type, change);
    }
    // Re-fold inside the same transaction so an event whose recorded order
    // would invalidate a later persisted correction is rejected atomically.
    await _foldRoot(root, matterId);
    return (await _readEvent(id))!;
  });

  @override
  Future<List<FutureMatterAmendmentEvent>> listAmendments(
    String futureMatterId,
  ) async {
    final query = _database.select(_database.futureMatterAmendmentEvents)
      ..where((table) => table.futureMatterId.equals(futureMatterId.trim()))
      ..orderBy([
        (table) => OrderingTerm.asc(table.recordedAt),
        (table) => OrderingTerm.asc(table.id),
      ]);
    return [for (final row in await query.get()) await _event(row)];
  }

  @override
  Future<FutureMatterEffectiveFacts> foldEffectiveResult(
    FutureMatterEventReference target,
  ) async {
    final matterId = await _matterIdFor(target);
    if (matterId == null) {
      throw const RepositoryConstraintException('Target event does not exist.');
    }
    final root = await _resolveRoot(target, matterId, <String>{});
    return _foldRoot(root, matterId);
  }

  Future<FutureMatterEffectiveFacts> _foldRoot(
    FutureMatterEventReference root,
    String matterId,
  ) async {
    final values = await _baseValues(root, matterId);
    final events = await listAmendments(matterId);
    for (final event in events) {
      final eventRoot = await _resolveRoot(event.target, matterId, <String>{});
      if (eventRoot.kind != root.kind || eventRoot.id != root.id) continue;
      for (final change in event.changes) {
        final current =
            values[change.field] ?? const FutureMatterFieldValue.absent();
        if (event.eventType == FutureMatterAmendmentType.supplement) {
          if (current.state != FutureMatterValueState.absent) {
            throw StateError(
              'Persisted supplement conflicts with its event chain.',
            );
          }
        } else if (current != change.oldValue) {
          throw StateError('Persisted correction has a stale old value.');
        }
        values[change.field] = change.newValue;
      }
    }
    return FutureMatterEffectiveFacts(values);
  }

  Future<Map<FutureMatterAmendmentField, FutureMatterFieldValue>> _baseValues(
    FutureMatterEventReference root,
    String matterId,
  ) async {
    final values = <FutureMatterAmendmentField, FutureMatterFieldValue>{};
    for (final field in FutureMatterAmendmentField.values) {
      values[field] = const FutureMatterFieldValue.absent();
    }
    if (root.kind == FutureMatterTargetEventKind.completed) {
      final row =
          await (_database.select(_database.futureMatterCompletedEvents)..where(
                (table) =>
                    table.id.equals(root.id) &
                    table.futureMatterId.equals(matterId),
              ))
              .getSingleOrNull();
      if (row == null) {
        throw const RepositoryConstraintException(
          'Target event does not exist.',
        );
      }
      values[FutureMatterAmendmentField.completedDate] =
          FutureMatterFieldValue.value(
            FutureMatterDate.parse(row.completedDate),
          );
      values[FutureMatterAmendmentField.completedMinuteOfDay] =
          row.completedMinuteOfDay == null
          ? const FutureMatterFieldValue.nullValue()
          : FutureMatterFieldValue.value(row.completedMinuteOfDay!);
    }
    return values;
  }

  Future<FutureMatterEventReference> _resolveRoot(
    FutureMatterEventReference target,
    String matterId,
    Set<String> visited,
  ) async {
    final key = '${target.kind.name}:${target.id}';
    if (!visited.add(key)) {
      throw const RepositoryConstraintException(
        'Amendment target cycle detected.',
      );
    }
    final targetMatter = await _matterIdFor(target);
    if (targetMatter == null || targetMatter != matterId) {
      throw const RepositoryConstraintException(
        'Target event does not belong to the FutureMatter.',
      );
    }
    if (target.kind != FutureMatterTargetEventKind.supplement &&
        target.kind != FutureMatterTargetEventKind.correction) {
      return target;
    }
    final row = await (_database.select(
      _database.futureMatterAmendmentEvents,
    )..where((table) => table.id.equals(target.id))).getSingle();
    if (row.eventType != target.kind.name) {
      throw const RepositoryConstraintException(
        'Target event kind does not match.',
      );
    }
    return _resolveRoot(
      FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.values.byName(row.targetEventKind),
        id: row.targetEventId,
      ),
      matterId,
      visited,
    );
  }

  Future<String?> _matterIdFor(FutureMatterEventReference target) async {
    switch (target.kind) {
      case FutureMatterTargetEventKind.created:
        return (await (_database.select(
              _database.futureMatterCreatedEvents,
            )..where((t) => t.id.equals(target.id))).getSingleOrNull())
            ?.futureMatterId;
      case FutureMatterTargetEventKind.change:
        return (await (_database.select(
              _database.futureMatterChangeEvents,
            )..where((t) => t.id.equals(target.id))).getSingleOrNull())
            ?.futureMatterId;
      case FutureMatterTargetEventKind.completed:
        return (await (_database.select(
              _database.futureMatterCompletedEvents,
            )..where((t) => t.id.equals(target.id))).getSingleOrNull())
            ?.futureMatterId;
      case FutureMatterTargetEventKind.supplement:
      case FutureMatterTargetEventKind.correction:
        final row = await (_database.select(
          _database.futureMatterAmendmentEvents,
        )..where((t) => t.id.equals(target.id))).getSingleOrNull();
        return row?.eventType == target.kind.name ? row?.futureMatterId : null;
    }
  }

  Future<void> _validateChange(
    FutureMatterAmendmentType type,
    FutureMatterFieldChange change,
    FutureMatterFieldValue current,
  ) async {
    _validateValue(change.field, change.oldValue);
    _validateValue(change.field, change.newValue);
    if (type == FutureMatterAmendmentType.supplement) {
      if (change.oldValue.state != FutureMatterValueState.absent ||
          change.newValue.state != FutureMatterValueState.value ||
          current.state != FutureMatterValueState.absent) {
        throw const RepositoryConstraintException(
          'A supplement only supports absent to value.',
        );
      }
    } else {
      if (change.oldValue.state != FutureMatterValueState.value ||
          change.newValue.state == FutureMatterValueState.absent ||
          current != change.oldValue ||
          change.oldValue == change.newValue) {
        throw const RepositoryConstraintException(
          'A correction requires the current old value and a different value or null.',
        );
      }
    }
    for (final value in [change.oldValue, change.newValue]) {
      if (value.state == FutureMatterValueState.value &&
          change.field == FutureMatterAmendmentField.attachments) {
        for (final id in (value.value as List<String>).toSet()) {
          if (await (_database.select(
                _database.attachments,
              )..where((t) => t.id.equals(id))).getSingleOrNull() ==
              null) {
            throw RepositoryConstraintException(
              'Attachment $id does not exist.',
            );
          }
        }
      }
    }
  }

  void _validateValue(
    FutureMatterAmendmentField field,
    FutureMatterFieldValue value,
  ) {
    if (value.state != FutureMatterValueState.value) {
      if (value.value != null) {
        throw const RepositoryConstraintException(
          'Absent or null values cannot carry data.',
        );
      }
      return;
    }
    final data = value.value;
    final valid = switch (field) {
      FutureMatterAmendmentField.completedDate =>
        data is FutureMatterDate && data.isValid,
      FutureMatterAmendmentField.completedMinuteOfDay =>
        data is int && data >= 0 && data <= 1439,
      FutureMatterAmendmentField.note => data is String,
      FutureMatterAmendmentField.attachments =>
        data is List<String> &&
            data.every((id) => id.trim().isNotEmpty) &&
            data.toSet().length == data.length,
      FutureMatterAmendmentField.cost =>
        data is FutureMatterMoney &&
            data.amountMinor >= 0 &&
            _iso4217.contains(data.currency),
      FutureMatterAmendmentField.relatedPeople =>
        data is List<FutureMatterRelatedPerson> &&
            data.every((person) => person.displayName.trim().isNotEmpty),
    };
    if (!valid) {
      throw RepositoryConstraintException('Invalid ${field.name} value.');
    }
  }

  Future<void> _writeChange(
    String eventId,
    FutureMatterAmendmentType type,
    FutureMatterFieldChange change,
  ) async {
    final oldValue = change.oldValue;
    final newValue = change.newValue;
    await _database
        .into(_database.futureMatterAmendmentFieldChanges)
        .insert(
          FutureMatterAmendmentFieldChangesCompanion.insert(
            eventId: eventId,
            fieldKey: change.field.name,
            valueType: _valueType(change.field),
            oldState: _stateName(oldValue.state),
            newState: _stateName(newValue.state),
            oldTextValue: Value(_textScalar(change.field, oldValue)),
            newTextValue: Value(_textScalar(change.field, newValue)),
            oldIntegerValue: Value(_integerScalar(change.field, oldValue)),
            newIntegerValue: Value(_integerScalar(change.field, newValue)),
          ),
        );
    await _writeComplex(eventId, change.field, 'old', oldValue);
    await _writeComplex(eventId, change.field, 'new', newValue);
  }

  Future<void> _writeComplex(
    String eventId,
    FutureMatterAmendmentField field,
    String side,
    FutureMatterFieldValue value,
  ) async {
    if (value.state != FutureMatterValueState.value) return;
    if (field == FutureMatterAmendmentField.attachments) {
      for (final id in value.value! as List<String>) {
        await _database
            .into(_database.futureMatterAmendmentAttachmentValues)
            .insert(
              FutureMatterAmendmentAttachmentValuesCompanion.insert(
                eventId: eventId,
                valueSide: side,
                attachmentId: id,
              ),
            );
      }
    } else if (field == FutureMatterAmendmentField.relatedPeople) {
      var index = 0;
      for (final person in value.value! as List<FutureMatterRelatedPerson>) {
        await _database
            .into(_database.futureMatterAmendmentRelatedPeople)
            .insert(
              FutureMatterAmendmentRelatedPeopleCompanion.insert(
                id: '${eventId}_${side}_${index++}',
                eventId: eventId,
                valueSide: side,
                displayName: person.displayName.trim(),
                relationNote: Value(_textOrNull(person.relationNote)),
              ),
            );
      }
    } else if (field == FutureMatterAmendmentField.cost) {
      final money = value.value! as FutureMatterMoney;
      await _database
          .into(_database.futureMatterAmendmentMoneyValues)
          .insert(
            FutureMatterAmendmentMoneyValuesCompanion.insert(
              eventId: eventId,
              valueSide: side,
              amountMinor: money.amountMinor,
              currency: money.currency,
            ),
          );
    }
  }

  Future<FutureMatterAmendmentEvent?> _readEvent(String id) async {
    final row = await (_database.select(
      _database.futureMatterAmendmentEvents,
    )..where((t) => t.id.equals(id))).getSingleOrNull();
    return row == null ? null : _event(row);
  }

  Future<FutureMatterAmendmentEvent> _event(
    FutureMatterAmendmentEventRow row,
  ) async {
    final query = _database.select(_database.futureMatterAmendmentFieldChanges)
      ..where((t) => t.eventId.equals(row.id));
    final changes = <FutureMatterFieldChange>[];
    for (final fieldRow in await query.get()) {
      final field = FutureMatterAmendmentField.values.byName(fieldRow.fieldKey);
      changes.add(
        FutureMatterFieldChange(
          field: field,
          oldValue: await _readValue(row.id, fieldRow, 'old'),
          newValue: await _readValue(row.id, fieldRow, 'new'),
        ),
      );
    }
    return FutureMatterAmendmentEvent(
      id: row.id,
      futureMatterId: row.futureMatterId,
      eventType: FutureMatterAmendmentType.values.byName(row.eventType),
      target: FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.values.byName(row.targetEventKind),
        id: row.targetEventId,
      ),
      occurredAt: row.occurredAt,
      recordedAt: row.recordedAt,
      eventSource: FutureMatterSource.values.byName(row.eventSource),
      sourceReferenceKind: row.sourceReferenceKind == null
          ? null
          : FutureMatterSourceReferenceKind.values.byName(
              row.sourceReferenceKind!,
            ),
      sourceReferenceId: row.sourceReferenceId,
      changes: changes,
    );
  }

  Future<FutureMatterFieldValue> _readValue(
    String eventId,
    FutureMatterAmendmentFieldChangeRow row,
    String side,
  ) async {
    final state = _state(side == 'old' ? row.oldState : row.newState);
    if (state == FutureMatterValueState.absent) {
      return const FutureMatterFieldValue.absent();
    }
    if (state == FutureMatterValueState.nullValue) {
      return const FutureMatterFieldValue.nullValue();
    }
    final field = FutureMatterAmendmentField.values.byName(row.fieldKey);
    Object value;
    if (field == FutureMatterAmendmentField.completedDate) {
      value = FutureMatterDate.parse(
        side == 'old' ? row.oldTextValue! : row.newTextValue!,
      );
    } else if (field == FutureMatterAmendmentField.completedMinuteOfDay) {
      value = side == 'old' ? row.oldIntegerValue! : row.newIntegerValue!;
    } else if (field == FutureMatterAmendmentField.note) {
      value = side == 'old' ? row.oldTextValue! : row.newTextValue!;
    } else if (field == FutureMatterAmendmentField.attachments) {
      final rows =
          await (_database.select(
                _database.futureMatterAmendmentAttachmentValues,
              )..where(
                (t) => t.eventId.equals(eventId) & t.valueSide.equals(side),
              ))
              .get();
      value = [for (final item in rows) item.attachmentId];
    } else if (field == FutureMatterAmendmentField.relatedPeople) {
      final rows =
          await (_database.select(_database.futureMatterAmendmentRelatedPeople)
                ..where(
                  (t) => t.eventId.equals(eventId) & t.valueSide.equals(side),
                )
                ..orderBy([(t) => OrderingTerm.asc(t.id)]))
              .get();
      value = [
        for (final item in rows)
          FutureMatterRelatedPerson(
            displayName: item.displayName,
            relationNote: item.relationNote,
          ),
      ];
    } else {
      final money =
          await (_database.select(_database.futureMatterAmendmentMoneyValues)
                ..where(
                  (t) => t.eventId.equals(eventId) & t.valueSide.equals(side),
                ))
              .getSingle();
      value = FutureMatterMoney(
        amountMinor: money.amountMinor,
        currency: money.currency,
      );
    }
    return FutureMatterFieldValue.value(value);
  }

  Future<void> _requireMatter(String id) async {
    if (await (_database.select(
          _database.futureMatters,
        )..where((t) => t.id.equals(id))).getSingleOrNull() ==
        null) {
      throw RepositoryConstraintException('FutureMatter $id does not exist.');
    }
  }

  Future<void> _requireSourceReference(
    FutureMatterSourceReferenceKind kind,
    String id,
  ) async {
    final targetKind = switch (kind) {
      FutureMatterSourceReferenceKind.futureMatterCreatedEvent =>
        FutureMatterTargetEventKind.created,
      FutureMatterSourceReferenceKind.futureMatterChangeEvent =>
        FutureMatterTargetEventKind.change,
      FutureMatterSourceReferenceKind.futureMatterCompletedEvent =>
        FutureMatterTargetEventKind.completed,
      FutureMatterSourceReferenceKind.futureMatterAmendmentEvent => null,
      FutureMatterSourceReferenceKind.maintenanceRecord => null,
    };
    bool exists;
    if (targetKind != null) {
      exists =
          await _matterIdFor(
            FutureMatterEventReference(kind: targetKind, id: id),
          ) !=
          null;
    } else if (kind ==
        FutureMatterSourceReferenceKind.futureMatterAmendmentEvent) {
      exists =
          await (_database.select(
            _database.futureMatterAmendmentEvents,
          )..where((t) => t.id.equals(id))).getSingleOrNull() !=
          null;
    } else {
      exists =
          await (_database.select(
            _database.maintenanceRecords,
          )..where((t) => t.id.equals(id))).getSingleOrNull() !=
          null;
    }
    if (!exists) {
      throw RepositoryConstraintException(
        'Source reference ${kind.name}:$id does not exist.',
      );
    }
  }
}

String _stateName(FutureMatterValueState state) =>
    state == FutureMatterValueState.nullValue ? 'null' : state.name;
FutureMatterValueState _state(String value) => value == 'null'
    ? FutureMatterValueState.nullValue
    : FutureMatterValueState.values.byName(value);
String _valueType(FutureMatterAmendmentField field) => switch (field) {
  FutureMatterAmendmentField.completedDate => 'futureMatterDate',
  FutureMatterAmendmentField.completedMinuteOfDay => 'minuteOfDay',
  FutureMatterAmendmentField.note => 'text',
  FutureMatterAmendmentField.attachments => 'attachmentCollection',
  FutureMatterAmendmentField.cost => 'money',
  FutureMatterAmendmentField.relatedPeople => 'relatedPeopleCollection',
};
String? _textScalar(
  FutureMatterAmendmentField field,
  FutureMatterFieldValue value,
) => value.state != FutureMatterValueState.value
    ? null
    : switch (field) {
        FutureMatterAmendmentField.completedDate =>
          (value.value! as FutureMatterDate).storageValue,
        FutureMatterAmendmentField.note => value.value! as String,
        _ => null,
      };
int? _integerScalar(
  FutureMatterAmendmentField field,
  FutureMatterFieldValue value,
) =>
    value.state == FutureMatterValueState.value &&
        field == FutureMatterAmendmentField.completedMinuteOfDay
    ? value.value! as int
    : null;
String? _textOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}

const _iso4217 = <String>{
  'AED',
  'AFN',
  'ALL',
  'AMD',
  'ANG',
  'AOA',
  'ARS',
  'AUD',
  'AWG',
  'AZN',
  'BAM',
  'BBD',
  'BDT',
  'BGN',
  'BHD',
  'BIF',
  'BMD',
  'BND',
  'BOB',
  'BOV',
  'BRL',
  'BSD',
  'BTN',
  'BWP',
  'BYN',
  'BZD',
  'CAD',
  'CDF',
  'CHE',
  'CHF',
  'CHW',
  'CLF',
  'CLP',
  'CNY',
  'COP',
  'COU',
  'CRC',
  'CUC',
  'CUP',
  'CVE',
  'CZK',
  'DJF',
  'DKK',
  'DOP',
  'DZD',
  'EGP',
  'ERN',
  'ETB',
  'EUR',
  'FJD',
  'FKP',
  'GBP',
  'GEL',
  'GHS',
  'GIP',
  'GMD',
  'GNF',
  'GTQ',
  'GYD',
  'HKD',
  'HNL',
  'HRK',
  'HTG',
  'HUF',
  'IDR',
  'ILS',
  'INR',
  'IQD',
  'IRR',
  'ISK',
  'JMD',
  'JOD',
  'JPY',
  'KES',
  'KGS',
  'KHR',
  'KMF',
  'KPW',
  'KRW',
  'KWD',
  'KYD',
  'KZT',
  'LAK',
  'LBP',
  'LKR',
  'LRD',
  'LSL',
  'LYD',
  'MAD',
  'MDL',
  'MGA',
  'MKD',
  'MMK',
  'MNT',
  'MOP',
  'MRU',
  'MUR',
  'MVR',
  'MWK',
  'MXN',
  'MXV',
  'MYR',
  'MZN',
  'NAD',
  'NGN',
  'NIO',
  'NOK',
  'NPR',
  'NZD',
  'OMR',
  'PAB',
  'PEN',
  'PGK',
  'PHP',
  'PKR',
  'PLN',
  'PYG',
  'QAR',
  'RON',
  'RSD',
  'RUB',
  'RWF',
  'SAR',
  'SBD',
  'SCR',
  'SDG',
  'SEK',
  'SGD',
  'SHP',
  'SLE',
  'SLL',
  'SOS',
  'SRD',
  'SSP',
  'STN',
  'SVC',
  'SYP',
  'SZL',
  'THB',
  'TJS',
  'TMT',
  'TND',
  'TOP',
  'TRY',
  'TTD',
  'TWD',
  'TZS',
  'UAH',
  'UGX',
  'USD',
  'USN',
  'UYI',
  'UYU',
  'UYW',
  'UZS',
  'VED',
  'VES',
  'VND',
  'VUV',
  'WST',
  'XAF',
  'XAG',
  'XAU',
  'XBA',
  'XBB',
  'XBC',
  'XBD',
  'XCD',
  'XDR',
  'XOF',
  'XPD',
  'XPF',
  'XPT',
  'XSU',
  'XTS',
  'XUA',
  'XXX',
  'YER',
  'ZAR',
  'ZMW',
  'ZWL',
};
