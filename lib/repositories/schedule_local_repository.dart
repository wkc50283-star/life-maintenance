import 'dart:convert';

import '../models/schedule.dart';
import '../services/local_storage_service.dart';

class ScheduleLocalRepository {
  static const String _storageKey = 'schedules';

  ScheduleLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<Schedule>> loadSchedules() async {
    final rawSchedules = await _storageService.readString(_storageKey);
    if (rawSchedules == null) {
      return <Schedule>[];
    }

    final decodedSchedules = jsonDecode(rawSchedules) as List<dynamic>;
    return decodedSchedules
        .map(
          (schedule) => Schedule.fromJson(schedule as Map<String, dynamic>),
        )
        .toList();
  }

  Future<void> saveSchedules(List<Schedule> schedules) async {
    final encodedSchedules = jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedSchedules);
  }
}
