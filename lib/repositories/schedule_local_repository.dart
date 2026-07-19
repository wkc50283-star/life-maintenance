import 'dart:convert';

import '../models/schedule.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';
import 'schedule_repository.dart';

class ScheduleLocalRepository implements ScheduleRepository {
  static const String _storageKey = 'schedules';

  ScheduleLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  @override
  Future<List<Schedule>> loadSchedules() async {
    final rawSchedules = await _storageService.readString(_storageKey);
    if (rawSchedules == null) {
      LocalDataIntegrityService.instance.clearIssue(_storageKey);
      return <Schedule>[];
    }

    return LocalDataIntegrityService.instance.decodeList<Schedule>(
      storageKey: _storageKey,
      rawValue: rawSchedules,
      decodeEntry: Schedule.fromJson,
    );
  }

  @override
  Future<void> saveSchedules(List<Schedule> schedules) async {
    LocalDataIntegrityService.instance.ensureWritesAllowed();
    final encodedSchedules = jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedSchedules);
  }
}
