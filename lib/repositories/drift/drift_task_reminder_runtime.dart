import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/schedule_anchor_policy.dart';
import '../../models/task.dart';
import '../../models/work_case.dart';
import '../../models/work_case_enums.dart';
import '../repository_constraint_exception.dart';
import '../task_reminder_runtime.dart';
import '../work_case_runtime.dart';
import 'drift_schema_v2_repositories.dart';

class DriftTaskReminderRuntime implements TaskReminderRuntime {
  DriftTaskReminderRuntime({
    required AppDatabase database,
    required DriftSchemaV2Repositories repositories,
    required WorkCaseRuntime workCaseRuntime,
  }) : _database = database,
       _repositories = repositories,
       _workCaseRuntime = workCaseRuntime;

  final AppDatabase _database;
  final DriftSchemaV2Repositories _repositories;
  final WorkCaseRuntime _workCaseRuntime;

  @override
  Future<List<TaskReminderDetail>> loadReminders() async {
    final rows = await _repositories.tasks.listAll();
    final details = <TaskReminderDetail>[];
    for (final row in rows) {
      details.add(await _toDetail(row));
    }
    return details;
  }

  @override
  Future<TaskReminderDetail?> findReminder(String taskId) async {
    final row = await _repositories.tasks.findById(taskId);
    return row == null ? null : _toDetail(row);
  }

  @override
  Future<void> pause(String taskId, DateTime changedAt) async {
    await _updateMutableTask(taskId, (row) {
      if (row.status == TaskStatus.postponed.name) return row;
      return row.copyWith(
        status: TaskStatus.postponed.name,
        postponedAt: Value(changedAt),
        updatedAt: changedAt,
      );
    });
  }

  @override
  Future<void> resume(String taskId, DateTime changedAt) async {
    await _database.transaction(() async {
      final row = await _requireMutableTask(taskId);
      if (row.status != TaskStatus.postponed.name) {
        throw const RepositoryConstraintException(
          'Only a paused Task can be resumed.',
        );
      }
      await _repositories.tasks.save(
        row.copyWith(
          status: _activeStatus(row.dueDate, changedAt),
          postponedAt: const Value(null),
          updatedAt: changedAt,
        ),
      );
    });
  }

  @override
  Future<void> reschedule(
    String taskId,
    DateTime dueDate,
    DateTime changedAt,
  ) async {
    await _database.transaction(() async {
      final row = await _requireMutableTask(taskId);
      if (_dateOnly(dueDate).isBefore(_dateOnly(changedAt))) {
        throw const RepositoryConstraintException(
          'A Task can only be rescheduled to today or a future date.',
        );
      }
      if (row.scheduleId case final scheduleId?) {
        final existing = await _repositories.tasks.listAll();
        if (existing.any(
          (entry) =>
              entry.id != row.id &&
              entry.scheduleId == scheduleId &&
              entry.dueDate == dueDate,
        )) {
          throw const RepositoryConstraintException(
            'This Schedule already has a Task on the selected date.',
          );
        }
      }
      final isPaused = row.status == TaskStatus.postponed.name;
      await _repositories.tasks.save(
        row.copyWith(
          dueDate: dueDate,
          status: isPaused ? row.status : _activeStatus(dueDate, changedAt),
          updatedAt: changedAt,
        ),
      );
    });
  }

  @override
  Future<void> complete(String taskId, DateTime completedAt) async {
    await _database.transaction(() async {
      final row = await _requireMutableTask(taskId);
      if (row.scheduleId == null) {
        throw const RepositoryConstraintException(
          'Only a scheduled Reminder or Maintenance Task can be completed directly.',
        );
      }

      final schedule = await _repositories.schedules.findById(row.scheduleId!);
      final hasMatchingSource = switch (row.sourceType) {
        'scheduledReminder' =>
          row.generalReminderId != null &&
              schedule?.sourceType == 'generalReminder' &&
              schedule?.generalReminderId == row.generalReminderId,
        'scheduledMaintenance' =>
          row.maintenancePlanId != null &&
              schedule?.sourceType == 'maintenancePlan' &&
              schedule?.maintenancePlanId == row.maintenancePlanId,
        _ => false,
      };
      if (schedule == null || !hasMatchingSource) {
        throw const RepositoryConstraintException(
          'The Task has no matching formal Reminder or Maintenance Schedule.',
        );
      }
      if (schedule.status != ScheduleStatus.active.name) {
        throw const RepositoryConstraintException(
          'Only an active Schedule can advance after completion.',
        );
      }

      final cycleType = _supportedCycleType(schedule.cycleType);
      final sourceCases = await _workCaseRuntime.listBySourceTaskId(row.id);
      if (sourceCases.any((workCase) => workCase.isOpen)) {
        throw const RepositoryConstraintException(
          'A Task with an open WorkCase cannot be completed directly.',
        );
      }

      final anchorPolicy = _anchorPolicy(schedule.anchorPolicy);
      final nextDueDate = ScheduleAnchorCalculator.nextDueDate(
        policy: anchorPolicy,
        cycleType: cycleType,
        interval: schedule.interval,
        scheduledDueDate: row.dueDate,
        completedAt: completedAt,
        userDefinedNextDueDate: schedule.userDefinedNextDate,
      );
      if (!nextDueDate.isAfter(row.dueDate)) {
        throw const RepositoryConstraintException(
          'The next Schedule date must follow this Task due date.',
        );
      }

      await _repositories.tasks.save(
        row.copyWith(
          status: TaskStatus.completed.name,
          completedAt: Value(completedAt),
          postponedAt: const Value(null),
          updatedAt: completedAt,
        ),
      );
      await _repositories.schedules.save(
        schedule.copyWith(nextDueDate: nextDueDate, updatedAt: completedAt),
      );
    });
  }

