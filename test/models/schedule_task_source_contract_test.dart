import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/schedule_task_source_contract.dart';

void main() {
  group('ScheduleSourceReference', () {
    test('accepts a valid maintenance plan source', () {
      const source = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.maintenancePlan,
        maintenancePlanId: 'plan-1',
      );

      final result = source.validate(maintenancePlanItemId: 'item-1');

      expect(result.isValid, isTrue);
      expect(result.violations, isEmpty);
    });

    test('rejects missing and conflicting source references', () {
      const source = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.maintenancePlan,
        generalReminderId: 'reminder-1',
      );

      final result = source.validate();

      expect(result.isValid, isFalse);
      expect(
        result.violations,
        contains(SourceContractViolation.missingMaintenancePlanId),
      );
      expect(
        result.violations,
        contains(SourceContractViolation.unexpectedGeneralReminderId),
      );
    });

    test('rejects a source that belongs to another life item', () {
      const source = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.milestone,
        milestoneId: 'milestone-1',
      );

      final result = source.validate(milestoneItemId: 'item-2');

      expect(
        result.violations,
        contains(SourceContractViolation.milestoneItemMismatch),
      );
    });

    test('unknown source remains blocked instead of inferred', () {
      const source = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.unknown,
      );

      final result = source.validate();

      expect(result.isValid, isFalse);
      expect(
        result.violations,
        contains(SourceContractViolation.unknownSource),
      );
    });
  });

  group('TaskSourceReference', () {
    test('accepts a scheduled maintenance task with matching schedule', () {
      const schedule = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.maintenancePlan,
        maintenancePlanId: 'plan-1',
      );
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.scheduledMaintenance,
        scheduleId: 'schedule-1',
        maintenancePlanId: 'plan-1',
      );

      final result = task.validate(
        schedule: schedule,
        maintenancePlanItemId: 'item-1',
      );

      expect(result.isValid, isTrue);
    });

    test('rejects a task whose schedule belongs to another item', () {
      const schedule = ScheduleSourceReference(
        itemId: 'item-2',
        sourceType: ScheduleSourceType.generalReminder,
        generalReminderId: 'reminder-1',
      );
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.scheduledReminder,
        scheduleId: 'schedule-1',
        generalReminderId: 'reminder-1',
      );

      final result = task.validate(schedule: schedule);

      expect(
        result.violations,
        contains(SourceContractViolation.itemMismatch),
      );
    });

    test('rejects a task whose source disagrees with its schedule', () {
      const schedule = ScheduleSourceReference(
        itemId: 'item-1',
        sourceType: ScheduleSourceType.generalReminder,
        generalReminderId: 'reminder-1',
      );
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.scheduledMaintenance,
        scheduleId: 'schedule-1',
        maintenancePlanId: 'plan-1',
      );

      final result = task.validate(
        schedule: schedule,
        maintenancePlanItemId: 'item-1',
      );

      expect(
        result.violations,
        contains(SourceContractViolation.scheduleSourceMismatch),
      );
    });

    test('manual task must not pretend to have scheduled sources', () {
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.manual,
        scheduleId: 'schedule-1',
        maintenancePlanId: 'plan-1',
      );

      final result = task.validate();

      expect(
        result.violations,
        contains(SourceContractViolation.unexpectedScheduleId),
      );
      expect(
        result.violations,
        contains(SourceContractViolation.unexpectedMaintenancePlanId),
      );
    });

    test('milestone task may be direct or scheduled but must match item', () {
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.milestone,
        milestoneId: 'milestone-1',
      );

      final result = task.validate(milestoneItemId: 'item-1');

      expect(result.isValid, isTrue);
    });

    test('unknown task source remains blocked instead of inferred', () {
      const task = TaskSourceReference(
        itemId: 'item-1',
        sourceType: TaskSourceType.unknown,
      );

      final result = task.validate();

      expect(result.isValid, isFalse);
      expect(
        result.violations,
        contains(SourceContractViolation.unknownSource),
      );
    });
  });
}
