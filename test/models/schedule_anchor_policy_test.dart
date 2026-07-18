import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/schedule_anchor_policy.dart';

void main() {
  group('fixedCalendarPeriod', () {
    test('daily stays on the original daily sequence after late completion', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.daily,
        interval: 1,
        scheduledDueDate: DateTime(2026, 7, 1, 9),
        completedAt: DateTime(2026, 7, 4, 18),
      );

      expect(next, DateTime(2026, 7, 5, 9));
    });

    test('weekly stays on the original weekday and time', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.weekly,
        interval: 1,
        scheduledDueDate: DateTime(2026, 7, 6, 9),
        completedAt: DateTime(2026, 7, 15, 18),
      );

      expect(next, DateTime(2026, 7, 20, 9));
      expect(next.weekday, DateTime.monday);
    });

    test('monthly preserves month-end intent instead of drifting to day 28', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.monthly,
        interval: 1,
        scheduledDueDate: DateTime(2026, 1, 31, 9),
        completedAt: DateTime(2026, 2, 28, 12),
      );

      expect(next, DateTime(2026, 3, 31, 9));
    });

    test('quarterly remains quarterly after delayed completion', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.quarterly,
        interval: 1,
        scheduledDueDate: DateTime(2026, 1, 15),
        completedAt: DateTime(2026, 8, 1),
      );

      expect(next, DateTime(2026, 10, 15));
    });

    test('semiannual remains semiannual after delayed completion', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.semiAnnual,
        interval: 1,
        scheduledDueDate: DateTime(2026, 1, 10),
        completedAt: DateTime(2027, 2, 1),
      );

      expect(next, DateTime(2027, 7, 10));
    });

    test('yearly preserves leap-day anchor when the leap year returns', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
        cycleType: CycleType.yearly,
        interval: 1,
        scheduledDueDate: DateTime.utc(2024, 2, 29, 8),
        completedAt: DateTime.utc(2027, 3, 1),
      );

      expect(next, DateTime.utc(2028, 2, 29, 8));
      expect(next.isUtc, isTrue);
    });
  });

  group('other policies', () {
    test('completionBased starts a new cycle from actual completion', () {
      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.completionBased,
        cycleType: CycleType.monthly,
        interval: 1,
        scheduledDueDate: DateTime(2026, 1, 1),
        completedAt: DateTime(2026, 1, 20, 14),
      );

      expect(next, DateTime(2026, 2, 20, 14));
    });

    test('userDefined requires a future date', () {
      final completedAt = DateTime(2026, 7, 18);

      expect(
        () => ScheduleAnchorCalculator.nextDueDate(
          policy: ScheduleAnchorPolicy.userDefined,
          cycleType: CycleType.custom,
          interval: 1,
          scheduledDueDate: DateTime(2026, 7, 1),
          completedAt: completedAt,
        ),
        throwsArgumentError,
      );

      expect(
        () => ScheduleAnchorCalculator.nextDueDate(
          policy: ScheduleAnchorPolicy.userDefined,
          cycleType: CycleType.custom,
          interval: 1,
          scheduledDueDate: DateTime(2026, 7, 1),
          completedAt: completedAt,
          userDefinedNextDueDate: completedAt,
        ),
        throwsArgumentError,
      );

      final next = ScheduleAnchorCalculator.nextDueDate(
        policy: ScheduleAnchorPolicy.userDefined,
        cycleType: CycleType.custom,
        interval: 1,
        scheduledDueDate: DateTime(2026, 7, 1),
        completedAt: completedAt,
        userDefinedNextDueDate: DateTime(2026, 8, 3),
      );

      expect(next, DateTime(2026, 8, 3));
    });

    test('interval must be positive', () {
      expect(
        () => ScheduleAnchorCalculator.nextDueDate(
          policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
          cycleType: CycleType.weekly,
          interval: 0,
          scheduledDueDate: DateTime(2026, 7, 1),
          completedAt: DateTime(2026, 7, 2),
        ),
        throwsArgumentError,
      );
    });

    test('custom cycles cannot silently use automatic policies', () {
      expect(
        () => ScheduleAnchorCalculator.nextDueDate(
          policy: ScheduleAnchorPolicy.fixedCalendarPeriod,
          cycleType: CycleType.custom,
          interval: 1,
          scheduledDueDate: DateTime(2026, 7, 1),
          completedAt: DateTime(2026, 7, 2),
        ),
        throwsUnsupportedError,
      );
    });
  });
}
