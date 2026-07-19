import 'dart:convert';

import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/repositories/attachment_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/history_projection_repository.dart';
import 'package:life_maintenance/repositories/item_local_repository.dart';
import 'package:life_maintenance/repositories/item_read_repository.dart';
import 'package:life_maintenance/repositories/maintenance_record_local_repository.dart';
import 'package:life_maintenance/repositories/maintenance_record_repository.dart';
import 'package:life_maintenance/repositories/schedule_local_repository.dart';
import 'package:life_maintenance/repositories/schedule_repository.dart';
import 'package:life_maintenance/repositories/task_local_repository.dart';
import 'package:life_maintenance/repositories/task_repository.dart';
import 'package:life_maintenance/repositories/task_reminder_runtime.dart';
import 'package:life_maintenance/repositories/work_case_runtime.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:life_maintenance/services/maintenance_task_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Compatibility-only persistence used by pre-Drift widget tests.
///
/// It is deliberately located under test/ and is never part of production.
class TestRuntimeDependencies implements AppRuntimeDependencies {
  TestRuntimeDependencies()
    : _storage = LocalStorageService(),
      maintenanceTaskService = MaintenanceTaskService() {
    itemReadRepository = ItemLocalRepository(_storage);
    scheduleRepository = _TestScheduleRepository(_storage);
    taskRepository = _TestTaskRepository(_storage);
    maintenanceRecordRepository = _TestMaintenanceRecordRepository(_storage);
  }

  final LocalStorageService _storage;

  @override
  late final ItemReadRepository itemReadRepository;
  @override
  late final MaintenanceRecordRepository maintenanceRecordRepository;
  @override
  late final ScheduleRepository scheduleRepository;
  @override
  DriftMaintenancePlanRepository? get maintenancePlanRepository => null;
  @override
  DriftGeneralReminderRepository? get generalReminderRepository => null;
  @override
  DriftMilestoneRepository? get milestoneRepository => null;
  @override
  late final TaskRepository taskRepository;
  @override
  TaskReminderRuntime? get taskReminderRuntime => null;
  @override
  WorkCaseRuntime? get workCaseRuntime => null;
  @override
  HistoryProjectionRepository? get historyProjectionRepository => null;
  @override
  AttachmentRuntime? get attachmentRuntime => null;
  @override
  final MaintenanceTaskService maintenanceTaskService;
  @override
  bool get usesDriftPlanning => false;
  @override
  bool get formalWritesEnabled => true;
}

class _TestScheduleRepository implements ScheduleRepository {
  _TestScheduleRepository(LocalStorageService storage)
    : _reader = ScheduleLocalRepository(storage);

  final ScheduleLocalRepository _reader;

  @override
  Future<List<Schedule>> loadSchedules() => _reader.loadSchedules();

  @override
  Future<void> saveSchedules(List<Schedule> schedules) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'schedules',
      jsonEncode(schedules.map((schedule) => schedule.toJson()).toList()),
    );
  }
}

class _TestTaskRepository implements TaskRepository {
  _TestTaskRepository(LocalStorageService storage)
    : _reader = TaskLocalRepository(storage);

  final TaskLocalRepository _reader;

  @override
  Future<List<Task>> loadTasks() => _reader.loadTasks();

  @override
  Future<void> saveGeneratedTasks(List<Task> tasks) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'tasks',
      jsonEncode(tasks.map((task) => task.toJson()).toList()),
    );
  }
}

class _TestMaintenanceRecordRepository implements MaintenanceRecordRepository {
  _TestMaintenanceRecordRepository(LocalStorageService storage)
    : _reader = MaintenanceRecordLocalRepository(storage);

  final MaintenanceRecordLocalRepository _reader;

  @override
  Future<MaintenanceRecord?> findById(String id) => _reader.findById(id);

  @override
  Future<List<MaintenanceRecord>> listAll() => _reader.listAll();

  @override
  Future<List<MaintenanceRecord>> listForItem(String itemId) =>
      _reader.listForItem(itemId);

  @override
  Future<void> createSimpleRecord(MaintenanceRecord record) async {
    await _save([...await _reader.listAll(), record]);
  }

  @override
  Future<void> completeSimpleTask(MaintenanceRecord record) =>
      createSimpleRecord(record);

  Future<void> _save(List<MaintenanceRecord> records) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'maintenance_records',
      jsonEncode(records.map((record) => record.toJson()).toList()),
    );
  }
}
