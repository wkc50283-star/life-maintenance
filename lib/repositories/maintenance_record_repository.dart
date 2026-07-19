import '../models/maintenance_record.dart';

/// Formal access to completed facts that do not require a case process.
///
/// Events needing progress updates or formal closure must use WorkCase and
/// WorkCaseClosure instead. This contract intentionally exposes no generic
/// update/delete API and never writes the legacy SharedPreferences source.
abstract interface class MaintenanceRecordRepository {
  Future<MaintenanceRecord?> findById(String id);

  Future<List<MaintenanceRecord>> listForItem(String itemId);

  /// Records a simple, manually confirmed fact with no Task or case process.
  Future<void> createSimpleRecord(MaintenanceRecord record);

  /// Completes one reminder and creates its simple completion fact atomically.
  Future<void> completeSimpleTask(MaintenanceRecord record);
}
