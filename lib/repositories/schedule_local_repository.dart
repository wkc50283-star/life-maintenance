import '../models/schedule.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';

class ScheduleLocalRepository {
  static const String _storageKey = 'schedules';

  ScheduleLocalRepository(this._storageService);

  final LocalStorageService _storageService;

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
}
