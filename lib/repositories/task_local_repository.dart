import '../models/task.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';

class TaskLocalRepository {
  static const String _storageKey = 'tasks';

  TaskLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<Task>> loadTasks() async {
    final rawTasks = await _storageService.readString(_storageKey);
    if (rawTasks == null) {
      LocalDataIntegrityService.instance.clearIssue(_storageKey);
      return <Task>[];
    }

    return LocalDataIntegrityService.instance.decodeList<Task>(
      storageKey: _storageKey,
      rawValue: rawTasks,
      decodeEntry: Task.fromJson,
    );
  }
}
