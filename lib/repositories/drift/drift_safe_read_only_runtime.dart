import '../../models/maintenance_record.dart';
import '../../models/schedule.dart';
import '../../models/task.dart';
import '../maintenance_record_repository.dart';
import '../repository_constraint_exception.dart';
import '../schedule_repository.dart';
import '../task_repository.dart';

const _readOnlyMessage =
    'Runtime admission failed; Drift is available in read-only safe mode.';

class DriftSafeReadOnlyScheduleRepository implements ScheduleRepository {
  DriftSafeReadOnlyScheduleRepository(this._delegate);

  final ScheduleRepository _delegate;

  @override
  Future<List<Schedule>> loadSchedules() => _delegate.loadSchedules();

  @override
  Future<void> saveSchedules(List<Schedule> schedules) =>
      Future<void>.error(const RepositoryConstraintException(_readOnlyMessage));
}

class DriftSafeReadOnlyTaskRepository implements TaskRepository {
  DriftSafeReadOnlyTaskRepository(this._delegate);

  final TaskRepository _delegate;

  @override
  Future<List<Task>> loadTasks() => _delegate.loadTasks();

  @override
  Future<void> saveGeneratedTasks(List<Task> tasks) =>
      Future<void>.error(const RepositoryConstraintException(_readOnlyMessage));
}

class DriftSafeReadOnlyMaintenanceRecordRepository
    implements MaintenanceRecordRepository {
  DriftSafeReadOnlyMaintenanceRecordRepository(this._delegate);

  final MaintenanceRecordRepository _delegate;

  @override
  Future<MaintenanceRecord?> findById(String id) => _delegate.findById(id);

  @override
  Future<List<MaintenanceRecord>> listAll() => _delegate.listAll();

  @override
  Future<List<MaintenanceRecord>> listForItem(String itemId) =>
      _delegate.listForItem(itemId);

  @override
  Future<void> createSimpleRecord(MaintenanceRecord record) =>
      Future<void>.error(const RepositoryConstraintException(_readOnlyMessage));

  @override
  Future<void> completeSimpleTask(MaintenanceRecord record) =>
      Future<void>.error(const RepositoryConstraintException(_readOnlyMessage));
}
