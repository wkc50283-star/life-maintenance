enum FutureMatterTimingMode { later, specifiedDate, recurring, condition }

enum FutureMatterIntervalUnit { minute, hour, day, week, month, year }

enum FutureMatterConditionType { afterFormalCompletion }

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
