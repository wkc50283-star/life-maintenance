import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/task.dart';
import '../repository_constraint_exception.dart';
import '../task_repository.dart';
import 'drift_schema_v2_repositories.dart';

/// Formal Runtime adapter for Schema v2 Task reminder instances.
///
/// Generated tasks copy their source from the referenced Schedule. The legacy
/// SharedPreferences store is never read or written here.
class DriftTaskRuntimeRepository implements TaskRepository {
  DriftTaskRuntimeRepository({
    required AppDatabase database,
    required DriftSchemaV2Repositories repositories,
  }) : _database = database,
       _repositories = repositories;

  final AppDatabase _database;
  final DriftSchemaV2Repositories _repositories;

  @override
  Future<List<Task>> loadTasks() async {
    final rows = await _repositories.tasks.listAll();
    return rows.map(_toRuntimeModel).toList(growable: false);
  }

  @override
  Future<void> saveGeneratedTasks(List<Task> tasks) async {
    final keys = <(String, DateTime)>{};
    for (final task in tasks) {
      if (task.scheduleId.isEmpty) {
        throw const RepositoryConstraintException(
          'A generated Task requires a Schedule source.',
        );
      }
      if (!keys.add((task.scheduleId, task.dueDate))) {
        throw const RepositoryConstraintException(
          'Generated Tasks must have unique scheduleId and dueDate values.',
        );
      }
    }

    await _database.transaction(() async {
      final existing = await _repositories.tasks.listAll();
      final existingKeys = {
        for (final row in existing)
          if (row.scheduleId != null) (row.scheduleId!, row.dueDate),
      };
      for (final task in tasks) {
        if (existingKeys.contains((task.scheduleId, task.dueDate))) {
          continue;
        }
        await _repositories.tasks.save(await _toFormalRow(task));
        existingKeys.add((task.scheduleId, task.dueDate));
      }
    });
  }

  Future<TaskRow> _toFormalRow(Task task) async {
    final schedule = await _repositories.schedules.findById(task.scheduleId);
    if (schedule == null) {
      throw RepositoryConstraintException(
        'Task ${task.id} references a missing Schedule.',
      );
    }
    if (schedule.itemId != task.itemId) {
      throw const RepositoryConstraintException(
        'Task and Schedule must belong to the same Item.',
      );
    }

    final sourceType = switch (schedule.sourceType) {
      'maintenancePlan' => 'scheduledMaintenance',
      'generalReminder' => 'scheduledReminder',
      'milestone' => 'milestone',
      _ => throw RepositoryConstraintException(
        'Schedule ${schedule.id} cannot generate a Task.',
      ),
    };
    final status = task.status == TaskStatus.overdue
        ? TaskStatus.overdue.name
        : TaskStatus.pending.name;

    return TaskRow(
      id: task.id,
      itemId: task.itemId,
      sourceType: sourceType,
      scheduleId: schedule.id,
      maintenancePlanId: schedule.maintenancePlanId,
      generalReminderId: schedule.generalReminderId,
      milestoneId: schedule.milestoneId,
      legacyCardId: task.cardId.isEmpty ? schedule.legacyCardId : task.cardId,
      title: task.title,
      dueDate: task.dueDate,
      status: status,
      createdAt: task.dueDate,
      updatedAt: task.dueDate,
    );
  }

  Task _toRuntimeModel(TaskRow row) {
    final status = _taskStatus(row.status);
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
}

TaskStatus _taskStatus(String value) {
  try {
    return TaskStatus.values.byName(value);
  } catch (_) {
    throw RepositoryConstraintException('Unsupported Task status $value.');
  }
}
