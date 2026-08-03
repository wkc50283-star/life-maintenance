import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/screens/today_screen.dart';

void main() {
  testWidgets('empty Drift overview contains no fixture facts', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 932);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    var quickAddCount = 0;

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(
          home: Scaffold(
            body: TodayScreen(
              onQuickAdd: () => quickAddCount++,
              showQuickCapture: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('安，國政'), findsOneWidget);
    expect(find.textContaining('星期'), findsOneWidget);
    expect(find.text('還沒有生活項目'), findsOneWidget);
    expect(find.text('今天發生了什麼？'), findsNothing);
    expect(find.text('記錄生活，AI 幫你整理'), findsNothing);
    expect(find.text('新增生活項目'), findsOneWidget);
    expect(
      tester.getSize(find.byKey(const ValueKey('overview-empty-items'))).height,
      greaterThan(0),
    );
    expect(find.text('今天需要處理'), findsNothing);
    expect(find.text('進行中案件'), findsNothing);
    expect(find.text('階段性重點'), findsNothing);
    expect(find.text('最近完成'), findsNothing);
    expect(find.text('AI 建議管理'), findsOneWidget);
    expect(find.text('AI 建議功能尚未啟用'), findsOneWidget);
    expect(find.text('近期需要注意'), findsOneWidget);
    expect(find.text('近期沒有需要注意的事情'), findsOneWidget);
    expect(find.byKey(const ValueKey('overview-quick-add')), findsNothing);
    expect(find.text('系統建議你今天清潔冷氣'), findsNothing);
    expect(
      find.byKey(const ValueKey('overview-status-reminders')),
      findsNothing,
    );
    await tester.tap(find.text('新增生活項目').last);
    expect(quickAddCount, 1);
    final scrollable = find.descendant(
      of: find.byKey(const ValueKey('overview-scroll')),
      matching: find.byType(Scrollable),
    );
    for (final key in const [
      ValueKey('overview-capture-photo'),
      ValueKey('overview-capture-voice'),
      ValueKey('overview-capture-text'),
    ]) {
      await tester.scrollUntilVisible(
        find.byKey(key),
        160,
        scrollable: scrollable,
      );
      await tester.tap(find.byKey(key));
    }
    expect(quickAddCount, 4);
    expect(find.text('今天想記錄什麼？'), findsNothing);
    expect(find.text('客廳冷氣'), findsNothing);
    expect(find.text('冷氣異音檢查'), findsNothing);
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('語音'), findsOneWidget);
    expect(find.text('說一句'), findsNothing);
    expect(find.text('輸入'), findsOneWidget);
    expect(
      tester
          .getSize(find.byKey(const ValueKey('overview-capture-section')))
          .height,
      lessThan(140),
    );
    expect(find.text('拍一張照片'), findsNothing);
    expect(find.text('語音說一段話'), findsNothing);
    expect(find.text('打幾個字'), findsNothing);
    final aiTop = tester.getTopLeft(find.text('AI 建議管理')).dy;
    final focusTop = tester.getTopLeft(find.text('近期需要注意')).dy;
    final captureTop = tester
        .getTopLeft(find.byKey(const ValueKey('overview-capture-section')))
        .dy;
    expect(aiTop, lessThan(focusTop));
    expect(focusTop, lessThan(captureTop));
    await database.close();
  });

  testWidgets('life overview projects every formal section from Drift facts', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    await _seedItem(root, today);
    await root.driftRepositories.tasks.save(
      TaskRow(
        id: 'task-today',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '確認冷氣運轉',
        dueDate: today,
        status: TaskStatus.pending.name,
        createdAt: today,
        updatedAt: today,
      ),
    );
    await root.driftRepositories.tasks.save(
      TaskRow(
        id: 'task-future',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '下個月再確認',
        dueDate: today.add(const Duration(days: 30)),
        status: TaskStatus.pending.name,
        createdAt: today,
        updatedAt: today,
      ),
    );
    await root.workCaseRuntime.createManual(
      WorkCase(
        id: 'case-1',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.repair,
        title: '冷氣異音檢查',
        status: WorkCaseStatus.waiting,
        createdAt: today.subtract(const Duration(days: 2)),
        updatedAt: today.subtract(const Duration(days: 1)),
      ),
      initialUpdate: WorkCaseUpdate(
        id: 'update-1',
        workCaseId: 'case-1',
        occurredAt: today.subtract(const Duration(days: 1)),
        description: '已聯絡維修人員',
        nextAction: '等待到府檢查',
        createdAt: today.subtract(const Duration(days: 1)),
      ),
    );
    await root.milestoneRepository.save(
      Milestone(
        id: 'milestone-1',
        itemId: 'item-1',
        title: '第六年全面檢查',
        kind: MilestoneKind.deepInspection,
        triggerType: MilestoneTriggerType.specificDate,
        triggerDate: today.add(const Duration(days: 20)),
        status: MilestoneStatus.pending,
        createdAt: today.subtract(const Duration(days: 10)),
        updatedAt: today,
      ),
    );
    await root.maintenanceRecordRepository.createSimpleRecord(
      MaintenanceRecord(
        id: 'record-1',
        itemId: 'item-1',
        recordType: RecordType.regularMaintenance,
        date: today.subtract(const Duration(days: 3)),
        title: '完成冷氣濾網清潔',
        result: '運轉正常',
        createdAt: today.subtract(const Duration(days: 3)),
      ),
    );

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(
          home: Scaffold(body: TodayScreen(showQuickCapture: true)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('overview-status-reminders')),
      findsNothing,
    );
    expect(find.text('今天需要處理（1）'), findsOneWidget);
    expect(find.text('進行中案件'), findsNothing);
    expect(find.text('最近完成'), findsOneWidget);
    expect(find.text('AI 建議管理'), findsOneWidget);
    expect(find.text('AI 建議功能尚未啟用'), findsOneWidget);
    expect(find.text('近期需要注意'), findsOneWidget);
    expect(find.text('近期沒有需要注意的事情'), findsNothing);
    expect(
      find.byKey(const ValueKey('overview-focus-task-today')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('overview-quick-add')), findsNothing);
    expect(find.text('確認冷氣運轉'), findsOneWidget);
    expect(find.text('已安排'), findsOneWidget);
    expect(find.text('下個月再確認'), findsNothing);
    expect(find.text('冷氣異音檢查'), findsNothing);
    expect(find.text('下一步：等待到府檢查'), findsNothing);
    expect(find.text('第六年全面檢查'), findsNothing);
    expect(find.text('已逾期'), findsNothing);
    expect(find.text('已達標'), findsNothing);
    expect(find.text('完成冷氣濾網清潔'), findsOneWidget);
    expect(await root.driftRepositories.tasks.listAll(), hasLength(2));
    expect(await root.workCaseRuntime.listCasesForItem('item-1'), hasLength(1));
    expect(await root.milestoneRepository.listForItem('item-1'), hasLength(1));
    expect(await root.maintenanceRecordRepository.listAll(), hasLength(1));

    final reminderTop = tester.getTopLeft(find.text('今天需要處理（1）')).dy;
    final completionTop = tester.getTopLeft(find.text('最近完成')).dy;
    final aiTop = tester.getTopLeft(find.text('AI 建議管理')).dy;
    final focusTop = tester.getTopLeft(find.text('近期需要注意')).dy;
    final captureTop = tester
        .getTopLeft(find.byKey(const ValueKey('overview-capture-section')))
        .dy;
    expect(reminderTop, lessThan(completionTop));
    expect(completionTop, lessThan(aiTop));
    expect(aiTop, lessThan(focusTop));
    expect(focusTop, lessThan(captureTop));
    await database.close();
  });

  testWidgets('upcoming focus uses only the next seven days and caps at four', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 2400);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day, 9);
    await _seedItem(root, today);
    for (final task in [
      ('focus-past', -1, TaskStatus.pending),
      ('focus-0', 0, TaskStatus.pending),
      ('focus-1', 1, TaskStatus.pending),
      ('focus-2', 2, TaskStatus.pending),
      ('focus-3', 3, TaskStatus.pending),
      ('focus-4', 4, TaskStatus.pending),
      ('focus-7', 7, TaskStatus.pending),
      ('focus-8', 8, TaskStatus.pending),
      ('focus-completed', 1, TaskStatus.completed),
      ('focus-paused', 1, TaskStatus.postponed),
    ]) {
      await root.driftRepositories.tasks.save(
        TaskRow(
          id: task.$1,
          itemId: 'item-1',
          sourceType: 'manual',
          title: task.$1,
          dueDate: today.add(Duration(days: task.$2)),
          status: task.$3.name,
          createdAt: today,
          updatedAt: today,
        ),
      );
    }

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();

    for (final id in const ['focus-0', 'focus-1', 'focus-2', 'focus-3']) {
      expect(find.byKey(ValueKey('overview-focus-$id')), findsOneWidget);
    }
    for (final id in const [
      'focus-past',
      'focus-4',
      'focus-7',
      'focus-8',
      'focus-completed',
      'focus-paused',
    ]) {
      expect(find.byKey(ValueKey('overview-focus-$id')), findsNothing);
    }
    final tops = [
      for (final id in const ['focus-0', 'focus-1', 'focus-2', 'focus-3'])
        tester.getTopLeft(find.byKey(ValueKey('overview-focus-$id'))).dy,
    ];
    expect(tops, orderedEquals([...tops]..sort()));
    expect(find.text('今天'), findsOneWidget);
    expect(find.text('明天'), findsOneWidget);
    expect(find.text('提醒'), findsNWidgets(4));
    expect(tester.takeException(), isNull);
    await database.close();
  });
}

Future<void> _seedItem(AppCompositionRoot root, DateTime createdAt) async {
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'homeAndAppliance',
      displayName: '家電與居家設備',
      sortOrder: 0,
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: 'item-1',
      name: '客廳冷氣',
      categoryId: 'category-1',
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}
