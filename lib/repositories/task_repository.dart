import '../models/task.dart';

/// Runtime access to reminder instances.
///
/// A Task is generated from a formal source and remains only a reminder. This
/// contract intentionally exposes no completion or MaintenanceRecord write.
abstract interface class TaskRepository {
  Future<List<Task>> loadTasks();

  Future<void> saveGeneratedTasks(List<Task> tasks);
}
