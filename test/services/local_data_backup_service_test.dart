import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';

void main() {
  final integrityService = LocalDataIntegrityService.instance;

  setUp(integrityService.resetForTesting);
  tearDown(integrityService.resetForTesting);

  test('copies each raw value exactly without parsing it', () async {
    final storage = _FakeLocalStorageService();
    const malformedRaw = '{not-json';
    storage.values['items'] = malformedRaw;

    await LocalDataBackupService(storage).createPreMigrationBackups();

    expect(storage.values['backup_v1_items'], malformedRaw);
    expect(integrityService.hasIssues, isFalse);
  });

  test('never overwrites an existing backup', () async {
    final storage = _FakeLocalStorageService();
    storage.values['items'] = 'new-current-value';
    storage.values['backup_v1_items'] = 'original-backup';

    await LocalDataBackupService(storage).createPreMigrationBackups();

    expect(storage.values['backup_v1_items'], 'original-backup');
  });

  test('does not create backup data when a source does not exist', () async {
    final storage = _FakeLocalStorageService();

    await LocalDataBackupService(storage).createPreMigrationBackups();

    for (final backupKey in LocalDataBackupService.backupKeys.values) {
      expect(storage.values.containsKey(backupKey), isFalse);
    }
  });

  test('backup failure is reported without changing the source', () async {
    final storage = _FakeLocalStorageService();
    storage.values['items'] = 'raw-items';
    storage.failingSaveKeys.add('backup_v1_items');

    await LocalDataBackupService(storage).createPreMigrationBackups();

    expect(integrityService.hasIssueForKey('backup:items'), isTrue);
    expect(storage.values['items'], 'raw-items');
    expect(storage.values['backup_v1_items'], isNull);
  });
}

class _FakeLocalStorageService extends LocalStorageService {
  final Map<String, String> values = <String, String>{};
  final Set<String> failingSaveKeys = <String>{};

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> writeBackupIfAbsent(String key, String value) async {
    if (failingSaveKeys.contains(key)) {
      throw StateError('Simulated backup failure.');
    }

    values.putIfAbsent(key, () => value);
  }
}
