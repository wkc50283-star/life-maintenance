import 'enums.dart';

enum ScheduleAnchorPolicy {
  fixedCalendarPeriod,
  completionBased,
  userDefined,
}

class ScheduleAnchorCalculator {
  const ScheduleAnchorCalculator._();

  static DateTime nextDueDate({
    required ScheduleAnchorPolicy policy,
    required CycleType cycleType,
    required int interval,
    required DateTime scheduledDueDate,
    required DateTime completedAt,
    DateTime? userDefinedNextDueDate,
  }) {
    if (interval <= 0) {
      throw ArgumentError.value(interval, 'interval', 'must be greater than zero');
    }

    switch (policy) {
      case ScheduleAnchorPolicy.fixedCalendarPeriod:
        return _nextFixedOccurrence(
          cycleType: cycleType,
          interval: interval,
          scheduledDueDate: scheduledDueDate,
          completedAt: completedAt,
        );
      case ScheduleAnchorPolicy.completionBased:
        return _addCycle(completedAt, cycleType, interval);
      case ScheduleAnchorPolicy.userDefined:
        final nextDate = userDefinedNextDueDate;
        if (nextDate == null) {
          throw ArgumentError.notNull('userDefinedNextDueDate');
        }
        if (!nextDate.isAfter(completedAt)) {
          throw ArgumentError.value(
            nextDate,
            'userDefinedNextDueDate',
            'must be after completedAt',
          );
        }
        return nextDate;
    }
  }

  static DateTime _nextFixedOccurrence({
    required CycleType cycleType,
    required int interval,
    required DateTime scheduledDueDate,
    required DateTime completedAt,
  }) {
    var occurrence = 1;
    while (true) {
      final candidate = _addCycle(
        scheduledDueDate,
        cycleType,
        interval * occurrence,
      );
      if (candidate.isAfter(completedAt)) {
        return candidate;
      }
      occurrence += 1;
    }
  }

  static DateTime _addCycle(DateTime date, CycleType cycleType, int amount) {
    return switch (cycleType) {
      CycleType.daily => date.add(Duration(days: amount)),
      CycleType.weekly => date.add(Duration(days: 7 * amount)),
      CycleType.monthly => _addMonths(date, amount),
      CycleType.quarterly => _addMonths(date, 3 * amount),
      CycleType.semiAnnual => _addMonths(date, 6 * amount),
      CycleType.yearly => _addMonths(date, 12 * amount),
      CycleType.custom => throw UnsupportedError(
        'Custom cycles require a user-defined next due date.',
      ),
    };
  }

  static DateTime _addMonths(DateTime date, int months) {
    final totalMonths = date.year * 12 + (date.month - 1) + months;
    final targetYear = totalMonths ~/ 12;
    final targetMonth = totalMonths % 12 + 1;
    final targetDay = date.day.clamp(1, _daysInMonth(targetYear, targetMonth));

    if (date.isUtc) {
      return DateTime.utc(
        targetYear,
        targetMonth,
        targetDay,
        date.hour,
        date.minute,
        date.second,
        date.millisecond,
        date.microsecond,
      );
    }

    return DateTime(
      targetYear,
      targetMonth,
      targetDay,
      date.hour,
      date.minute,
      date.second,
      date.millisecond,
      date.microsecond,
    );
  }

  static int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }
}
