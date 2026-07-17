import 'dart:convert';

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

  Future<void> saveRecords(List<MaintenanceRecord> records) async {
    LocalDataIntegrityService.instance.ensureWritesAllowed();
    final encodedRecords = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedRecords);
  }
}
