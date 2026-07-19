import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../models/legacy_drift_import_report.dart';
import '../repositories/drift/drift_item_read_repository.dart';
import '../repositories/drift/drift_schedule_runtime_repository.dart';
import '../repositories/drift/drift_schema_v2_repositories.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/item_read_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_local_repository.dart';
import '../services/local_data_backup_service.dart';
import '../services/local_data_integrity_service.dart';
import '../services/legacy_drift_import_service.dart';
import '../services/local_storage_service.dart';
import '../services/maintenance_task_service.dart';

/// Owns the process-wide runtime dependencies.
///
/// Legacy repositories remain available only for roles that have not completed
/// a controlled cutover. Item reads switch to Drift after verified import.
abstract interface class AppRuntimeDependencies {
  ItemReadRepository get itemReadRepository;
  ItemLocalRepository get itemRepository;
  MaintenanceRecordLocalRepository get maintenanceRecordRepository;
  ScheduleRepository get scheduleRepository;
  DriftMaintenancePlanRepository? get maintenancePlanRepository;
  DriftGeneralReminderRepository? get generalReminderRepository;
  DriftMilestoneRepository? get milestoneRepository;
  TaskLocalRepository get taskRepository;
  LocalDataBackupService get localDataBackupService;
  LocalDataIntegrityService get localDataIntegrityService;
  MaintenanceTaskService get maintenanceTaskService;
  bool get legacyWritesEnabled;
  bool get usesDriftPlanning;
}

class LegacyRuntimeDependencies implements AppRuntimeDependencies {
  LegacyRuntimeDependencies(LocalStorageService legacyStorage)
    : _legacyStorage = legacyStorage,
      itemRepository = ItemLocalRepository(legacyStorage),
      maintenanceRecordRepository = MaintenanceRecordLocalRepository(
        legacyStorage,
      ),
      scheduleRepository = ScheduleLocalRepository(legacyStorage),
      taskRepository = TaskLocalRepository(legacyStorage),
      localDataBackupService = LocalDataBackupService(legacyStorage),
      localDataIntegrityService = LocalDataIntegrityService.instance,
      maintenanceTaskService = MaintenanceTaskService();

  final LocalStorageService _legacyStorage;

  @override
  ItemReadRepository get itemReadRepository => itemRepository;
  @override
  final ItemLocalRepository itemRepository;
  @override
  final MaintenanceRecordLocalRepository maintenanceRecordRepository;
  @override
  final ScheduleLocalRepository scheduleRepository;
  @override
  DriftMaintenancePlanRepository? get maintenancePlanRepository => null;
  @override
  DriftGeneralReminderRepository? get generalReminderRepository => null;
  @override
  DriftMilestoneRepository? get milestoneRepository => null;
  @override
  final TaskLocalRepository taskRepository;
  @override
  final LocalDataBackupService localDataBackupService;
  @override
  final LocalDataIntegrityService localDataIntegrityService;
  @override
  final MaintenanceTaskService maintenanceTaskService;
  @override
  bool get legacyWritesEnabled => _legacyStorage.writesEnabled;
  @override
  bool get usesDriftPlanning => false;
}

enum RuntimeDataMode { legacy, driftItemRead, driftPlanning }

class RuntimeInitializationResult {
  const RuntimeInitializationResult({required this.mode, this.importReport});

  final RuntimeDataMode mode;
  final LegacyDriftImportReport? importReport;

  bool get usesDriftItemRead => mode != RuntimeDataMode.legacy;

  bool get usesDriftPlanning => mode == RuntimeDataMode.driftPlanning;
}

class AppCompositionRoot implements AppRuntimeDependencies {
  AppCompositionRoot({
    required this.database,
    required LocalStorageService legacyStorage,
    this.ownsDatabase = false,
  }) : driftRepositories = DriftSchemaV2Repositories(database),
       _legacyStorage = legacyStorage,
       _runtime = LegacyRuntimeDependencies(legacyStorage) {
    _itemReadRepository = _runtime.itemRepository;
    _scheduleRepository = _runtime.scheduleRepository;
  }

  factory AppCompositionRoot.production() => AppCompositionRoot(
    database: AppDatabase.defaults(),
    legacyStorage: LocalStorageService(),
    ownsDatabase: true,
  );

  final AppDatabase database;
  final DriftSchemaV2Repositories driftRepositories;
  final LocalStorageService _legacyStorage;
  final LegacyRuntimeDependencies _runtime;
  final bool ownsDatabase;
  late ItemReadRepository _itemReadRepository;
  late ScheduleRepository _scheduleRepository;
  Future<RuntimeInitializationResult>? _initialization;

  Future<RuntimeInitializationResult> initialize() =>
      _initialization ??= _initialize();

  Future<RuntimeInitializationResult> _initialize() async {
    await localDataBackupService.createPreMigrationBackups();
    await Future.wait<void>([
      itemRepository.loadItems().then((_) {}),
      scheduleRepository.loadSchedules().then((_) {}),
      taskRepository.loadTasks().then((_) {}),
      maintenanceRecordRepository.loadRecords().then((_) {}),
    ]);
    if (localDataIntegrityService.hasIssues) {
      return const RuntimeInitializationResult(mode: RuntimeDataMode.legacy);
    }

    _legacyStorage.disableWrites();
    try {
      final report =
          await LegacyDriftImportService(
            database: database,
            source: SharedPreferencesLegacyImportSource(_legacyStorage),
          ).execute(
            sourceWritesAreDisabled: true,
            allowVerifiedPlanningMutations: true,
          );
      _itemReadRepository = DriftItemReadRepository(driftRepositories);
      _scheduleRepository = DriftScheduleRuntimeRepository(
        database: database,
        repositories: driftRepositories,
      );
      return RuntimeInitializationResult(
        mode: RuntimeDataMode.driftPlanning,
        importReport: report,
      );
    } on LegacyDriftImportException catch (error) {
      _legacyStorage.enableWrites();
      _itemReadRepository = _runtime.itemRepository;
      _scheduleRepository = _runtime.scheduleRepository;
      return RuntimeInitializationResult(
        mode: RuntimeDataMode.legacy,
        importReport: error.report,
      );
    } catch (_) {
      _legacyStorage.enableWrites();
      _itemReadRepository = _runtime.itemRepository;
      _scheduleRepository = _runtime.scheduleRepository;
      return const RuntimeInitializationResult(mode: RuntimeDataMode.legacy);
    }
  }

  @override
  ItemReadRepository get itemReadRepository => _itemReadRepository;
  @override
  ItemLocalRepository get itemRepository => _runtime.itemRepository;
  @override
  MaintenanceRecordLocalRepository get maintenanceRecordRepository =>
      _runtime.maintenanceRecordRepository;
  @override
  ScheduleRepository get scheduleRepository => _scheduleRepository;
  @override
  DriftMaintenancePlanRepository? get maintenancePlanRepository =>
      usesDriftPlanning ? driftRepositories.maintenancePlans : null;
  @override
  DriftGeneralReminderRepository? get generalReminderRepository =>
      usesDriftPlanning ? driftRepositories.generalReminders : null;
  @override
  DriftMilestoneRepository? get milestoneRepository =>
      usesDriftPlanning ? driftRepositories.milestones : null;
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
  @override
  bool get legacyWritesEnabled => _legacyStorage.writesEnabled;
  @override
  bool get usesDriftPlanning =>
      _scheduleRepository is DriftScheduleRuntimeRepository;

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
