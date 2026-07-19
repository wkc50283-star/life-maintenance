import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/services/legacy_drift_import_service.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(SharedPreferences.resetStatic);

  test('formal runtime has no Legacy persistence dependency', () {
    final files = <File>[
      File('lib/main.dart'),
      ..._dartFiles('lib/app'),
      ..._dartFiles('lib/screens'),
      ..._dartFiles('lib/widgets'),
    ];
    const forbidden = [
      "package:shared_preferences/shared_preferences.dart",
      "services/local_storage_service.dart",
      'LocalStorageService',
      'LocalDataBackupService',
      'LocalDataIntegrityService',
      'LegacyRuntimeDependencies',
      'ItemLocalRepository',
      'ScheduleLocalRepository',
      'TaskLocalRepository',
      'MaintenanceRecordLocalRepository',
    ];
    final violations = <String>[];

    for (final file in files) {
      final source = file.readAsStringSync();
      for (final pattern in forbidden) {
        if (source.contains(pattern)) {
          violations.add('${_relative(file.path)}: $pattern');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('legacy production helpers expose no business writer API', () {
    final storageSource = File(
      'lib/services/local_storage_service.dart',
    ).readAsStringSync();
    final repositorySources = [
      'lib/repositories/item_local_repository.dart',
      'lib/repositories/schedule_local_repository.dart',
      'lib/repositories/task_local_repository.dart',
      'lib/repositories/maintenance_record_local_repository.dart',
    ].map((path) => File(path).readAsStringSync()).join('\n');

    for (final forbidden in const [
      'saveString(',
      'remove(',
      'enableWrites(',
      'disableWrites(',
    ]) {
      expect(storageSource, isNot(contains(forbidden)));
    }
    for (final forbidden in const [
      'saveItems(',
      'saveSchedules(',
      'saveTasks(',
      'saveRecords(',
      'createSimpleRecord(',
      'completeSimpleTask(',
    ]) {
      expect(repositorySources, isNot(contains(forbidden)));
    }
  });

  test('formal root starts on Drift without touching legacy keys', () async {
    SharedPreferences.setMockInitialValues({
      'items': 'legacy-items',
      'backup_v1_items': 'immutable-items',
    });
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);

    final initialized = await root.initialize();

    expect(initialized.mode, RuntimeDataMode.driftMaintenanceRecords);
    expect(root.formalWritesEnabled, isTrue);
    expect(root.usesDriftPlanning, isTrue);
    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('items'), 'legacy-items');
    expect(preferences.getString('backup_v1_items'), 'immutable-items');
    await database.close();
  });

  test('backup writer is restricted to immutable backup_v1 keys', () async {
    SharedPreferences.setMockInitialValues({
      'items': 'legacy-items',
      'backup_v1_items': 'original-backup',
    });
    final storage = LocalStorageService();

    await expectLater(
      storage.writeBackupIfAbsent('items', 'replacement'),
      throwsArgumentError,
    );
    await storage.writeBackupIfAbsent('backup_v1_items', 'replacement');

    final preferences = await SharedPreferences.getInstance();
    expect(preferences.getString('items'), 'legacy-items');
    expect(preferences.getString('backup_v1_items'), 'original-backup');
  });

  test('read-only import and backup recovery tools remain available', () async {
    SharedPreferences.setMockInitialValues({
      'items': '[]',
      'schedules': '[]',
      'tasks': '[]',
      'maintenance_records': '[]',
    });
    final storage = LocalStorageService();
    await LocalDataBackupService(storage).createPreMigrationBackups();
    final source = SharedPreferencesLegacyImportSource(storage);

    expect(await source.readString('items'), '[]');
    expect(await source.readString('backup_v1_items'), '[]');

    final database = AppDatabase(NativeDatabase.memory());
    final report = await LegacyDriftImportService(
      database: database,
      source: source,
    ).dryRun();
    expect(report.isBlocked, isFalse);
    await database.close();
  });
}

List<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);

String _relative(String path) =>
    path.replaceFirst('${Directory.current.path}/', '');
