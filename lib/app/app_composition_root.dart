import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../models/legacy_drift_import_report.dart';
import '../repositories/drift/drift_item_read_repository.dart';
import '../repositories/drift/drift_attachment_runtime.dart';
import '../repositories/drift/drift_history_projection_repository.dart';
import '../repositories/drift/drift_maintenance_record_repository.dart';
import '../repositories/drift/drift_safe_read_only_runtime.dart';
import '../repositories/drift/drift_schedule_runtime_repository.dart';
import '../repositories/drift/drift_schema_v2_repositories.dart';
import '../repositories/drift/drift_task_runtime_repository.dart';
import '../repositories/drift/drift_work_case_runtime.dart';
import '../repositories/item_local_repository.dart';
import '../repositories/attachment_runtime.dart';
import '../repositories/history_projection_repository.dart';
import '../repositories/item_read_repository.dart';
import '../repositories/maintenance_record_local_repository.dart';
import '../repositories/maintenance_record_repository.dart';
import '../repositories/schedule_local_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_local_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/work_case_runtime.dart';
import '../services/local_data_backup_service.dart';
import '../services/local_data_integrity_service.dart';
import '../services/legacy_drift_import_service.dart';
import '../services/local_storage_service.dart';
import '../services/maintenance_task_service.dart';

/// Owns the process-wide runtime dependencies.
///
/// Production reads and writes use Drift after admission. Legacy repositories
/// remain only for preflight parsing, immutable backup, and test injection; an
/// admission failure activates Drift read-only mode instead of a legacy writer.
abstract interface class AppRuntimeDependencies {
  ItemReadRepository get itemReadRepository;
  ItemLocalRepository get itemRepository;
  MaintenanceRecordRepository get maintenanceRecordRepository;
  ScheduleRepository get scheduleRepository;
  DriftMaintenancePlanRepository? get maintenancePlanRepository;
  DriftGeneralReminderRepository? get generalReminderRepository;
  DriftMilestoneRepository? get milestoneRepository;
  TaskRepository get taskRepository;
  WorkCaseRuntime? get workCaseRuntime;
  HistoryProjectionRepository? get historyProjectionRepository;
  AttachmentRuntime? get attachmentRuntime;
  LocalDataBackupService get localDataBackupService;
  LocalDataIntegrityService get localDataIntegrityService;
  MaintenanceTaskService get maintenanceTaskService;
  bool get legacyWritesEnabled;
  bool get usesDriftPlanning;
  bool get formalWritesEnabled;
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
  WorkCaseRuntime? get workCaseRuntime => null;
  @override
  HistoryProjectionRepository? get historyProjectionRepository => null;
  @override
  AttachmentRuntime? get attachmentRuntime => null;
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
  @override
  bool get formalWritesEnabled => true;
}

enum RuntimeDataMode {
  legacy,
  driftSafeReadOnly,
  driftItemRead,
  driftPlanning,
  driftTasks,
  driftWorkCases,
  driftHistoryAttachments,
  driftMaintenanceRecords,
}

class RuntimeInitializationResult {
  const RuntimeInitializationResult({required this.mode, this.importReport});

  final RuntimeDataMode mode;
  final LegacyDriftImportReport? importReport;

  bool get usesDriftItemRead => mode != RuntimeDataMode.legacy;

  bool get isDriftSafeReadOnly => mode == RuntimeDataMode.driftSafeReadOnly;

  bool get usesDriftPlanning =>
      mode == RuntimeDataMode.driftPlanning ||
      mode == RuntimeDataMode.driftTasks ||
      mode == RuntimeDataMode.driftWorkCases ||
      mode == RuntimeDataMode.driftHistoryAttachments ||
      mode == RuntimeDataMode.driftMaintenanceRecords;

  bool get usesDriftTasks =>
      mode == RuntimeDataMode.driftTasks ||
      mode == RuntimeDataMode.driftWorkCases ||
      mode == RuntimeDataMode.driftHistoryAttachments ||
      mode == RuntimeDataMode.driftMaintenanceRecords;

  bool get usesDriftWorkCases =>
      mode == RuntimeDataMode.driftWorkCases ||
      mode == RuntimeDataMode.driftHistoryAttachments ||
      mode == RuntimeDataMode.driftMaintenanceRecords;

  bool get usesDriftHistoryAttachments =>
      mode == RuntimeDataMode.driftHistoryAttachments ||
      mode == RuntimeDataMode.driftMaintenanceRecords;

  bool get usesDriftMaintenanceRecords =>
      mode == RuntimeDataMode.driftMaintenanceRecords;
}

