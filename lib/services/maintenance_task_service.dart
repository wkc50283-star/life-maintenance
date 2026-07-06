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
      if (!schedule.enabled || dueDate.isAfter(todayDate)) {
        continue;
      }

      final hasExistingTask = existingTasks.any(
        (task) =>
            task.scheduleId == schedule.id &&
            _isSameDay(task.dueDate, schedule.nextDueDate),
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
          title: '保養提醒',
          dueDate: schedule.nextDueDate,
          status: overdue ? TaskStatus.overdue : TaskStatus.pending,
          overdue: overdue,
        ),
      );
    }

    return generatedTasks;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  bool _isSameDay(DateTime firstDate, DateTime secondDate) {
    return _dateOnly(firstDate) == _dateOnly(secondDate);
  }
}