  @override
  Future<WorkCase> startWorkCase({
    required String taskId,
    required WorkCase workCase,
  }) async {
    if (workCase.status != WorkCaseStatus.inProgress ||
        workCase.startedAt == null ||
        workCase.isClosed) {
      throw const RepositoryConstraintException(
        'A WorkCase started from a Task must begin in progress.',
      );
    }
    return _workCaseRuntime.createFromTask(taskId: taskId, workCase: workCase);
  }

  Future<void> _updateMutableTask(
    String taskId,
    TaskRow Function(TaskRow row) update,
  ) async {
    await _database.transaction(() async {
      final row = await _requireMutableTask(taskId);
      await _repositories.tasks.save(update(row));
    });
  }

  Future<TaskRow> _requireMutableTask(String taskId) async {
    final row = await _repositories.tasks.findById(taskId);
    if (row == null) {
      throw RepositoryConstraintException('Task $taskId does not exist.');
    }
    if (row.status == TaskStatus.completed.name ||
        row.status == TaskStatus.canceled.name) {
      throw const RepositoryConstraintException(
        'A completed or canceled Task cannot be changed.',
      );
    }
    return row;
  }

  Future<TaskReminderDetail> _toDetail(TaskRow row) async {
    final item = await _repositories.items.findById(row.itemId);
    final schedule = row.scheduleId == null
        ? null
        : await _repositories.schedules.findById(row.scheduleId!);
    final (kind, title, description) = switch (row.sourceType) {
      'scheduledMaintenance' => await _maintenanceSource(row),
      'scheduledReminder' => await _reminderSource(row),
      'milestone' => await _milestoneSource(row),
      'manual' => (TaskReminderSourceKind.manual, row.title, null),
      _ => (TaskReminderSourceKind.legacy, row.title, null),
    };
    final sourceCases = await _workCaseRuntime.listBySourceTaskId(row.id);
    return TaskReminderDetail(
      task: _toTask(row),
      itemName: item?.name ?? '未命名生活項目',
      sourceKind: kind,
      sourceTitle: title,
      sourceDescription: description,
      scheduleCycleType: schedule?.cycleType,
      scheduleInterval: schedule?.interval,
      scheduleAnchorPolicy: schedule?.anchorPolicy,
      scheduleStatus: schedule?.status,
      hasOpenWorkCase: sourceCases.any((workCase) => workCase.isOpen),
    );
  }

  Future<(TaskReminderSourceKind, String, String?)> _maintenanceSource(
    TaskRow row,
  ) async {
    final id = row.maintenancePlanId;
    final plan = id == null
        ? null
        : await _repositories.maintenancePlans.findById(id);
    return (
      TaskReminderSourceKind.maintenancePlan,
      plan?.title ?? row.title,
      plan?.description,
    );
  }

  Future<(TaskReminderSourceKind, String, String?)> _reminderSource(
    TaskRow row,
  ) async {
    final id = row.generalReminderId;
    final reminder = id == null
        ? null
        : await _repositories.generalReminders.findById(id);
    return (
      TaskReminderSourceKind.generalReminder,
      reminder?.title ?? row.title,
      reminder?.description,
    );
  }

  Future<(TaskReminderSourceKind, String, String?)> _milestoneSource(
    TaskRow row,
  ) async {
    final id = row.milestoneId;
    final milestone = id == null
        ? null
        : await _repositories.milestones.findById(id);
    return (
      TaskReminderSourceKind.milestone,
      milestone?.title ?? row.title,
      milestone?.description,
    );
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

String _activeStatus(DateTime dueDate, DateTime now) =>
    _dateOnly(dueDate).isBefore(_dateOnly(now))
    ? TaskStatus.overdue.name
    : TaskStatus.pending.name;

DateTime _dateOnly(DateTime value) =>
    DateTime(value.year, value.month, value.day);

Task _toTask(TaskRow row) {
  final status = TaskStatus.values.byName(row.status);
  return Task(
    id: row.id,
    itemId: row.itemId,
    cardId: row.legacyCardId ?? '',
    scheduleId: row.scheduleId ?? '',
    title: row.title,
    dueDate: row.dueDate,
    status: status,
    completedAt: row.completedAt,
    postponedAt: row.postponedAt,
    overdue: status == TaskStatus.overdue,
  );
}
