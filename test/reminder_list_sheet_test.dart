import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/widgets/reminder_list_sheet.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('reminder list shows active paused and ended manual reminders', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 1);
    final pastDate = DateTime(now.year, now.month, now.day - 1);

    await _setLocalData(
      schedules: [
        _schedule(id: 'schedule-future', title: '未到期提醒', date: futureDate),
        _schedule(id: 'schedule-past', title: '已到期提醒', date: pastDate),
        _schedule(
          id: 'schedule-paused',
          title: '暫停提醒',
          date: futureDate,
          status: ScheduleStatus.paused,
        ),
        _schedule(
          id: 'schedule-ended',
          title: '結束提醒',
          date: futureDate,
          status: ScheduleStatus.ended,
        ),
        _schedule(
          id: 'schedule-maintenance',
          title: '一般保養',
          date: futureDate,
          cardId: 'card-aircon-filter-cleaning',
        ),
      ],
    );

    await _openReminderListSheet(tester);

    expect(find.text('未到期提醒'), findsOneWidget);
    expect(find.text('狀態：尚未到期'), findsOneWidget);
    expect(find.text('已到期提醒'), findsOneWidget);
    expect(find.text('狀態：已到期'), findsOneWidget);
    expect(find.text('暫停提醒'), findsOneWidget);
    expect(find.text('狀態：已暫停'), findsOneWidget);
    expect(find.text('結束提醒'), findsOneWidget);
    expect(find.text('狀態：已結束'), findsOneWidget);
    expect(find.text('一般保養'), findsNothing);
  });

  testWidgets('paused reminder opens read only detail without active actions', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 1);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '暫停提醒',
          date: futureDate,
          status: ScheduleStatus.paused,
        ),
      ],
    );

    await _openReminderListSheet(tester);
    await tester.tap(find.text('暫停提醒'));
    await tester.pumpAndSettle();

    expect(find.text('事項詳情'), findsOneWidget);
    expect(find.text('已暫停'), findsOneWidget);
    expect(find.text('編輯名稱'), findsNothing);
    expect(find.text('編輯提醒日期'), findsNothing);
    expect(find.text('取消提醒'), findsNothing);
    expect(find.text('重新安排並恢復'), findsOneWidget);
  });

  testWidgets('ended reminder opens read only detail without active actions', (
    tester,
  ) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 1);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-ended',
          title: '結束提醒',
          date: futureDate,
          status: ScheduleStatus.ended,
        ),
      ],
    );

    await _openReminderListSheet(tester);
    await tester.tap(find.text('結束提醒'));
    await tester.pumpAndSettle();

    expect(find.text('事項詳情'), findsOneWidget);
    expect(find.text('已結束'), findsOneWidget);
    expect(find.text('編輯名稱'), findsNothing);
    expect(find.text('編輯提醒日期'), findsNothing);
    expect(find.text('取消提醒'), findsNothing);
    expect(find.text('重新安排並恢復'), findsNothing);
  });

  testWidgets('active reminder detail keeps active actions', (tester) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 1);
    await _setLocalData(
      schedules: [
        _schedule(id: 'schedule-active', title: '未到期提醒', date: futureDate),
      ],
    );

    await _openReminderListSheet(tester);
    await tester.tap(find.text('未到期提醒'));
    await tester.pumpAndSettle();

    expect(find.text('事項詳情'), findsOneWidget);
    expect(find.text('編輯名稱'), findsOneWidget);
    expect(find.text('編輯提醒日期'), findsOneWidget);
    expect(find.text('取消提醒'), findsOneWidget);
    expect(find.text('重新安排並恢復'), findsNothing);
  });

  testWidgets('paused reminder can be rescheduled and resumed', (tester) async {
    final now = DateTime.now();
    final futureDate = DateTime(now.year, now.month, now.day + 2);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '暫停提醒',
          date: futureDate,
          status: ScheduleStatus.paused,
        ),
      ],
    );

    await _openReminderListSheet(tester);
    await tester.tap(find.text('暫停提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重新安排並恢復'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    expect(find.text('提醒已重新安排'), findsOneWidget);
    final schedules = await _storedSchedules();
    expect(_statusFor(schedules, 'schedule-paused'), ScheduleStatus.active.name);
    expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
  });

  testWidgets(
    'paused reminder reschedule rejects conflicting unfinished task',
    (tester) async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-paused',
            title: '暫停提醒',
            date: futureDate,
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

      await _openReminderListSheet(tester);
      await tester.tap(find.text('暫停提醒'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重新安排並恢復'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      expect(find.text('這個日期已有待處理提醒，請選擇其他日期'), findsOneWidget);
      final schedules = await _storedSchedules();
      expect(
        _statusFor(schedules, 'schedule-paused'),
        ScheduleStatus.paused.name,
      );
      expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
    },
  );

  testWidgets(
    'paused reminder reschedule ignores completed and canceled tasks',
    (tester) async {
      final now = DateTime.now();
      final futureDate = DateTime(now.year, now.month, now.day + 2);
      await _setLocalData(
        schedules: [
          _schedule(
            id: 'schedule-paused',
            title: '暫停提醒',
            date: futureDate,
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

      await _openReminderListSheet(tester);
      await tester.tap(find.text('暫停提醒'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('重新安排並恢復'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();

      final schedules = await _storedSchedules();
      expect(_statusFor(schedules, 'schedule-paused'), ScheduleStatus.active.name);
      expect(_nextDueDateFor(schedules, 'schedule-paused'), futureDate);
    },
  );

  testWidgets('past paused reminder defaults reschedule date to tomorrow', (
    tester,
  ) async {
    final now = DateTime.now();
    final pastDate = DateTime(now.year, now.month, now.day - 1);
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    await _setLocalData(
      schedules: [
        _schedule(
          id: 'schedule-paused',
          title: '暫停提醒',
          date: pastDate,
          status: ScheduleStatus.paused,
        ),
      ],
    );

    await _openReminderListSheet(tester);
    await tester.tap(find.text('暫停提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('重新安排並恢復'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    final schedules = await _storedSchedules();
    expect(_statusFor(schedules, 'schedule-paused'), ScheduleStatus.active.name);
    expect(_nextDueDateFor(schedules, 'schedule-paused'), tomorrow);
  });
}

Future<void> _setLocalData({
  required List<Schedule> schedules,
  List<Task> tasks = const [],
}) async {
  SharedPreferences.resetStatic();
  SharedPreferences.setMockInitialValues({
    'items': jsonEncode([_item().toJson()]),
    'schedules': jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    ),
    'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
  });
}

Future<void> _openReminderListSheet(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) {
            return TextButton(
              onPressed: () => showReminderListSheet(context),
              child: const Text('open'),
            );
          },
        ),
      ),
    ),
  );
  await tester.tap(find.text('open'));
  await tester.pumpAndSettle();
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
  required String title,
  required DateTime date,
  String cardId = 'manual-expiry-reminder',
  ScheduleStatus status = ScheduleStatus.active,
}) {
  return Schedule(
    id: id,
    itemId: 'item-1',
    cardId: cardId,
    cycleType: CycleType.custom,
    interval: 1,
    startDate: DateTime(2026, 7, 1),
    nextDueDate: date,
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
    cardId: 'manual-expiry-reminder',
    scheduleId: scheduleId,
    title: '暫停提醒',
    dueDate: dueDate,
    status: status,
  );
}

Future<List<dynamic>> _storedSchedules() async {
  final preferences = await SharedPreferences.getInstance();
  return jsonDecode(preferences.getString('schedules')!) as List<dynamic>;
}

String _statusFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return schedule['status'] as String;
}

DateTime _nextDueDateFor(List<dynamic> schedules, String id) {
  final schedule = schedules.cast<Map<String, dynamic>>().singleWhere(
    (schedule) => schedule['id'] == id,
  );
  return DateTime.parse(schedule['nextDueDate'] as String);
}
