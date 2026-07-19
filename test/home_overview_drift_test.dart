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
    tester.view.physicalSize = const Size(430, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日提醒 0'), findsOneWidget);
    expect(find.text('進行中案件 0'), findsOneWidget);
    expect(find.text('階段性重點 0'), findsOneWidget);
    expect(find.text('今天沒有需要留意的提醒。'), findsOneWidget);
    expect(find.text('目前沒有進行中的案件。'), findsOneWidget);
    expect(find.text('目前還沒有完成紀錄。'), findsOneWidget);
    expect(find.text('客廳冷氣'), findsNothing);
    expect(find.text('冷氣異音檢查'), findsNothing);
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
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('今日提醒 1'), findsOneWidget);
    expect(find.text('進行中案件 1'), findsOneWidget);
    expect(find.text('階段性重點 1'), findsOneWidget);
    expect(find.text('確認冷氣運轉'), findsOneWidget);
    expect(find.text('下個月再確認'), findsNothing);
    expect(find.text('冷氣異音檢查'), findsOneWidget);
    expect(find.text('下一步：等待到府檢查'), findsOneWidget);
    expect(find.text('第六年全面檢查'), findsOneWidget);
    expect(find.text('完成冷氣濾網清潔'), findsOneWidget);
    expect(await root.driftRepositories.tasks.listAll(), hasLength(2));
    expect(await root.workCaseRuntime.listCasesForItem('item-1'), hasLength(1));
    expect(await root.milestoneRepository.listForItem('item-1'), hasLength(1));
    expect(await root.maintenanceRecordRepository.listAll(), hasLength(1));
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
