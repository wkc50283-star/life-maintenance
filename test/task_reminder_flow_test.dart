import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/screens/today_screen.dart';

void main() {
  testWidgets(
    'Task detail shows its source and starts a WorkCase without completing Task',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 1600);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final database = AppDatabase(NativeDatabase.memory());
      addTearDown(database.close);
      final root = AppCompositionRoot(database: database);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 8);
      await _seed(root, today);
      final before = await root.driftRepositories.tasks.findById('task-1');

      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('租約續約').first);
      await tester.pumpAndSettle();

      expect(find.text('提醒詳情'), findsOneWidget);
      expect(find.text('一般提醒'), findsOneWidget);
      expect(find.text('依固定曆法週期'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '重新安排'), findsOneWidget);
      expect(find.widgetWithText(OutlinedButton, '暫停提醒'), findsOneWidget);
      expect(find.widgetWithText(FilledButton, '開始處理'), findsOneWidget);
      expect(find.text('完成提醒'), findsNothing);
      expect(find.text('正式結案'), findsNothing);
      expect(find.text('寫入史略'), findsNothing);

      await tester.tap(find.widgetWithText(FilledButton, '開始處理'));
      await tester.pumpAndSettle();
      expect(find.text('把事情接成一筆案件'), findsOneWidget);
      expect(find.textContaining('原提醒不會被完成或消失'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, '建立進行中案件'));
      await tester.pumpAndSettle();

      expect(await root.driftRepositories.tasks.findById('task-1'), before);
      final cases = await root.workCaseRuntime.listCasesForItem('item-1');
      expect(cases, hasLength(1));
      expect(cases.single.title, '租約續約');
      expect(cases.single.isOpen, isTrue);
      expect(
        await root.driftRepositories.workCaseClosures.findForCase(
          cases.single.id,
        ),
        isNull,
      );
      expect(
        await root.driftRepositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );
    },
  );

  testWidgets('paused Task can be restored from the all reminders entry', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final root = AppCompositionRoot(database: database);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 8);
    await _seed(root, today);

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('租約續約').first);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '暫停提醒'));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(OutlinedButton, '恢復提醒'), findsOneWidget);
    expect(
      (await root.driftRepositories.tasks.findById('task-1'))?.status,
      TaskStatus.postponed.name,
    );

    await tester.pageBack();
    await tester.pumpAndSettle();
    await tester.tap(find.text('查看全部'));
    await tester.pumpAndSettle();
    expect(find.text('租約續約'), findsOneWidget);
    expect(find.text('已暫停'), findsOneWidget);
    await tester.tap(find.text('租約續約'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(OutlinedButton, '恢復提醒'));
    await tester.pumpAndSettle();

    expect(
      (await root.driftRepositories.tasks.findById('task-1'))?.status,
      TaskStatus.pending.name,
    );
  });
}

Future<void> _seed(AppCompositionRoot root, DateTime now) async {
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'document',
      displayName: '文件',
      sortOrder: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: 'item-1',
      name: '房屋租約',
      categoryId: 'category-1',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.generalReminders.save(
    GeneralReminderRow(
      schemaVersion: 1,
      id: 'reminder-1',
      itemId: 'item-1',
      title: '租約續約',
      description: '確認續約條件',
      reminderType: 'expiry',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-1',
      itemId: 'item-1',
      sourceType: 'generalReminder',
      generalReminderId: 'reminder-1',
      cycleType: 'yearly',
      interval: 1,
      startDate: now,
      nextDueDate: now,
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.tasks.save(
    TaskRow(
      id: 'task-1',
      itemId: 'item-1',
      sourceType: 'scheduledReminder',
      scheduleId: 'schedule-1',
      generalReminderId: 'reminder-1',
      title: '租約續約',
      dueDate: now,
      status: TaskStatus.pending.name,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
