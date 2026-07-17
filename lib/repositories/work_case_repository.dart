import '../models/work_case.dart';
import '../models/work_case_update.dart';

abstract interface class WorkCaseRepository {
  Future<WorkCase?> findCaseById(String id);

  Future<List<WorkCase>> listCasesForItem(String itemId);

  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId);

  Future<void> saveCase(WorkCase workCase);

  Future<void> appendUpdate(WorkCaseUpdate update);

  Future<void> createCaseWithInitialUpdate(
    WorkCase workCase,
    WorkCaseUpdate initialUpdate,
  );
}
