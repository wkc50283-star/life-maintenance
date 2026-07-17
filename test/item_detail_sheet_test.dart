import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('items screen shows empty state without mock items', (
    tester,
  ) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ItemsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('目前還沒有生活項目。'), findsOneWidget);
    expect(find.text('客廳冷氣'), findsNothing);
    expect(find.text('機車'), findsNothing);
    expect(find.text('租屋合約'), findsNothing);
  });

  testWidgets('item detail uses only local schedules and records', (
    tester,
  ) async {
    await _setLocalData(schedules: const []);

    await _openItemDetail(tester);

    expect(find.text('保養安排'), findsOneWidget);
    expect(find.text('目前沒有保養安排'), findsOneWidget);
    expect(find.text('目前尚無處理紀錄'), findsOneWidget);
    expect(find.text('保養提醒'), findsNothing);
    expect(find.text('建立冷氣濾網清洗提醒'), findsNothing);
  });

  testWidgets('item detail shows maintenance schedules separately', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 2);
    final pastDate = DateTime(now.year, now.month, now.day - 1);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-manual',
          title: '手動提醒',
          cardId: 'manual-expiry-reminder',
          nextDueDate: futureDate,
        ),
        _schedule(
          id: 'schedule-manual-due',
          title: '已到期手動提醒',
          cardId: 'manual-expiry-reminder',
          nextDueDate: pastDate,
        ),
        _schedule(
          id: 'schedule-manual-paused',
          title: '暫停手動提醒',
          cardId: 'manual-expiry-reminder',
          nextDueDate: futureDate,
          status: ScheduleStatus.paused,
        ),
        _schedule(
          id: 'schedule-manual-ended',
          title: '結束手動提醒',
          cardId: 'manual-expiry-reminder',
          nextDueDate: futureDate,
          status: ScheduleStatus.ended,
        ),
        _schedule(
          id: 'schedule-active',
          title: '濾網清潔',
          cardId: 'card-aircon-filter-cleaning',
          nextDueDate: futureDate,
        ),
        _schedule(
          id: 'schedule-paused',
          title: '冷氣保養',
          cardId: 'card-aircon-maintenance',
          nextDueDate: futureDate,
          status: ScheduleStatus.paused,
        ),
        _schedule(
          id: 'schedule-ended',
          title: '舊排程',
          cardId: 'card-old-maintenance',
          nextDueDate: futureDate,
          status: ScheduleStatus.ended,
        ),
      ],
    );

    await _openItemDetail(tester);

    expect(find.text('提醒事項'), findsOneWidget);
    expect(find.text('手動提醒'), findsOneWidget);
    expect(find.text('已到期手動提醒'), findsOneWidget);
    expect(find.text('暫停手動提醒'), findsOneWidget);
    expect(find.text('結束手動提醒'), findsOneWidget);
    expect(find.text('狀態：尚未到期'), findsOneWidget);
    expect(find.text('狀態：已到期'), findsOneWidget);
    expect(find.text('保養安排'), findsOneWidget);
    expect(find.text('濾網清潔'), findsOneWidget);
    expect(find.text('冷氣保養'), findsOneWidget);
    expect(find.text('舊排程'), findsOneWidget);
    expect(find.text('狀態：進行中'), findsOneWidget);
    expect(find.text('狀態：已暫停'), findsNWidgets(2));
    expect(find.text('狀態：已結束'), findsNWidgets(2));
    expect(find.text('重新安排並恢復'), findsOneWidget);
  });

  testWidgets('paused maintenance schedule can be rescheduled and resumed', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 2);
    final otherDate = DateTime(now.year, now.month, now.day + 5);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '冷氣保養',
          cardId: 'card-aircon-maintenance',
          nextDueDate: futureDate,
          status: ScheduleStatus.paused,
        ),
        _schedule(
          id: 'schedule-other',
          title: '其他保養',
          cardId: 'card-other-maintenance',
          nextDueDate: otherDate,
        ),
      ],
    );

    await _openItemDetail(tester);
    await _tapResumeButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('保養安排已重新安排並恢復'), findsOneWidget);
    final schedules = await _storedSchedules();
    expect(
      _statusFor(schedules, 'schedule-paused'),
      ScheduleStatus.active.name,
    );
    expect(_enabledFor(schedules, 'schedule-paused'), isTrue);
    expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
    expect(_statusFor(schedules, 'schedule-other'), ScheduleStatus.active.name);
    expect(_nextDueDateFor(schedules, 'schedule-other'), otherDate);
    expect(await _storedTasks(), isEmpty);
  });

  testWidgets('past paused maintenance schedule defaults date to tomorrow', (
    tester,
  ) async {
    final now = DateTime.now();
    final pastDate = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '冷氣保養',
          cardId: 'card-aircon-maintenance',
          nextDueDate: pastDate,
          status: ScheduleStatus.paused,
        ),
      ],
    );

    await _openItemDetail(tester);
    await _tapResumeButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final schedules = await _storedSchedules();
    expect(
      _statusFor(schedules, 'schedule-paused'),
      ScheduleStatus.active.name,
    );
    expect(_nextDueDateFor(schedules, 'schedule-paused'), tomorrow);
  });

  testWidgets('paused maintenance schedule rejects conflicting pending task', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 2);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '冷氣保養',
          cardId: 'card-aircon-maintenance',
          nextDueDate: futureDate,
          status: ScheduleStatus.paused,
        ),
      ],
      tasks: [
        _task(
          id: 'task-conflict',
          scheduleId: 'schedule-paused',
          dueDate: futureDate,
        ),
      ],
    );

    await _openItemDetail(tester);
    await _tapResumeButton(tester);
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('這個日期已有待處理提醒，請選擇其他日期'), findsOneWidget);
    expect(find.text('生活項目詳情'), findsOneWidget);
    final schedules = await _storedSchedules();
    expect(
      _statusFor(schedules, 'schedule-paused'),
      ScheduleStatus.paused.name,
    );
    expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
  });

  testWidgets(
    'paused maintenance schedule ignores completed and canceled task conflicts',
    (tester) async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-paused',
            title: '冷氣保養',
            cardId: 'card-aircon-maintenance',
            nextDueDate: futureDate,
            status: ScheduleStatus.paused,
          ),
        ],
        tasks: [
          _task(
            id: 'task-completed',
            scheduleId: 'schedule-paused',
            dueDate: futureDate,
            status: TaskStatus.completed,
          ),
          _task(
            id: 'task-canceled',
            scheduleId: 'schedule-paused',
            dueDate: futureDate,
            status: TaskStatus.canceled,
          ),
        ],
      );

      await _openItemDetail(tester);
      await _tapResumeButton(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final schedules = await _storedSchedules();
      expect(
        _statusFor(schedules, 'schedule-paused'),
        ScheduleStatus.active.name,
      );
      expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
    },
  );

  testWidgets(
    'paused maintenance schedule fails when stored schedule changed',
    (tester) async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-paused',
            title: '冷氣保養',
            cardId: 'card-aircon-maintenance',
            nextDueDate: futureDate,
            status: ScheduleStatus.paused,
          ),
        ],
      );

      await _openItemDetail(tester);
      await _replaceStoredSchedules([
        _schedule(
          id: 'schedule-paused',
          title: '冷氣保養',
          cardId: 'card-aircon-maintenance',
          nextDueDate: futureDate,
          status: ScheduleStatus.active,
        ),
      ]);
      await _tapResumeButton(tester);
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('重新安排失敗，請稍後再試'), findsOneWidget);
      expect(find.text('生活項目詳情'), findsOneWidget);
      final schedules = await _storedSchedules();
      expect(
        _statusFor(schedules, 'schedule-paused'),
        ScheduleStatus.active.name,
      );
      expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
    },
  );
}

