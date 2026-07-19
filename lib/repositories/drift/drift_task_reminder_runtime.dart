import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
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
    return TaskReminderDetail(
      task: _toTask(row),
      itemName: item?.name ?? '未命名生活項目',
      sourceKind: kind,
      sourceTitle: title,
      sourceDescription: description,
      scheduleCycleType: schedule?.cycleType,
      scheduleInterval: schedule?.interval,
      scheduleAnchorPolicy: schedule?.anchorPolicy,
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
