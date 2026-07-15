import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/widgets/empty_history_state.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('history screen shows empty state without mock records', (
    tester,
  ) async {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('目前還沒有履歷紀錄。'), findsOneWidget);
    expect(find.text('建立冷氣濾網清洗提醒'), findsNothing);
    expect(find.text('建立機車胎壓檢查提醒'), findsNothing);
    expect(find.text('建立租屋合約到期提醒'), findsNothing);
  });

  testWidgets('history does not use mock item names for local records', (
    tester,
  ) async {
    final record = _record(
      id: 'record-local-missing-item',
      itemId: 'item-aircon-living-room',
      recordType: RecordType.regularMaintenance,
      date: DateTime(2026, 7, 10),
      title: '本機紀錄',
      workDescription: '本機處理內容',
    );
    await _setLocalData(records: [record], items: const []);

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('本機紀錄'), findsOneWidget);
    expect(find.text('未命名物品'), findsOneWidget);
    expect(find.text('客廳冷氣'), findsNothing);
  });

  testWidgets('history screen shows records as a dated timeline', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final records = [
      _record(
        id: 'record-old',
        itemId: 'item-b',
        recordType: RecordType.regularMaintenance,
        date: DateTime(2026, 6, 5),
        title: '較舊紀錄',
        issueDescription: '有異音',
      ),
      _record(
        id: 'record-missing-item',
        itemId: 'missing-item',
        recordType: RecordType.other,
        date: DateTime(2026, 5, 1),
        title: '找不到項目紀錄',
        note: '備註摘要',
      ),
      _record(
        id: 'record-new',
        itemId: 'item-a',
        taskId: 'task-new',
        recordType: RecordType.repair,
        date: DateTime(2026, 7, 10),
        title: '最新紀錄',
        workDescription: '更換濾網',
        result: '已完成',
      ),
      _record(
        id: 'record-empty',
        itemId: 'item-a',
        recordType: RecordType.expiryHandled,
        date: DateTime(2026, 4, 1),
        title: '空欄位紀錄',
        workDescription: '',
        issueDescription: '',
        note: '',
      ),
    ];
    final schedules = [_schedule(id: 'schedule-1', itemId: 'item-a')];
    final tasks = [
      _task(id: 'task-1', itemId: 'item-a', scheduleId: 'schedule-1'),
    ];
    await _setLocalData(records: records, schedules: schedules, tasks: tasks);
    final beforeRecords = await _storedValue('maintenance_records');
    final beforeSchedules = await _storedValue('schedules');
    final beforeTasks = await _storedValue('tasks');

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('2026 年 7 月'), findsOneWidget);
    expect(find.text('2026 年 6 月'), findsOneWidget);
    expect(find.text('2026 年 5 月'), findsOneWidget);
    expect(find.text('2026 年 4 月'), findsOneWidget);
    expect(
      tester.getTopLeft(find.text('最新紀錄')).dy,
      lessThan(tester.getTopLeft(find.text('較舊紀錄')).dy),
    );
    expect(find.text('冷氣'), findsWidgets);
    expect(find.text('車子'), findsOneWidget);
    expect(find.text('未命名物品'), findsOneWidget);
    expect(find.text('維修'), findsWidgets);
    expect(find.text('保養'), findsWidgets);
    expect(find.text('其他'), findsWidgets);
    expect(find.text('到期提醒'), findsWidgets);
    expect(find.text('更換濾網'), findsOneWidget);
    expect(find.text('有異音'), findsOneWidget);
    expect(find.text('備註摘要'), findsOneWidget);
    expect(find.text('已留下保養維修紀錄。'), findsOneWidget);

    await tester.tap(find.text('最新紀錄'));
    await tester.pumpAndSettle();

    expect(find.text('任務 ID'), findsOneWidget);
    expect(find.text('task-new'), findsOneWidget);
    expect(await _storedValue('maintenance_records'), beforeRecords);
    expect(await _storedValue('schedules'), beforeSchedules);
    expect(await _storedValue('tasks'), beforeTasks);
  });

  testWidgets('empty history state remains renderable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyHistoryState())),
    );

    expect(find.text('目前還沒有履歷紀錄。'), findsOneWidget);
  });
}

Future<void> _setLocalData({
  required List<MaintenanceRecord> records,
  List<Item>? items,
  List<Schedule> schedules = const [],
  List<Task> tasks = const [],
}) async {
  SharedPreferences.resetStatic();
  final storedItems = items ?? [_item('item-a', '冷氣'), _item('item-b', '車子')];
  SharedPreferences.setMockInitialValues({
    'items': jsonEncode(storedItems.map((item) => item.toJson()).toList()),
    'maintenance_records': jsonEncode(
      records.map((record) => record.toJson()).toList(),
    ),
    'schedules': jsonEncode(
      schedules.map((schedule) => schedule.toJson()).toList(),
    ),
    'tasks': jsonEncode(tasks.map((task) => task.toJson()).toList()),
  });
}

Item _item(String id, String name) {
  return Item(
    id: id,
    name: name,
    category: ItemCategory.appliance,
    createdAt: DateTime(2026, 1, 1),
  );
}

MaintenanceRecord _record({
  required String id,
  required String itemId,
  String? taskId,
  required RecordType recordType,
  required DateTime date,
  required String title,
  String? issueDescription,
  String? workDescription,
  String? note,
  String? result,
}) {
  return MaintenanceRecord(
    id: id,
    itemId: itemId,
    taskId: taskId,
    recordType: recordType,
    date: date,
    title: title,
    issueDescription: issueDescription,
    workDescription: workDescription,
    note: note,
    result: result,
    createdAt: date,
  );
}

Schedule _schedule({required String id, required String itemId}) {
  return Schedule(
    id: id,
    itemId: itemId,
    cardId: 'card-aircon-maintenance',
    cycleType: CycleType.monthly,
    interval: 1,
    startDate: DateTime(2026, 1, 1),
    nextDueDate: DateTime(2026, 7, 1),
  );
}

Task _task({
  required String id,
  required String itemId,
  required String scheduleId,
}) {
  return Task(
    id: id,
    itemId: itemId,
    cardId: 'card-aircon-maintenance',
    scheduleId: scheduleId,
    title: '冷氣保養',
    dueDate: DateTime(2026, 7, 1),
  );
}

Future<String?> _storedValue(String key) async {
  final preferences = await SharedPreferences.getInstance();
  return preferences.getString(key);
}
