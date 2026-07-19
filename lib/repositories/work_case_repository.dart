import '../models/work_case.dart';
import '../models/work_case_update.dart';
import '../models/work_case_enums.dart';

abstract interface class WorkCaseRepository {
  Future<WorkCase?> findCaseById(String id);

  Future<List<WorkCase>> listCasesForItem(String itemId);

  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId);

  Future<void> saveCase(WorkCase workCase);

  Future<void> appendUpdate(WorkCaseUpdate update);

  Future<void> updateStatus(
    String workCaseId,
    WorkCaseStatus status,
    DateTime updatedAt,
  );

  Future<void> appendUpdateAndSetStatus(
    WorkCaseUpdate update,
    WorkCaseStatus status,
    DateTime updatedAt,
  );

  Future<void> createCaseWithInitialUpdate(
    WorkCase workCase,
    WorkCaseUpdate initialUpdate,
  );
}
