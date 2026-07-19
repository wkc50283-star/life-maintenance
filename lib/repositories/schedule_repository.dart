import '../models/schedule.dart';

abstract interface class ScheduleRepository {
  Future<List<Schedule>> loadSchedules();

  Future<void> saveSchedules(List<Schedule> schedules);
}
