import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/schedule_anchor_policy.dart';
import '../../models/work_case.dart';
import '../../models/work_case_enums.dart';
import '../repository_constraint_exception.dart';
import 'drift_schema_v2_repositories.dart';

class DriftRecurringTaskCompletion {
  const DriftRecurringTaskCompletion({
    required DriftTaskRepository tasks,
    required DriftScheduleRepository schedules,
  }) : _tasks = tasks,
       _schedules = schedules;

  final DriftTaskRepository _tasks;
  final DriftScheduleRepository _schedules;

  Future<void> complete({
    required TaskRow task,
    required DateTime completedAt,
    WorkCase? sourceWorkCase,
  }) async {
    if (task.status == TaskStatus.completed.name ||
        task.status == TaskStatus.canceled.name) {
      throw const RepositoryConstraintException(
        'A completed or canceled Task cannot be changed.',
      );
    }
    final scheduleId = task.scheduleId;
    if (scheduleId == null) {
      throw const RepositoryConstraintException(
        'Only a scheduled Reminder or Maintenance Task can be completed directly.',
      );
    }

    final schedule = await _schedules.findById(scheduleId);
    final hasMatchingSource = switch (task.sourceType) {
      'scheduledReminder' =>
        task.generalReminderId != null &&
            schedule?.sourceType == 'generalReminder' &&
            schedule?.generalReminderId == task.generalReminderId,
      'scheduledMaintenance' =>
        task.maintenancePlanId != null &&
            schedule?.sourceType == 'maintenancePlan' &&
            schedule?.maintenancePlanId == task.maintenancePlanId,
      _ => false,
    };
    if (schedule == null || !hasMatchingSource) {
      throw const RepositoryConstraintException(
        'The Task has no matching formal Reminder or Maintenance Schedule.',
      );
    }
    if (sourceWorkCase != null) {
      _validateWorkCaseSource(sourceWorkCase, task);
    }
    if (schedule.status != ScheduleStatus.active.name) {
      throw const RepositoryConstraintException(
        'Only an active Schedule can advance after completion.',
      );
    }

    final cycleType = _supportedCycleType(schedule.cycleType);
    final anchorPolicy = _anchorPolicy(schedule.anchorPolicy);
    final nextDueDate = ScheduleAnchorCalculator.nextDueDate(
      policy: anchorPolicy,
      cycleType: cycleType,
      interval: schedule.interval,
      scheduledDueDate: task.dueDate,
      completedAt: completedAt,
      userDefinedNextDueDate: schedule.userDefinedNextDate,
    );
    if (!nextDueDate.isAfter(task.dueDate)) {
      throw const RepositoryConstraintException(
        'The next Schedule date must follow this Task due date.',
      );
    }

    await _tasks.save(
      task.copyWith(
        status: TaskStatus.completed.name,
        completedAt: Value(completedAt),
        postponedAt: const Value(null),
        updatedAt: completedAt,
      ),
    );
    await _schedules.save(
      schedule.copyWith(nextDueDate: nextDueDate, updatedAt: completedAt),
    );
  }

  void _validateWorkCaseSource(WorkCase workCase, TaskRow task) {
    if (workCase.sourceTaskId != task.id || workCase.itemId != task.itemId) {
      throw const RepositoryConstraintException(
        'WorkCase and source Task do not match.',
      );
    }
    final matches = switch (workCase.sourceType) {
      WorkCaseSourceType.generalReminder =>
        task.sourceType == 'scheduledReminder' &&
            workCase.sourceId == task.generalReminderId,
      WorkCaseSourceType.maintenanceTask =>
        task.sourceType == 'scheduledMaintenance' &&
            task.maintenancePlanId != null &&
            workCase.sourceId == task.id,
      WorkCaseSourceType.milestone ||
      WorkCaseSourceType.manual ||
      WorkCaseSourceType.unknown => false,
    };
    if (!matches) {
      throw const RepositoryConstraintException(
        'WorkCase and source Task formal sources do not match.',
      );
    }
  }
}

CycleType _supportedCycleType(String value) {
  final cycleType = switch (value) {
    'daily' => CycleType.daily,
    'weekly' => CycleType.weekly,
    'monthly' => CycleType.monthly,
    'quarterly' => CycleType.quarterly,
    'semiAnnual' => CycleType.semiAnnual,
    'yearly' => CycleType.yearly,
    _ => null,
  };
  if (cycleType == null) {
    throw const RepositoryConstraintException(
      'This Schedule cycle does not support direct completion.',
    );
  }
  return cycleType;
}

ScheduleAnchorPolicy _anchorPolicy(String value) {
  try {
    return ScheduleAnchorPolicy.values.byName(value);
  } catch (_) {
    throw RepositoryConstraintException(
      'Unsupported Schedule anchor policy $value.',
    );
  }
}
