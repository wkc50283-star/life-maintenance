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

    for (final schedule in schedules) {
      if (!schedule.enabled || schedule.nextDueDate.isAfter(today)) {
        continue;
      }

      final hasExistingTask = existingTasks.any(
        (task) =>
            task.scheduleId == schedule.id &&
            task.dueDate.isAtSameMomentAs(schedule.nextDueDate),
      );

      if (hasExistingTask) {
        continue;
      }

      final overdue = schedule.nextDueDate.isBefore(today);

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
}
