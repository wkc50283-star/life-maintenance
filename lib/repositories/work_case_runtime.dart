import '../models/work_case.dart';
import '../models/work_case_closure.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';

/// Formal Runtime boundary for a case from opening through closure.
///
/// Task remains a reminder and History remains a projection; neither is
/// mutated by this contract.
abstract interface class WorkCaseRuntime {
  Future<WorkCase?> findCaseById(String id);

  Future<List<WorkCase>> listCasesForItem(String itemId);

  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId);

  Future<WorkCaseClosure?> findClosureForCase(String workCaseId);

  Future<WorkCase> createFromTask({
    required String taskId,
    required WorkCase workCase,
    WorkCaseUpdate? initialUpdate,
  });

  Future<void> createManual(WorkCase workCase, {WorkCaseUpdate? initialUpdate});

  Future<void> saveOpenCase(WorkCase workCase);

  Future<void> appendUpdate(
    WorkCaseUpdate update, {
    WorkCaseStatus? status,
    DateTime? statusUpdatedAt,
  });

  Future<void> updateStatus(
    String workCaseId,
    WorkCaseStatus status,
    DateTime updatedAt,
  );

  Future<void> close(WorkCaseClosure closure);

  Future<void> cancel(
    WorkCaseClosure closure, {
    required String cancellationReason,
  });
}
