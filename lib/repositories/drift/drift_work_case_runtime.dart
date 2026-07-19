import '../../database/app_database.dart';
import '../../models/work_case.dart';
import '../../models/work_case_closure.dart';
import '../../models/work_case_enums.dart';
import '../../models/work_case_update.dart';
import '../repository_constraint_exception.dart';
import '../work_case_closure_repository.dart';
import '../work_case_repository.dart';
import '../work_case_runtime.dart';
import 'drift_schema_v2_repositories.dart';

class DriftWorkCaseRuntime implements WorkCaseRuntime {
  DriftWorkCaseRuntime({
    required AppDatabase database,
    required WorkCaseRepository workCases,
    required WorkCaseClosureRepository closures,
    required DriftTaskRepository tasks,
  }) : _database = database,
       _workCases = workCases,
       _closures = closures,
       _tasks = tasks;

  final AppDatabase _database;
  final WorkCaseRepository _workCases;
  final WorkCaseClosureRepository _closures;
  final DriftTaskRepository _tasks;

  @override
  Future<WorkCase?> findCaseById(String id) => _workCases.findCaseById(id);

  @override
  Future<List<WorkCase>> listCasesForItem(String itemId) =>
      _workCases.listCasesForItem(itemId);

  @override
  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId) =>
      _workCases.listUpdatesForCase(workCaseId);

  @override
  Future<WorkCaseClosure?> findClosureForCase(String workCaseId) =>
      _closures.findForCase(workCaseId);

  @override
  Future<WorkCase> createFromTask({
    required String taskId,
    required WorkCase workCase,
    WorkCaseUpdate? initialUpdate,
  }) async {
    final query = _database.select(_database.tasks)
      ..where((table) => table.id.equals(taskId));
    final task = await query.getSingleOrNull();
    if (task == null) {
      throw RepositoryConstraintException('Task $taskId does not exist.');
    }
    if (task.itemId != workCase.itemId) {
      throw const RepositoryConstraintException(
        'Task and WorkCase must belong to the same Item.',
      );
    }

    final (sourceType, sourceId) = switch (task.sourceType) {
      'scheduledMaintenance' => (WorkCaseSourceType.maintenanceTask, task.id),
      'scheduledReminder' => (
        WorkCaseSourceType.generalReminder,
        task.generalReminderId,
      ),
      'milestone' => (WorkCaseSourceType.milestone, task.milestoneId),
      _ => throw RepositoryConstraintException(
        'Task ${task.id} has no supported formal WorkCase source.',
      ),
    };
    if (sourceId == null) {
      throw RepositoryConstraintException(
        'Task ${task.id} is missing its formal source.',
      );
    }
    final normalized = workCase.copyWith(
      sourceType: sourceType,
      sourceId: sourceId,
    );
    await _create(normalized, initialUpdate);
    return normalized;
  }

  @override
  Future<void> createManual(
    WorkCase workCase, {
    WorkCaseUpdate? initialUpdate,
  }) async {
    if (workCase.sourceType != WorkCaseSourceType.manual ||
        workCase.sourceId != null) {
      throw const RepositoryConstraintException(
        'A manually created WorkCase must use the manual source only.',
      );
    }
    await _create(workCase, initialUpdate);
  }

  Future<void> _create(WorkCase workCase, WorkCaseUpdate? initialUpdate) async {
    if (initialUpdate == null) {
      await _workCases.saveCase(workCase);
      return;
    }
    await _workCases.createCaseWithInitialUpdate(workCase, initialUpdate);
  }

  @override
  Future<void> saveOpenCase(WorkCase workCase) => _workCases.saveCase(workCase);

  @override
  Future<void> appendUpdate(
    WorkCaseUpdate update, {
    WorkCaseStatus? status,
    DateTime? statusUpdatedAt,
  }) async {
    if (status == null && statusUpdatedAt == null) {
      await _workCases.appendUpdate(update);
      return;
    }
    if (status == null || statusUpdatedAt == null) {
      throw const RepositoryConstraintException(
        'Status and statusUpdatedAt must be provided together.',
      );
    }
    await _workCases.appendUpdateAndSetStatus(update, status, statusUpdatedAt);
  }

  @override
  Future<void> updateStatus(
    String workCaseId,
    WorkCaseStatus status,
    DateTime updatedAt,
  ) => _workCases.updateStatus(workCaseId, status, updatedAt);

  @override
  Future<void> close(WorkCaseClosure closure) => _closures.closeCase(closure);

  @override
  Future<void> closeWithFollowUp(
    WorkCaseClosure closure, {
    DateTime? nextReminderDueDate,
  }) async {
    final reminderId = closure.nextReminderTaskId;
    if ((reminderId == null) != (nextReminderDueDate == null)) {
      throw const RepositoryConstraintException(
        'Follow-up reminder ID and due date must be provided together.',
      );
    }
    if (nextReminderDueDate != null &&
        !nextReminderDueDate.isAfter(closure.completedAt)) {
      throw const RepositoryConstraintException(
        'A follow-up reminder must be after the completion date.',
      );
    }

    await _database.transaction(() async {
      if (reminderId != null && nextReminderDueDate != null) {
        final workCase = await _workCases.findCaseById(closure.workCaseId);
        if (workCase == null) {
          throw RepositoryConstraintException(
            'WorkCase ${closure.workCaseId} does not exist.',
          );
        }
        await _tasks.save(
          TaskRow(
            id: reminderId,
            itemId: workCase.itemId,
            sourceType: 'manual',
            title: '後續留意：${workCase.title}',
            dueDate: nextReminderDueDate,
            status: 'pending',
            createdAt: closure.createdAt,
            updatedAt: closure.updatedAt,
          ),
        );
      }
      await _closures.closeCase(closure);
    });
  }

  @override
  Future<void> cancel(
    WorkCaseClosure closure, {
    required String cancellationReason,
  }) => _closures.cancelCase(closure, cancellationReason: cancellationReason);
}
