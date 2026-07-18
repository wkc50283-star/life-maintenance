import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../repositories/drift/drift_schema_v2_repositories.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../repositories/task_local_repository.dart';
import '../services/local_data_backup_service.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';
import '../services/maintenance_task_service.dart';

/// Owns the process-wide runtime dependencies.
///
/// The legacy repositories remain the active runtime data source until a later
/// controlled cutover. Drift repositories are constructed here but are not
/// injected into the current UI in this release.
abstract interface class AppRuntimeDependencies {
  ItemLocalRepository get itemRepository;
  MaintenanceRecordLocalRepository get maintenanceRecordRepository;
  ScheduleLocalRepository get scheduleRepository;
  TaskLocalRepository get taskRepository;
  LocalDataBackupService get localDataBackupService;
  LocalDataIntegrityService get localDataIntegrityService;
  MaintenanceTaskService get maintenanceTaskService;
}

class LegacyRuntimeDependencies implements AppRuntimeDependencies {
  LegacyRuntimeDependencies(LocalStorageService legacyStorage)
    : itemRepository = ItemLocalRepository(legacyStorage),
      maintenanceRecordRepository = MaintenanceRecordLocalRepository(
        legacyStorage,
      ),
      scheduleRepository = ScheduleLocalRepository(legacyStorage),
      taskRepository = TaskLocalRepository(legacyStorage),
      localDataBackupService = LocalDataBackupService(legacyStorage),
      localDataIntegrityService = LocalDataIntegrityService.instance,
      maintenanceTaskService = MaintenanceTaskService();

  @override
  final ItemLocalRepository itemRepository;
  @override
  final MaintenanceRecordLocalRepository maintenanceRecordRepository;
  @override
  final ScheduleLocalRepository scheduleRepository;
  @override
  final TaskLocalRepository taskRepository;
  @override
  final LocalDataBackupService localDataBackupService;
  @override
  final LocalDataIntegrityService localDataIntegrityService;
  @override
  final MaintenanceTaskService maintenanceTaskService;
}

class AppCompositionRoot implements AppRuntimeDependencies {
  AppCompositionRoot({
    required this.database,
    required LocalStorageService legacyStorage,
    this.ownsDatabase = false,
  }) : driftRepositories = DriftSchemaV2Repositories(database),
       _runtime = LegacyRuntimeDependencies(legacyStorage);

  factory AppCompositionRoot.production() => AppCompositionRoot(
    database: AppDatabase.defaults(),
    legacyStorage: LocalStorageService(),
    ownsDatabase: true,
  );

  final AppDatabase database;
  final DriftSchemaV2Repositories driftRepositories;
  final LegacyRuntimeDependencies _runtime;
  final bool ownsDatabase;

  @override
  ItemLocalRepository get itemRepository => _runtime.itemRepository;
  @override
  MaintenanceRecordLocalRepository get maintenanceRecordRepository =>
      _runtime.maintenanceRecordRepository;
  @override
  ScheduleLocalRepository get scheduleRepository => _runtime.scheduleRepository;
  @override
  TaskLocalRepository get taskRepository => _runtime.taskRepository;
  @override
  LocalDataBackupService get localDataBackupService =>
      _runtime.localDataBackupService;
  @override
  LocalDataIntegrityService get localDataIntegrityService =>
      _runtime.localDataIntegrityService;
  @override
  MaintenanceTaskService get maintenanceTaskService =>
      _runtime.maintenanceTaskService;

  Future<void> dispose() async {
    if (ownsDatabase) {
      await database.close();
    }
  }
}

class AppCompositionScope extends InheritedWidget {
  const AppCompositionScope({
    required this.root,
    required super.child,
    super.key,
  });

  final AppRuntimeDependencies root;

  @visibleForTesting
  static AppRuntimeDependencies? testDependencies;

  static AppRuntimeDependencies of(BuildContext context) {
    final scope = context
        .dependOnInheritedWidgetOfExactType<AppCompositionScope>();
    final resolvedRoot = scope?.root ?? testDependencies;
    if (resolvedRoot == null) {
      throw StateError('AppCompositionScope is missing above this widget.');
    }
    return resolvedRoot;
  }

  @override
  bool updateShouldNotify(AppCompositionScope oldWidget) =>
      !identical(root, oldWidget.root);
}
