import '../models/history_projection.dart';

/// Read-only History query. There is deliberately no save or delete method.
abstract interface class HistoryProjectionRepository {
  Future<HistoryProjection> projectForItem(String itemId);
  Future<List<WorkCaseHistoryEntry>> projectGlobalWorkCaseEntries();
  Future<List<FutureMatterCreatedHistoryEntry>>
  projectGlobalFutureMatterCreatedEntries();
  Future<List<FutureMatterChangeHistoryEntry>>
  projectGlobalFutureMatterChangeEntries();
  Future<List<FutureMatterCompletedHistoryEntry>>
  projectGlobalFutureMatterCompletedEntries();
}
