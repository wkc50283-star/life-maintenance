import '../models/work_case_closure.dart';

abstract interface class WorkCaseClosureRepository {
  Future<WorkCaseClosure?> findForCase(String workCaseId);

  Future<void> closeCase(WorkCaseClosure closure);

  Future<void> cancelCase(
    WorkCaseClosure closure, {
    required String cancellationReason,
  });
}