class AppCompositionRoot implements AppRuntimeDependencies {
  AppCompositionRoot({
    required this.database,
    required LocalStorageService legacyStorage,
    this.ownsDatabase = false,
  }) : driftRepositories = DriftSchemaV2Repositories(database),
       _legacyStorage = legacyStorage,
       _runtime = LegacyRuntimeDependencies(legacyStorage) {
    _driftItemReadRepository = DriftItemReadRepository(driftRepositories);
    _driftScheduleRepository = DriftScheduleRuntimeRepository(
      database: database,
      repositories: driftRepositories,
    );
    _driftTaskRepository = DriftTaskRuntimeRepository(
      database: database,
      repositories: driftRepositories,
    );
    _driftMaintenanceRecordRepository = DriftMaintenanceRecordRuntimeRepository(
      database,
    );
    _itemReadRepository = _runtime.itemRepository;
    _scheduleRepository = _runtime.scheduleRepository;
    _taskRepository = _runtime.taskRepository;
    _maintenanceRecordRepository = _runtime.maintenanceRecordRepository;
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
  late TaskRepository _taskRepository;
  late MaintenanceRecordRepository _maintenanceRecordRepository;
  late final DriftItemReadRepository _driftItemReadRepository;
  late final DriftScheduleRuntimeRepository _driftScheduleRepository;
  late final DriftTaskRuntimeRepository _driftTaskRepository;
  late final DriftMaintenanceRecordRuntimeRepository
  _driftMaintenanceRecordRepository;
  WorkCaseRuntime? _workCaseRuntime;
  HistoryProjectionRepository? _historyProjectionRepository;
  AttachmentRuntime? _attachmentRuntime;
  bool _formalWritesEnabled = false;
  Future<RuntimeInitializationResult>? _initialization;

  Future<RuntimeInitializationResult> initialize() =>
      _initialization ??= _initialize();

  Future<RuntimeInitializationResult> _initialize() async {
    try {
      await localDataBackupService.createPreMigrationBackups();
      await Future.wait<void>([
        itemRepository.loadItems().then((_) {}),
        scheduleRepository.loadSchedules().then((_) {}),
        _runtime.taskRepository.loadTasks().then((_) {}),
        _runtime.maintenanceRecordRepository.loadRecords().then((_) {}),
      ]);
      if (localDataIntegrityService.hasIssues) {
        _activateDriftSafeReadOnly();
        return const RuntimeInitializationResult(
          mode: RuntimeDataMode.driftSafeReadOnly,
        );
      }

      _legacyStorage.disableWrites();
      final report =
          await LegacyDriftImportService(
            database: database,
            source: SharedPreferencesLegacyImportSource(_legacyStorage),
          ).execute(
            sourceWritesAreDisabled: true,
            allowVerifiedPlanningMutations: true,
          );
      _itemReadRepository = _driftItemReadRepository;
      _scheduleRepository = _driftScheduleRepository;
      _taskRepository = _driftTaskRepository;
      _maintenanceRecordRepository = _driftMaintenanceRecordRepository;
      _workCaseRuntime = DriftWorkCaseRuntime(
        database: database,
        workCases: driftRepositories.workCases,
        closures: driftRepositories.workCaseClosures,
      );
      _attachmentRuntime = DriftAttachmentRuntime(
        driftRepositories.attachments,
      );
      _historyProjectionRepository = DriftHistoryProjectionRepository(
        database: database,
        attachments: driftRepositories.attachments,
      );
      _formalWritesEnabled = true;
      return RuntimeInitializationResult(
        mode: RuntimeDataMode.driftMaintenanceRecords,
        importReport: report,
      );
    } on LegacyDriftImportException catch (error) {
      _activateDriftSafeReadOnly();
      return RuntimeInitializationResult(
        mode: RuntimeDataMode.driftSafeReadOnly,
        importReport: error.report,
      );
    } catch (_) {
      _activateDriftSafeReadOnly();
      return const RuntimeInitializationResult(
        mode: RuntimeDataMode.driftSafeReadOnly,
      );
    }
  }

  void _activateDriftSafeReadOnly() {
    _legacyStorage.disableWrites();
    _itemReadRepository = _driftItemReadRepository;
    _scheduleRepository = DriftSafeReadOnlyScheduleRepository(
      _driftScheduleRepository,
    );
    _taskRepository = DriftSafeReadOnlyTaskRepository(_driftTaskRepository);
    _maintenanceRecordRepository = DriftSafeReadOnlyMaintenanceRecordRepository(
      _driftMaintenanceRecordRepository,
    );
    _workCaseRuntime = null;
    _attachmentRuntime = null;
    _historyProjectionRepository = DriftHistoryProjectionRepository(
      database: database,
      attachments: driftRepositories.attachments,
    );
    _formalWritesEnabled = false;
  }

  @override
  ItemReadRepository get itemReadRepository => _itemReadRepository;
  @override
  ItemLocalRepository get itemRepository => _runtime.itemRepository;
  @override
  MaintenanceRecordRepository get maintenanceRecordRepository =>
      _maintenanceRecordRepository;
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
  TaskRepository get taskRepository => _taskRepository;
  @override
  WorkCaseRuntime? get workCaseRuntime => _workCaseRuntime;
  @override
  HistoryProjectionRepository? get historyProjectionRepository =>
      _historyProjectionRepository;
  @override
  AttachmentRuntime? get attachmentRuntime => _attachmentRuntime;
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
  @override
  bool get formalWritesEnabled => _formalWritesEnabled;

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
