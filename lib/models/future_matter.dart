enum FutureMatterTimingMode { later, specifiedDate, recurring, condition }

enum FutureMatterIntervalUnit { minute, hour, day, week, month, year }

enum FutureMatterConditionType { afterFormalCompletion }

enum FutureMatterLifecycleStatus { active, completed }

enum FutureMatterSource { manual, ai, backfill, system }

enum FutureMatterSourceReferenceKind {
  futureMatterCreatedEvent,
  futureMatterChangeEvent,
  futureMatterCompletedEvent,
  futureMatterAmendmentEvent,
  maintenanceRecord,
}

enum FutureMatterAmendmentType { supplement, correction }

enum FutureMatterTargetEventKind {
  created,
  change,
  completed,
  supplement,
  correction,
}

enum FutureMatterAmendmentField {
  completedDate,
  completedMinuteOfDay,
  note,
  attachments,
  cost,
  relatedPeople,
}

enum FutureMatterValueState { absent, nullValue, value }

class FutureMatterDate {
  const FutureMatterDate(this.year, this.month, this.day);

  factory FutureMatterDate.parse(String value) {
    final match = RegExp(r'^(\d{4})-(\d{2})-(\d{2})$').firstMatch(value);
    if (match == null) {
      throw FormatException('FutureMatterDate must use YYYY-MM-DD.', value);
    }
    final date = FutureMatterDate(
      int.parse(match.group(1)!),
      int.parse(match.group(2)!),
      int.parse(match.group(3)!),
    );
    if (!date.isValid) {
      throw FormatException('FutureMatterDate is not a calendar date.', value);
    }
    return date;
  }

  final int year;
  final int month;
  final int day;

  bool get isValid {
    if (year < 1 || year > 9999 || month < 1 || month > 12 || day < 1) {
      return false;
    }
    final candidate = DateTime.utc(year, month, day);
    return candidate.year == year &&
        candidate.month == month &&
        candidate.day == day;
  }

  String get storageValue =>
      '${year.toString().padLeft(4, '0')}-'
      '${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';

  @override
  bool operator ==(Object other) =>
      other is FutureMatterDate &&
      year == other.year &&
      month == other.month &&
      day == other.day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() => storageValue;
}

class FutureMatter {
  const FutureMatter({
    required this.id,
    required this.title,
    required this.timingMode,
    required this.createdAt,
    required this.updatedAt,
    this.lifecycleStatus = FutureMatterLifecycleStatus.active,
    this.itemId,
    this.specifiedDate,
    this.specifiedMinuteOfDay,
    this.recurringIntervalValue,
    this.recurringIntervalUnit,
    this.recurringAnchorDate,
    this.recurringAnchorMinuteOfDay,
    this.conditionType,
    this.conditionMaintenanceRecordId,
    this.conditionDelayValue,
    this.conditionDelayUnit,
    this.createdSource,
    this.createdSourceReferenceKind,
    this.createdSourceReferenceId,
  });

  final String id;
  final String title;
  final String? itemId;
  final FutureMatterTimingMode timingMode;
  final FutureMatterDate? specifiedDate;
  final int? specifiedMinuteOfDay;
  final int? recurringIntervalValue;
  final FutureMatterIntervalUnit? recurringIntervalUnit;
  final FutureMatterDate? recurringAnchorDate;
  final int? recurringAnchorMinuteOfDay;
  final FutureMatterConditionType? conditionType;
  final String? conditionMaintenanceRecordId;
  final int? conditionDelayValue;
  final FutureMatterIntervalUnit? conditionDelayUnit;
  final DateTime createdAt;
  final DateTime updatedAt;
  final FutureMatterLifecycleStatus lifecycleStatus;
  final FutureMatterSource? createdSource;
  final FutureMatterSourceReferenceKind? createdSourceReferenceKind;
  final String? createdSourceReferenceId;
}

class FutureMatterCompletedEvent {
  const FutureMatterCompletedEvent({
    required this.id,
    required this.futureMatterId,
    required this.completedDate,
    required this.confirmedAt,
    required this.createdAt,
    required this.snapshot,
    this.completedMinuteOfDay,
  });

  final String id;
  final String futureMatterId;
  final FutureMatterDate completedDate;
  final int? completedMinuteOfDay;
  final DateTime confirmedAt;
  final DateTime createdAt;
  final FutureMatter snapshot;
}

class FutureMatterCreatedEvent {
  const FutureMatterCreatedEvent({
    required this.id,
    required this.futureMatterId,
    required this.titleSnapshot,
    required this.timingModeSnapshot,
    required this.occurredAt,
    required this.createdAt,
    this.itemIdSnapshot,
    this.specifiedDateSnapshot,
    this.specifiedMinuteOfDaySnapshot,
    this.recurringIntervalValueSnapshot,
    this.recurringIntervalUnitSnapshot,
    this.recurringAnchorDateSnapshot,
    this.recurringAnchorMinuteOfDaySnapshot,
    this.conditionTypeSnapshot,
    this.conditionMaintenanceRecordIdSnapshot,
    this.conditionDelayValueSnapshot,
    this.conditionDelayUnitSnapshot,
  });

