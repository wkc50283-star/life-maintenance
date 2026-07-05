import 'dart:convert';

import '../models/maintenance_record.dart';
import '../services/local_storage_service.dart';

class MaintenanceRecordLocalRepository {
  static const String _storageKey = 'maintenance_records';

  MaintenanceRecordLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<MaintenanceRecord>> loadRecords() async {
    final rawRecords = await _storageService.readString(_storageKey);
    if (rawRecords == null) {
      return <MaintenanceRecord>[];
    }

    final decodedRecords = jsonDecode(rawRecords) as List<dynamic>;
    return decodedRecords
        .map(
          (record) =>
              MaintenanceRecord.fromJson(record as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveRecords(List<MaintenanceRecord> records) async {
    final encodedRecords = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedRecords);
  }
}
