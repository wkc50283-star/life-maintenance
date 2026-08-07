import 'item_management_period.dart';

enum ItemManagementIntervalUnit { day, week, month, quarter, halfYear, year }

enum ItemManagementIntervalFamily { day, calendarMonth }

class ItemCustomManagementPeriod {
  ItemCustomManagementPeriod({
    required this.intervalValue,
    required this.intervalUnit,
  }) {
    if (intervalValue <= 0) {
      throw ArgumentError.value(
        intervalValue,
        'intervalValue',
        'must be a positive integer',
      );
    }
    if (intervalValue > maxStoredInteger ~/ _unitMultiplier(intervalUnit)) {
      throw ArgumentError.value(
        intervalValue,
        'intervalValue',
        'exceeds the safe signed 64-bit storage range',
      );
    }
  }

  /// Largest integer represented exactly by every supported Dart target,
  /// including JavaScript, and accepted by SQLite INTEGER storage.
  static const int maxStoredInteger = 0x1FFFFFFFFFFFFF;

  final int intervalValue;
  final ItemManagementIntervalUnit intervalUnit;

  ItemManagementIntervalFamily get canonicalFamily => switch (intervalUnit) {
    ItemManagementIntervalUnit.day ||
    ItemManagementIntervalUnit.week => ItemManagementIntervalFamily.day,
    ItemManagementIntervalUnit.month ||
    ItemManagementIntervalUnit.quarter ||
    ItemManagementIntervalUnit.halfYear ||
    ItemManagementIntervalUnit.year =>
      ItemManagementIntervalFamily.calendarMonth,
  };

  int get canonicalValue => intervalValue * _unitMultiplier(intervalUnit);

  String get equivalenceKey => '${canonicalFamily.name}:$canonicalValue';

  ItemManagementPeriod? get fixedPeriod => intervalValue == 1
      ? switch (intervalUnit) {
          ItemManagementIntervalUnit.day => ItemManagementPeriod.day,
          ItemManagementIntervalUnit.week => ItemManagementPeriod.week,
          ItemManagementIntervalUnit.month => ItemManagementPeriod.month,
          ItemManagementIntervalUnit.quarter => ItemManagementPeriod.quarter,
          ItemManagementIntervalUnit.halfYear => ItemManagementPeriod.halfYear,
          ItemManagementIntervalUnit.year => ItemManagementPeriod.year,
        }
      : null;

  DateTime addTo(DateTime start) {
    try {
      return switch (canonicalFamily) {
        ItemManagementIntervalFamily.day => _addDays(start, canonicalValue),
        ItemManagementIntervalFamily.calendarMonth => _addCalendarMonths(
          start,
          canonicalValue,
        ),
      };
    } on RangeError {
      throw RangeError(
        'Management period calculation exceeds the DateTime range.',
      );
    } on ArgumentError {
      throw RangeError(
        'Management period calculation exceeds the DateTime range.',
      );
    }
  }

  @override
  bool operator ==(Object other) =>
      other is ItemCustomManagementPeriod &&
      other.intervalValue == intervalValue &&
      other.intervalUnit == intervalUnit;

  @override
  int get hashCode => Object.hash(intervalValue, intervalUnit);
}

int itemManagementPeriodCanonicalValue(ItemManagementPeriod period) =>
    switch (period) {
      ItemManagementPeriod.day => 1,
      ItemManagementPeriod.week => 7,
      ItemManagementPeriod.month => 1,
      ItemManagementPeriod.quarter => 3,
      ItemManagementPeriod.halfYear => 6,
      ItemManagementPeriod.year => 12,
    };

ItemManagementIntervalFamily itemManagementPeriodCanonicalFamily(
  ItemManagementPeriod period,
) => switch (period) {
  ItemManagementPeriod.day ||
  ItemManagementPeriod.week => ItemManagementIntervalFamily.day,
  ItemManagementPeriod.month ||
  ItemManagementPeriod.quarter ||
  ItemManagementPeriod.halfYear ||
  ItemManagementPeriod.year => ItemManagementIntervalFamily.calendarMonth,
};

String itemManagementPeriodEquivalenceKey(ItemManagementPeriod period) =>
    '${itemManagementPeriodCanonicalFamily(period).name}:'
    '${itemManagementPeriodCanonicalValue(period)}';

int _unitMultiplier(ItemManagementIntervalUnit unit) => switch (unit) {
  ItemManagementIntervalUnit.day || ItemManagementIntervalUnit.month => 1,
  ItemManagementIntervalUnit.week => 7,
  ItemManagementIntervalUnit.quarter => 3,
  ItemManagementIntervalUnit.halfYear => 6,
  ItemManagementIntervalUnit.year => 12,
};

DateTime _addCalendarMonths(DateTime start, int months) {
  final monthIndex = start.year * 12 + start.month - 1 + months;
  final targetYear = monthIndex ~/ 12;
  final targetMonth = monthIndex % 12 + 1;
  final lastDay = _dateLike(start, targetYear, targetMonth + 1, 0).day;
  return _dateLike(
    start,
    targetYear,
    targetMonth,
    start.day > lastDay ? lastDay : start.day,
  );
}

DateTime _addDays(DateTime start, int days) {
  const maxMicrosecondsSinceEpoch = 8640000000000000000;
  final remaining = maxMicrosecondsSinceEpoch - start.microsecondsSinceEpoch;
  if (days > remaining ~/ Duration.microsecondsPerDay) {
    throw RangeError('DateTime range exceeded.');
  }
  final target =
      start.microsecondsSinceEpoch + days * Duration.microsecondsPerDay;
  return DateTime.fromMicrosecondsSinceEpoch(target, isUtc: start.isUtc);
}

DateTime _dateLike(DateTime source, int year, int month, int day) =>
    source.isUtc
    ? DateTime.utc(
        year,
        month,
        day,
        source.hour,
        source.minute,
        source.second,
        source.millisecond,
        source.microsecond,
      )
    : DateTime(
        year,
        month,
        day,
        source.hour,
        source.minute,
        source.second,
        source.millisecond,
        source.microsecond,
      );