  final String id;
  final String futureMatterId;
  final String titleSnapshot;
  final String? itemIdSnapshot;
  final FutureMatterTimingMode timingModeSnapshot;
  final FutureMatterDate? specifiedDateSnapshot;
  final int? specifiedMinuteOfDaySnapshot;
  final int? recurringIntervalValueSnapshot;
  final FutureMatterIntervalUnit? recurringIntervalUnitSnapshot;
  final FutureMatterDate? recurringAnchorDateSnapshot;
  final int? recurringAnchorMinuteOfDaySnapshot;
  final FutureMatterConditionType? conditionTypeSnapshot;
  final String? conditionMaintenanceRecordIdSnapshot;
  final int? conditionDelayValueSnapshot;
  final FutureMatterIntervalUnit? conditionDelayUnitSnapshot;
  final DateTime occurredAt;
  final DateTime createdAt;
}

class FutureMatterChangeEvent {
  const FutureMatterChangeEvent({
    required this.id,
    required this.futureMatterId,
    required this.occurredAt,
    required this.createdAt,
    required this.before,
    required this.after,
  });

  final String id;
  final String futureMatterId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final FutureMatter before;
  final FutureMatter after;
}

class FutureMatterMoney {
  const FutureMatterMoney({required this.amountMinor, required this.currency});

  final int amountMinor;
  final String currency;

  @override
  bool operator ==(Object other) =>
      other is FutureMatterMoney &&
      amountMinor == other.amountMinor &&
      currency == other.currency;

  @override
  int get hashCode => Object.hash(amountMinor, currency);
}

class FutureMatterRelatedPerson {
  const FutureMatterRelatedPerson({
    required this.displayName,
    this.relationNote,
  });

  final String displayName;
  final String? relationNote;

  @override
  bool operator ==(Object other) =>
      other is FutureMatterRelatedPerson &&
      displayName == other.displayName &&
      relationNote == other.relationNote;

  @override
  int get hashCode => Object.hash(displayName, relationNote);
}

class FutureMatterFieldValue {
  const FutureMatterFieldValue._(this.state, this.value);

  const FutureMatterFieldValue.absent()
    : this._(FutureMatterValueState.absent, null);
  const FutureMatterFieldValue.nullValue()
    : this._(FutureMatterValueState.nullValue, null);
  const FutureMatterFieldValue.value(Object this.value)
    : state = FutureMatterValueState.value;

  final FutureMatterValueState state;
  final Object? value;

  @override
  bool operator ==(Object other) =>
      other is FutureMatterFieldValue &&
      state == other.state &&
      _deepEquals(value, other.value);

  @override
  int get hashCode => Object.hash(state, _deepHash(value));
}

class FutureMatterFieldChange {
  const FutureMatterFieldChange({
    required this.field,
    required this.oldValue,
    required this.newValue,
  });

  final FutureMatterAmendmentField field;
  final FutureMatterFieldValue oldValue;
  final FutureMatterFieldValue newValue;
}

class FutureMatterEventReference {
  const FutureMatterEventReference({required this.kind, required this.id});

  final FutureMatterTargetEventKind kind;
  final String id;
}

class FutureMatterAmendmentEvent {
  FutureMatterAmendmentEvent({
    required this.id,
    required this.futureMatterId,
    required this.eventType,
    required this.target,
    required this.recordedAt,
    required this.eventSource,
    required List<FutureMatterFieldChange> changes,
    this.occurredAt,
    this.sourceReferenceKind,
    this.sourceReferenceId,
  }) : changes = List.unmodifiable(changes);

  final String id;
  final String futureMatterId;
  final FutureMatterAmendmentType eventType;
  final FutureMatterEventReference target;
  final DateTime? occurredAt;
  final DateTime recordedAt;
  final FutureMatterSource eventSource;
  final FutureMatterSourceReferenceKind? sourceReferenceKind;
  final String? sourceReferenceId;
  final List<FutureMatterFieldChange> changes;
}

class FutureMatterEffectiveFacts {
  FutureMatterEffectiveFacts(
    Map<FutureMatterAmendmentField, FutureMatterFieldValue> values,
  ) : values = Map.unmodifiable(values);

  final Map<FutureMatterAmendmentField, FutureMatterFieldValue> values;
}

bool _deepEquals(Object? left, Object? right) {
  if (left is List && right is List) {
    if (left.length != right.length) return false;
    final unmatched = [...right];
    for (final value in left) {
      final index = unmatched.indexWhere(
        (candidate) => _deepEquals(value, candidate),
      );
      if (index < 0) return false;
      unmatched.removeAt(index);
    }
    return true;
  }
  return left == right;
}

int _deepHash(Object? value) {
  if (value is List) {
    final hashes = value.map(_deepHash).toList()..sort();
    return Object.hashAll(hashes);
  }
  return value.hashCode;
}
