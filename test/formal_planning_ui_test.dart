import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/maintenance_plan_step.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/repositories/formal_planning_editor.dart';
import 'package:life_maintenance/screens/add_screen.dart';

void main() {
  late AppDatabase database;
  late AppCompositionRoot root;
  late FormalPlanningEditor editor;
  late DateTime now;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    root = AppCompositionRoot(database: database);
    editor = FormalPlanningEditor.from(root)!;
    now = DateTime.utc(2026, 7, 19, 9);
  });

  tearDown(() => database.close());

  test(
    'formal editor preserves Item root and all planning source roles',
    () async {
      await editor.saveCategory(
        EditableCategory(
          id: 'category-home',
          systemCode: 'homeAndAppliance',
          customName: '家中設備',
          displayName: '家中設備',
          sortOrder: 1,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await editor.saveItem(
        EditableItem(
          id: 'item-ac',
          name: '客廳冷氣',
          categoryId: 'category-home',
          location: '客廳',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await editor.savePlan(
        MaintenancePlan(
          id: 'plan-filter',
          itemId: 'item-ac',
          title: '清洗濾網',
          planType: MaintenancePlanType.cleaning,
          riskLevel: RiskLevel.low,
          createdAt: now,
          updatedAt: now,
          steps: const [
            MaintenancePlanStep(
              id: 'step-power',
              order: 0,
              title: '關閉電源',
              description: '先確認設備停止運轉',
            ),
          ],
        ),
      );
      await editor.saveReminder(
        EditableReminder(
          id: 'reminder-warranty',
          itemId: 'item-ac',
          title: '保固到期',
          reminderType: 'expiry',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await editor.saveMilestone(
        Milestone(
          id: 'milestone-overhaul',
          itemId: 'item-ac',
          title: '使用第六年全面檢查',
          kind: MilestoneKind.majorService,
          triggerType: MilestoneTriggerType.usageYears,
          thresholdValue: 6,
          thresholdUnit: '年',
          status: MilestoneStatus.pending,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await editor.saveSchedule(
        EditableSchedule(
          id: 'schedule-filter',
          itemId: 'item-ac',
          sourceType: 'maintenancePlan',
          sourceId: 'plan-filter',
          cycleType: 'monthly',
          interval: 1,
          startDate: now,
          nextDueDate: DateTime.utc(2026, 8, 19),
          status: 'active',
          anchorPolicy: 'fixedCalendarPeriod',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect((await editor.loadCategories()).single.displayName, '家中設備');
      expect((await editor.loadItems()).single.name, '客廳冷氣');
      expect(
        (await editor.loadPlans('item-ac')).single.steps.single.title,
        '關閉電源',
      );
      expect(
        (await editor.loadReminders('item-ac')).single.reminderType,
        'expiry',
      );
      expect(
        (await editor.loadMilestones('item-ac')).single.kind,
        MilestoneKind.majorService,
      );
      final schedule = (await editor.loadSchedules('item-ac')).single;
      expect(schedule.sourceType, 'maintenancePlan');
      expect(schedule.sourceId, 'plan-filter');
      expect(schedule.anchorPolicy, 'fixedCalendarPeriod');
    },
  );

  testWidgets('formal Add screen exposes plain-language approved editors', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('生活項目'), findsOneWidget);
    expect(find.text('分類'), findsOneWidget);
    expect(find.text('保養項目與步驟'), findsOneWidget);
    expect(find.text('一般提醒'), findsOneWidget);
    expect(find.text('階段性重點'), findsOneWidget);
    expect(find.text('提醒排程'), findsOneWidget);
    expect(find.text('補登完成紀錄'), findsNothing);
    expect(find.textContaining('MaintenancePlan'), findsNothing);
    expect(find.textContaining('AnchorPolicy'), findsNothing);
  });

  testWidgets('category create form writes through the formal repository', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('分類'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-name')), '家中證件');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    expect(find.text('家中證件'), findsOneWidget);
    final categories = await editor.loadCategories();
    expect(categories.single.customName, '家中證件');
    expect(categories.single.systemCode, isNull);
  });
}
