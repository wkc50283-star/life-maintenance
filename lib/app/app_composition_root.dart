import 'package:flutter/widgets.dart';

import '../database/app_database.dart';
import '../repositories/attachment_runtime.dart';
import '../repositories/drift/drift_attachment_runtime.dart';
import '../repositories/drift/drift_history_projection_repository.dart';
import '../repositories/drift/drift_item_read_repository.dart';
import '../repositories/drift/drift_maintenance_record_repository.dart';
import '../repositories/drift/drift_schedule_runtime_repository.dart';
import '../repositories/drift/drift_schema_v2_repositories.dart';
import '../repositories/drift/drift_task_runtime_repository.dart';
import '../repositories/drift/drift_task_reminder_runtime.dart';
import '../repositories/drift/drift_work_case_runtime.dart';
import '../repositories/history_projection_repository.dart';
import '../repositories/item_read_repository.dart';
import '../repositories/maintenance_record_repository.dart';
import '../repositories/schedule_repository.dart';
import '../repositories/task_repository.dart';
import '../repositories/task_reminder_runtime.dart';
import '../repositories/work_case_runtime.dart';
import '../services/maintenance_task_service.dart';

/// Process-wide formal runtime dependencies.
///
/// Production business data is read and written only through Drift. Legacy
/// SharedPreferences access lives outside this composition root in explicitly
/// invoked backup, import, audit, and disaster-recovery tools.
abstract interface class AppRuntimeDependencies {
  ItemReadRepository get itemReadRepository;
  MaintenanceRecordRepository get maintenanceRecordRepository;
  ScheduleRepository get scheduleRepository;
  DriftMaintenancePlanRepository? get maintenancePlanRepository;
  DriftGeneralReminderRepository? get generalReminderRepository;
  DriftMilestoneRepository? get milestoneRepository;
  TaskRepository get taskRepository;
  TaskReminderRuntime? get taskReminderRuntime;
  WorkCaseRuntime? get workCaseRuntime;
  HistoryProjectionRepository? get historyProjectionRepository;
  AttachmentRuntime? get attachmentRuntime;
  MaintenanceTaskService get maintenanceTaskService;
  bool get usesDriftPlanning;
  bool get formalWritesEnabled;
}

enum RuntimeDataMode { driftMaintenanceRecords }

class RuntimeInitializationResult {
  const RuntimeInitializationResult({required this.mode});

  final RuntimeDataMode mode;

  bool get usesDriftItemRead => true;
  bool get usesDriftPlanning => true;
  bool get usesDriftTasks => true;
  bool get usesDriftWorkCases => true;
  bool get usesDriftHistoryAttachments => true;
  bool get usesDriftMaintenanceRecords => true;
}

class AppCompositionRoot implements AppRuntimeDependencies {
  AppCompositionRoot({required this.database, this.ownsDatabase = false})
    : driftRepositories = DriftSchemaV2Repositories(database) {
    itemReadRepository = DriftItemReadRepository(driftRepositories);
    scheduleRepository = DriftScheduleRuntimeRepository(
      database: database,
      repositories: driftRepositories,
    );
    taskRepository = DriftTaskRuntimeRepository(
      database: database,
      repositories: driftRepositories,
    );
    maintenanceRecordRepository = DriftMaintenanceRecordRuntimeRepository(
      database,
    );
    workCaseRuntime = DriftWorkCaseRuntime(
      database: database,
      workCases: driftRepositories.workCases,
      closures: driftRepositories.workCaseClosures,
      tasks: driftRepositories.tasks,
    );
    taskReminderRuntime = DriftTaskReminderRuntime(
      database: database,
      repositories: driftRepositories,
      workCaseRuntime: workCaseRuntime,
    );
    attachmentRuntime = DriftAttachmentRuntime(driftRepositories.attachments);
    historyProjectionRepository = DriftHistoryProjectionRepository(
      database: database,
      attachments: driftRepositories.attachments,
    );
  }

  factory AppCompositionRoot.production() =>
      AppCompositionRoot(database: AppDatabase.defaults(), ownsDatabase: true);

  final AppDatabase database;
  final DriftSchemaV2Repositories driftRepositories;
  final bool ownsDatabase;

  @override
  late final ItemReadRepository itemReadRepository;
  @override
  late final MaintenanceRecordRepository maintenanceRecordRepository;
  @override
  late final ScheduleRepository scheduleRepository;
  @override
  DriftMaintenancePlanRepository get maintenancePlanRepository =>
      driftRepositories.maintenancePlans;
  @override
  DriftGeneralReminderRepository get generalReminderRepository =>
      driftRepositories.generalReminders;
  @override
  DriftMilestoneRepository get milestoneRepository =>
      driftRepositories.milestones;
  @override
  late final TaskRepository taskRepository;
  @override
  late final TaskReminderRuntime taskReminderRuntime;
  @override
  late final WorkCaseRuntime workCaseRuntime;
  @override
  late final HistoryProjectionRepository historyProjectionRepository;
  @override
  late final AttachmentRuntime attachmentRuntime;
  @override
  final MaintenanceTaskService maintenanceTaskService =
      MaintenanceTaskService();
  @override
  bool get usesDriftPlanning => true;
  @override
  bool get formalWritesEnabled => true;

  Future<RuntimeInitializationResult> initialize() async {
    await database.customSelect('SELECT 1').get();
    return const RuntimeInitializationResult(
      mode: RuntimeDataMode.driftMaintenanceRecords,
    );
  }

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
