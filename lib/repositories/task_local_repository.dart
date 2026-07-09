import 'dart:convert';

import '../models/task.dart';
import '../services/local_storage_service.dart';

class TaskLocalRepository {
  static const String _storageKey = 'tasks';

  TaskLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<Task>> loadTasks() async {
    final rawTasks = await _storageService.readString(_storageKey);
    if (rawTasks == null) {
      return <Task>[];
    }

    try {
      final decodedTasks = jsonDecode(rawTasks) as List<dynamic>;
      return decodedTasks
          .map((task) => Task.fromJson(task as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return <Task>[];
    }
  }

  Future<void> saveTasks(List<Task> tasks) async {
    final encodedTasks = jsonEncode(
      tasks.map((task) => task.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedTasks);
  }
}
