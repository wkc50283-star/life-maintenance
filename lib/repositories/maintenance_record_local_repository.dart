import '../models/maintenance_record.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';

class MaintenanceRecordLocalRepository {
  static const String _storageKey = 'maintenance_records';

  MaintenanceRecordLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<MaintenanceRecord>> loadRecords() async {
    final rawRecords = await _storageService.readString(_storageKey);
    if (rawRecords == null) {
      LocalDataIntegrityService.instance.clearIssue(_storageKey);
      return <MaintenanceRecord>[];
    }

    return LocalDataIntegrityService.instance.decodeList<MaintenanceRecord>(
      storageKey: _storageKey,
      rawValue: rawRecords,
      decodeEntry: MaintenanceRecord.fromJson,
    );
  }

  Future<MaintenanceRecord?> findById(String id) async {
    for (final record in await loadRecords()) {
      if (record.id == id) return record;
    }
    return null;
  }

  Future<List<MaintenanceRecord>> listAll() => loadRecords();

  Future<List<MaintenanceRecord>> listForItem(String itemId) async =>
      (await loadRecords())
          .where((record) => record.itemId == itemId)
          .toList(growable: false);
}
