import 'local_data_integrity_service.dart';
import 'local_storage_service.dart';

class LocalDataBackupService {
  LocalDataBackupService(this._storageService);

  static const int backupVersion = 1;

  static const Map<String, String> backupKeys = <String, String>{
    'items': 'backup_v1_items',
    'schedules': 'backup_v1_schedules',
    'tasks': 'backup_v1_tasks',
    'maintenance_records': 'backup_v1_maintenance_records',
  };

  final LocalStorageService _storageService;

  Future<void> createPreMigrationBackups() async {
    for (final entry in backupKeys.entries) {
      await _backupIfAbsent(sourceKey: entry.key, backupKey: entry.value);
    }
  }

  Future<void> _backupIfAbsent({
    required String sourceKey,
    required String backupKey,
  }) async {
    final issueKey = 'backup:$sourceKey';

    try {
      final existingBackup = await _storageService.readString(backupKey);
      if (existingBackup != null) {
        LocalDataIntegrityService.instance.clearIssue(issueKey);
        return;
      }

      final rawValue = await _storageService.readString(sourceKey);
      if (rawValue == null) {
        LocalDataIntegrityService.instance.clearIssue(issueKey);
        return;
      }

      await _storageService.writeBackupIfAbsent(backupKey, rawValue);
      LocalDataIntegrityService.instance.clearIssue(issueKey);
    } catch (_) {
      LocalDataIntegrityService.instance.reportIssue(
        storageKey: issueKey,
        message: '無法建立本機資料安全備份',
        invalidEntryCount: 1,
      );
    }
  }
}
