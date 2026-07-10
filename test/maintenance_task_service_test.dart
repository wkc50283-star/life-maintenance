import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/services/maintenance_task_service.dart';

void main() {
  group('MaintenanceTaskService', () {
    test('uses schedule title when generating due tasks', () {
      final service = MaintenanceTaskService();
      final tasks = service.generateDueTasks(
        schedules: [
          _schedule(
            id: 'schedule-contract',
            title: '租約續約',
            nextDueDate: DateTime(2026, 7, 10),
          ),
        ],
        existingTasks: const [],
        today: DateTime(2026, 7, 10),
      );

      expect(tasks.single.title, '租約續約');
    });

    test('falls back for null and blank schedule titles', () {
      final service = MaintenanceTaskService();
      final tasks = service.generateDueTasks(
        schedules: [
          _schedule(
            id: 'schedule-manual-null',
            title: null,
            cardId: 'manual-expiry-reminder',
            nextDueDate: DateTime(2026, 7, 10),
          ),
          _schedule(
            id: 'schedule-manual-blank',
            title: '   ',
            cardId: 'manual-expiry-reminder',
            nextDueDate: DateTime(2026, 7, 10),
          ),
          _schedule(
            id: 'schedule-maintenance',
            title: null,
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: DateTime(2026, 7, 10),
          ),
        ],
        existingTasks: const [],
        today: DateTime(2026, 7, 10),
      );

      expect(tasks[0].title, '需要你記住的事');
      expect(tasks[1].title, '需要你記住的事');
      expect(tasks[2].title, '保養提醒');
    });

    test('does not duplicate existing task for same schedule and due date', () {
      final service = MaintenanceTaskService();
      final dueDate = DateTime(2026, 7, 10);
      final tasks = service.generateDueTasks(
        schedules: [
          _schedule(
            id: 'schedule-contract',
            title: '租約續約',
            nextDueDate: dueDate,
          ),
        ],
        existingTasks: [
          Task(
            id: 'existing-task',
            itemId: 'item-contract',
            cardId: 'manual-expiry-reminder',
            scheduleId: 'schedule-contract',
            title: '租約續約',
            dueDate: dueDate,
          ),
        ],
        today: DateTime(2026, 7, 10),
      );

      expect(tasks, isEmpty);
    });
  });

  test('Schedule reads old JSON without title', () {
    final schedule = Schedule.fromJson({
      'id': 'schedule-old',
      'itemId': 'item-contract',
      'cardId': 'manual-expiry-reminder',
      'cycleType': 'custom',
      'interval': 1,
      'startDate': '2026-07-01T00:00:00.000',
      'nextDueDate': '2026-07-10T00:00:00.000',
      'reminderTime': null,
      'enabled': true,
      'strictPeriodMode': false,
    });

    expect(schedule.title, isNull);
  });
}

Schedule _schedule({
  required String id,
  required String? title,
  required DateTime nextDueDate,
  String cardId = 'manual-expiry-reminder',
}) {
  return Schedule(
    id: id,
    itemId: 'item-contract',
    cardId: cardId,
    cycleType: CycleType.custom,
    interval: 1,
    startDate: DateTime(2026, 7, 1),
    nextDueDate: nextDueDate,
    title: title,
  );
}
