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
    final existingKeys = {
      for (final task in existingTasks) (task.scheduleId, task.dueDate),
    };

    for (final schedule in schedules) {
      final dueDate = _dateOnly(schedule.nextDueDate);
      if (schedule.status != ScheduleStatus.active ||
          dueDate.isAfter(todayDate)) {
        continue;
      }

      final taskKey = (schedule.id, schedule.nextDueDate);
      if (existingKeys.contains(taskKey)) {
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
      existingKeys.add(taskKey);
    }

    return generatedTasks;
  }

  DateTime _dateOnly(DateTime date) {
    final local = date.toLocal();
    return DateTime(local.year, local.month, local.day);
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
