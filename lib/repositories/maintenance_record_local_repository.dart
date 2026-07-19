import 'dart:convert';

import '../models/maintenance_record.dart';
import 'maintenance_record_repository.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';

class MaintenanceRecordLocalRepository implements MaintenanceRecordRepository {
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

  @override
  Future<MaintenanceRecord?> findById(String id) async {
    for (final record in await loadRecords()) {
      if (record.id == id) return record;
    }
    return null;
  }

  @override
  Future<List<MaintenanceRecord>> listAll() => loadRecords();

  @override
  Future<List<MaintenanceRecord>> listForItem(String itemId) async =>
      (await loadRecords())
          .where((record) => record.itemId == itemId)
          .toList(growable: false);

  Future<void> saveRecords(List<MaintenanceRecord> records) async {
    LocalDataIntegrityService.instance.ensureWritesAllowed();
    final encodedRecords = jsonEncode(
      records.map((record) => record.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedRecords);
  }

  @override
  Future<void> createSimpleRecord(MaintenanceRecord record) async {
    await saveRecords([...await loadRecords(), record]);
  }

  @override
  Future<void> completeSimpleTask(MaintenanceRecord record) {
    throw UnsupportedError(
      'Legacy recovery cannot complete a Task and MaintenanceRecord atomically.',
    );
  }
}
