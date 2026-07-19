import '../models/task.dart';
import '../models/work_case.dart';

enum TaskReminderSourceKind {
  maintenancePlan,
  generalReminder,
  milestone,
  manual,
  legacy,
}

class TaskReminderDetail {
  const TaskReminderDetail({
    required this.task,
    required this.itemName,
    required this.sourceKind,
    required this.sourceTitle,
    this.sourceDescription,
    this.scheduleCycleType,
    this.scheduleInterval,
    this.scheduleAnchorPolicy,
  });

  final Task task;
  final String itemName;
  final TaskReminderSourceKind sourceKind;
  final String sourceTitle;
  final String? sourceDescription;
  final String? scheduleCycleType;
  final int? scheduleInterval;
  final String? scheduleAnchorPolicy;

  bool get canStartWorkCase =>
      sourceKind == TaskReminderSourceKind.maintenancePlan ||
      sourceKind == TaskReminderSourceKind.generalReminder ||
      sourceKind == TaskReminderSourceKind.milestone;
}

/// Formal Task interaction boundary.
///
/// A Task remains a reminder instance. Starting work creates a WorkCase through
/// the existing case runtime and never completes the Task or writes Closure or
/// History data.
abstract interface class TaskReminderRuntime {
  Future<List<TaskReminderDetail>> loadReminders();

  Future<TaskReminderDetail?> findReminder(String taskId);

  Future<void> pause(String taskId, DateTime changedAt);

  Future<void> resume(String taskId, DateTime changedAt);

  Future<void> reschedule(String taskId, DateTime dueDate, DateTime changedAt);

  Future<WorkCase> startWorkCase({
    required String taskId,
    required WorkCase workCase,
  });
}
