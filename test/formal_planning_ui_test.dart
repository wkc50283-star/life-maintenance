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
import 'package:life_maintenance/screens/formal_planning_screens.dart';
import 'package:life_maintenance/screens/item_detail_screen.dart';

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

  testWidgets('Add screen creates a formal plan and hands off to its Item', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _seedItem(editor, now, id: 'item-first', name: '其他設備');
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('保養項目與步驟'));
    await tester.pumpAndSettle();
    expect(find.byType(PlanningContentScreen), findsOneWidget);
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('item-ac');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('plan-title')), '清洗濾網');
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('add-plan-step')),
      200,
      scrollable: find
          .descendant(
            of: find.byKey(const ValueKey('item-form-scroll')),
            matching: find.byType(Scrollable),
          )
          .first,
    );
    await tester.tap(find.byKey(const ValueKey('add-plan-step')));
    await tester.pumpAndSettle();
    await tester.enterText(find.widgetWithText(TextFormField, '步驟名稱'), '關閉電源');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final plan = (await editor.loadPlans('item-ac')).single;
    expect(plan.itemId, 'item-ac');
    expect(plan.steps.single.title, '關閉電源');
    expect(await editor.loadPlans('item-first'), isEmpty);
    final detail = tester.widget<ItemDetailScreen>(
      find.byType(ItemDetailScreen),
    );
    expect(detail.item.id, 'item-ac');
    expect(find.text('清洗濾網'), findsOneWidget);
    expect(find.textContaining('尚未建立排程'), findsOneWidget);
    expect(await root.scheduleRepository.loadSchedules(), isEmpty);
    expect(await root.taskRepository.loadTasks(), isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AddScreen), findsOneWidget);
    expect(find.byType(PlanningContentScreen), findsNothing);
  });

  testWidgets('Item detail management refreshes created and edited plans', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    final item = (await root.itemReadRepository.loadItems()).single;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(home: ItemDetailScreen(item: item)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('管理').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').first);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('plan-title')), '清洗濾網');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.text('清洗濾網'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('清洗濾網'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('管理').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('清洗濾網'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('plan-title')), '清洗冷氣濾網');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.text('清洗冷氣濾網'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('清洗冷氣濾網'), findsOneWidget);
    expect((await editor.loadPlans('item-ac')).single.title, '清洗冷氣濾網');
  });

  testWidgets('cancelled and failed plan creation do not report success', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(
          home: PlanningContentScreen(
            kind: PlanningContentKind.maintenancePlan,
            initialItemId: 'item-ac',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await editor.loadPlans('item-ac'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('plan-title')), '不應建立');
    await database.close();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.byType(MaintenancePlanFormScreen), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });

  testWidgets(
    'Add screen creates a formal reminder and hands off to its Item',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _seedItem(editor, now, id: 'item-first', name: '其他設備');
      await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: AddScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('一般提醒'));
      await tester.pumpAndSettle();
      expect(find.byType(PlanningContentScreen), findsOneWidget);
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('item-ac');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('reminder-title')),
        '保固到期',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, '補充說明（選填）'),
        '確認是否需要續約',
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      final reminder = (await editor.loadReminders('item-ac')).single;
      expect(reminder.itemId, 'item-ac');
      expect(reminder.reminderType, 'expiry');
      expect(reminder.description, '確認是否需要續約');
      expect(await editor.loadReminders('item-first'), isEmpty);
      final detail = tester.widget<ItemDetailScreen>(
        find.byType(ItemDetailScreen),
      );
      expect(detail.item.id, 'item-ac');
      expect(find.text('保固到期'), findsNWidgets(2));
      expect(find.text('到期提醒'), findsOneWidget);
      expect(find.text('確認是否需要續約'), findsOneWidget);
      expect(await root.scheduleRepository.loadSchedules(), isEmpty);
      expect(await root.taskRepository.loadTasks(), isEmpty);
      final history = await root.historyProjectionRepository.projectForItem(
        'item-ac',
      );
      expect(history.entries, isEmpty);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AddScreen), findsOneWidget);
      expect(find.byType(PlanningContentScreen), findsNothing);
    },
  );

  testWidgets('Item detail management refreshes created and edited reminders', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    final item = (await root.itemReadRepository.loadItems()).single;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(home: ItemDetailScreen(item: item)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('管理').at(1),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-title')),
      '保固到期',
    );
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.text('保固到期'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('保固到期'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('管理').at(1),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保固到期'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-title')),
      '冷氣保固到期',
    );
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.text('冷氣保固到期'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.text('冷氣保固到期'), findsOneWidget);
    expect((await editor.loadReminders('item-ac')).single.title, '冷氣保固到期');
  });

  testWidgets('cancelled and failed reminder creation do not report success', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(
          home: PlanningContentScreen(
            kind: PlanningContentKind.reminder,
            initialItemId: 'item-ac',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(await editor.loadReminders('item-ac'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('reminder-title')),
      '不應建立',
    );
    await database.close();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.byType(ReminderFormScreen), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });
}

Future<void> _seedItem(
  FormalPlanningEditor editor,
  DateTime now, {
  required String id,
  required String name,
}) async {
  final categoryId = 'category-$id';
  await editor.saveCategory(
    EditableCategory(
      id: categoryId,
      systemCode: 'homeAndAppliance',
      displayName: '家中設備',
      sortOrder: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await editor.saveItem(
    EditableItem(
      id: id,
      name: name,
      categoryId: categoryId,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
}
