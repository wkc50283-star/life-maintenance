import '../models/enums.dart';
import '../models/schedule.dart';
import '../models/task.dart';

class MaintenanceTaskService {
  List<Task> generateDueTasks({
    required List<Schedule> schedules,
    required List<Task> existingTasks,
    required DateTime today,
  }) {
    final generatedTasks = <Task>[];
    final todayDate = _dateOnly(today);

    for (final schedule in schedules) {
      final dueDate = _dateOnly(schedule.nextDueDate);
      if (schedule.status != ScheduleStatus.active ||
          dueDate.isAfter(todayDate)) {
        continue;
      }

      final hasExistingTask = existingTasks.any(
        (task) =>
            task.scheduleId == schedule.id &&
            (task.dueDate == schedule.nextDueDate ||
                (_isMutable(task.status) &&
                    !task.dueDate.isBefore(schedule.nextDueDate))),
      );

      if (hasExistingTask) {
        continue;
      }

      final overdue = dueDate.isBefore(todayDate);

      generatedTasks.add(
        Task(
          id: '${schedule.id}-${schedule.nextDueDate.toIso8601String()}',
          itemId: schedule.itemId,
          cardId: schedule.cardId,
          scheduleId: schedule.id,
          title: _taskTitleFor(schedule),
          dueDate: schedule.nextDueDate,
          status: overdue ? TaskStatus.overdue : TaskStatus.pending,
          overdue: overdue,
        ),
      );
    }

    return generatedTasks;
  }

  bool _isMutable(TaskStatus status) =>
      status != TaskStatus.completed && status != TaskStatus.canceled;

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  String _taskTitleFor(Schedule schedule) {
    final title = schedule.title?.trim();
    if (title != null && title.isNotEmpty) {
      return title;
    }

    if (schedule.cardId == 'manual-expiry-reminder') {
      return '提醒事項';
    }

    return '保養提醒';
  }
}
