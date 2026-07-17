import 'dart:convert';

import '../database/app_database.dart';
import '../models/migration_readiness_report.dart';
import 'local_data_backup_service.dart';
import 'local_storage_service.dart';

class MigrationReadinessService {
  const MigrationReadinessService({
    required LocalStorageService storageService,
    required AppDatabase database,
  }) : _storageService = storageService,
       _database = database;

  final LocalStorageService _storageService;
  final AppDatabase _database;

  Future<MigrationReadinessReport> inspect() async {
    final datasets = <MigrationDatasetSnapshot>[];

    for (final entry in LocalDataBackupService.backupKeys.entries) {
      final sourceRaw = await _storageService.readString(entry.key);
      final backupRaw = await _storageService.readString(entry.value);
      final sourceList = _decodeList(sourceRaw);
      final backupList = _decodeList(backupRaw);

      datasets.add(
        MigrationDatasetSnapshot(
          sourceKey: entry.key,
          backupKey: entry.value,
          sourceExists: sourceRaw != null,
          backupExists: backupRaw != null,
          sourceIsValidList: sourceRaw == null || sourceList != null,
          backupIsValidList: backupRaw == null || backupList != null,
          sourceCount: sourceList?.length,
          backupCount: backupList?.length,
          rawValuesMatch: sourceRaw == null || backupRaw == null
              ? null
              : sourceRaw == backupRaw,
        ),
      );
    }

    final workCaseCount = (await _database.select(_database.workCases).get()).length;
    final updateCount =
        (await _database.select(_database.workCaseUpdates).get()).length;

    return MigrationReadinessReport(
      datasets: List<MigrationDatasetSnapshot>.unmodifiable(datasets),
      driftWorkCaseCount: workCaseCount,
      driftWorkCaseUpdateCount: updateCount,
    );
  }

  List<dynamic>? _decodeList(String? rawValue) {
    if (rawValue == null) {
      return null;
    }

    try {
      final decoded = jsonDecode(rawValue);
      return decoded is List ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