Future<void> _setLocalData({
  required List<Schedule> schedules,
  List<Task> tasks = const [],
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    'items': jsonEncode([_item().toJson()]),
    'records': jsonEncode(<Map<String, dynamic>>[]),
    'schedules': jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    ),
    'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
  });
}

Future<void> _openItemDetail(WidgetTester tester) async {
  await tester.pumpWidget(
    const MaterialApp(home: Scaffold(body: ItemsScreen())),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.text('冷氣'));
  await tester.pumpAndSettle();
}

Future<void> _tapResumeButton(WidgetTester tester) async {
  final finder = find.text('重新安排並恢復').first;
  await tester.ensureVisible(finder);
  await tester.tap(finder);
}

Future<void> _replaceStoredSchedules(List<Schedule> schedules) async {
  final preferences = await SharedPreferences.getInstance();
  await preferences.setString(
    'schedules',
    jsonEncode(schedules.map((schedule) => schedule.toJson()).toList()),
  );
}

Item _item() {
  return Item(
    id: 'item-1',
    name: '冷氣',
    category: ItemCategory.appliance,
    createdAt: DateTime(2026, 7, 1),
  );
}

Schedule _schedule({
  required String id,
  required String title,
  required String cardId,
  required DateTime nextDueDate,
  ScheduleStatus status = ScheduleStatus.active,
}) {
  return Schedule(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    cycleType: CycleType.monthly,
    interval: 1,
    startDate: DateTime(2026, 7, 1),
    nextDueDate: nextDueDate,
    title: title,
    status: status,
  );
}

Task _task({
  required String id,
  required String scheduleId,
  required DateTime dueDate,
  TaskStatus status = TaskStatus.pending,
}) {
  return Task(
    id: id,
    itemId: 'item-1',
    cardId: 'card-aircon-maintenance',
    scheduleId: scheduleId,
    title: '冷氣保養',
    dueDate: dueDate,
    status: status,
  );
}

Future<List<dynamic>> _storedSchedules() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('schedules')!) as List<dynamic>;
}

Future<List<dynamic>> _storedTasks() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('tasks')!) as List<dynamic>;
}

String _statusFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['status'] as String;
}

bool _enabledFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['enabled'] as bool;
}

DateTime _nextDueDateFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return DateTime.parse(schedule['nextDueDate'] as String);
}
