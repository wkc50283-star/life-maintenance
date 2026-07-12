import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/screens/today_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets(
    'completing a manual expiry reminder disables only the matching schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(id: 'schedule-target', nextDueDate: dueDate),
          _schedule(id: 'schedule-other', nextDueDate: dueDate),
        ],
        tasks: [
          _task(
            id: 'task-target',
            scheduleId: 'schedule-target',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-target'), isFalse);
      expect(_enabledFor(schedules, 'schedule-other'), isTrue);
    },
  );

  testWidgets(
    'completing a regular maintenance task does not disable schedule',
    (tester) async {
      final dueDate = DateTime(2026, 7, 10);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            nextDueDate: dueDate,
          ),
        ],
        tasks: [
          _task(
            id: 'task-maintenance',
            cardId: 'card-aircon-filter-cleaning',
            scheduleId: 'schedule-maintenance',
            title: '保養提醒',
            dueDate: dueDate,
          ),
        ],
      );

      await _completeVisibleTask(tester);

      final schedules = await _storedSchedules();
      expect(_enabledFor(schedules, 'schedule-maintenance'), isTrue);
    },
  );

  testWidgets('completing a task with empty scheduleId still succeeds', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: const [],
      tasks: [
        _task(id: 'task-empty-schedule', scheduleId: '', dueDate: dueDate),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(_statusFor(tasks, 'task-empty-schedule'), TaskStatus.completed.name);
    final records = await _storedRecords();
    expect(records.single['taskId'], 'task-empty-schedule');
  });

  testWidgets('missing matching schedule does not block completion', (
    tester,
  ) async {
    final dueDate = DateTime(2026, 7, 10);
    await _setLocalData(
      schedules: [
        _schedule(id: 'schedule-unrelated', nextDueDate: DateTime(2027, 1, 1)),
      ],
      tasks: [
        _task(
          id: 'task-missing-schedule',
          scheduleId: 'schedule-missing',
          dueDate: dueDate,
        ),
      ],
    );

    await _completeVisibleTask(tester);

    final tasks = await _storedTasks();
    expect(
      _statusFor(tasks, 'task-missing-schedule'),
      TaskStatus.completed.name,
    );
    final schedules = await _storedSchedules();
    expect(_enabledFor(schedules, 'schedule-unrelated'), isTrue);
  });
}

Future<void> _setLocalData({
  required List<Schedule> schedules,
  required List<Task> tasks,
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    'items': jsonEncode([_item().toJson()]),
    'schedules': jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    ),
    'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
    'maintenance_records': jsonEncode([]),
  });
}

Future<void> _completeVisibleTask(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: TodayScreen())),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('完成').first);
  await tester.pumpAndSettle();

  final sheetCompleteButton = find.text('完成').last;
  await tester.ensureVisible(sheetCompleteButton);
  await tester.tap(sheetCompleteButton);
  await tester.pumpAndSettle();
}

Future<List<dynamic>> _storedSchedules() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('schedules')!) as List<dynamic>;
}

Future<List<dynamic>> _storedTasks() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('tasks')!) as List<dynamic>;
}

Future<List<dynamic>> _storedRecords() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('maintenance_records')!)
      as List<dynamic>;
}

bool _enabledFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['enabled'] as bool;
}

String _statusFor(List<dynamic> tasks, String id) {
  final task = tasks.cast<Map<String, dynamic>>().singleWhere(
    (task) => task['id'] == id,
  );
  return task['status'] as String;
}

Item _item() {
  return Item(
    id: 'item-1',
    name: '合約',
    category: ItemCategory.warrantyDocument,
    createdAt: DateTime(2026, 7, 1),
  );
}

Schedule _schedule({
  required String id,
  required DateTime nextDueDate,
  String cardId = 'manual-expiry-reminder',
}) {
  return Schedule(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    cycleType: CycleType.custom,
    interval: 1,
    startDate: DateTime(2026, 7, 1),
    nextDueDate: nextDueDate,
    title: '合約續約',
  );
}

Task _task({
  required String id,
  required String scheduleId,
  required DateTime dueDate,
  String cardId = 'manual-expiry-reminder',
  String title = '合約續約',
}) {
  return Task(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    scheduleId: scheduleId,
    title: title,
    dueDate: dueDate,
  );
}
