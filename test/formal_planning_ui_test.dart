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
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/repositories/formal_planning_editor.dart';
import 'package:life_maintenance/screens/add_screen.dart';
import 'package:life_maintenance/screens/formal_planning_screens.dart';
import 'package:life_maintenance/screens/item_detail_screen.dart';
import 'package:life_maintenance/screens/work_case_screens.dart';

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
    expect(find.text('突發事項／工程'), findsOneWidget);
    expect(find.text('補登完成紀錄'), findsNothing);
    expect(find.textContaining('MaintenancePlan'), findsNothing);
    expect(find.textContaining('AnchorPolicy'), findsNothing);
  });

  testWidgets('manual WorkCase entry refuses to create without an Item', (
    tester,
  ) async {
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await _openManualWorkCaseForm(tester);

    expect(find.byType(ManualWorkCaseFormScreen), findsOneWidget);
    expect(find.text('目前還沒有生活項目'), findsOneWidget);
    expect(find.byKey(const ValueKey('manual-case-save')), findsNothing);
  });

  testWidgets(
    'Add screen creates the selected manual WorkCase with one optional update',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1400);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _seedItem(editor, now, id: 'item-first', name: '其他設備');
      await _seedItem(editor, now, id: 'item-target', name: '浴室漏水');
      await root.workCaseRuntime.createManual(
        WorkCase(
          id: 'case-existing',
          itemId: 'item-first',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.other,
          title: '既有案件',
          status: WorkCaseStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: AddScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await _openManualWorkCaseForm(tester);
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('manual-case-item')),
          )
          .onChanged!('item-target');
      tester
          .widget<DropdownButtonFormField<WorkCaseType>>(
            find.byKey(const ValueKey('manual-case-type')),
          )
          .onChanged!(WorkCaseType.construction);
      await tester.enterText(
        find.byKey(const ValueKey('manual-case-title')),
        '  浴室防水修繕  ',
      );
      await tester.enterText(
        find.byKey(const ValueKey('manual-case-initial-update')),
        '  已確認牆角持續滲水  ',
      );
      await tester.tap(find.byKey(const ValueKey('manual-case-save')));
      await tester.tap(find.byKey(const ValueKey('manual-case-save')));
      await tester.pumpAndSettle();

      expect(find.byType(WorkCaseDetailScreen), findsOneWidget);
      expect(find.text('浴室防水修繕'), findsOneWidget);
      expect(find.text('已確認牆角持續滲水'), findsOneWidget);
      expect(find.text('既有案件'), findsNothing);
      final targetCases = await root.workCaseRuntime.listCasesForItem(
        'item-target',
      );
      expect(targetCases, hasLength(1));
      final created = targetCases.single;
      expect(created.sourceType, WorkCaseSourceType.manual);
      expect(created.sourceId, isNull);
      expect(created.sourceTaskId, isNull);
      expect(created.itemId, 'item-target');
      expect(created.title, '浴室防水修繕');
      expect(created.caseType, WorkCaseType.construction);
      expect(created.status, WorkCaseStatus.inProgress);
      final updates = await root.workCaseRuntime.listUpdatesForCase(created.id);
      expect(updates, hasLength(1));
      expect(updates.single.workCaseId, created.id);
      expect(updates.single.description, '已確認牆角持續滲水');
      expect(
        (await root.historyProjectionRepository.projectForItem(
          'item-target',
        )).entries,
        isEmpty,
      );

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(AddScreen), findsOneWidget);
    },
  );

  testWidgets('manual WorkCase validates title and omits a blank update', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-target', name: '客廳窗戶');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await _openManualWorkCaseForm(tester);

    tester
        .widget<DropdownButtonFormField<String>>(
          find.byKey(const ValueKey('manual-case-item')),
        )
        .onChanged!('item-target');
    tester
        .widget<DropdownButtonFormField<WorkCaseType>>(
          find.byKey(const ValueKey('manual-case-type')),
        )
        .onChanged!(WorkCaseType.repair);
    await tester.enterText(
      find.byKey(const ValueKey('manual-case-title')),
      '   ',
    );
    await _tapManualWorkCaseSave(tester);
    expect(find.text('請填寫案件標題'), findsOneWidget);
    expect(await root.workCaseRuntime.listCasesForItem('item-target'), isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('manual-case-title')),
      '窗戶把手鬆動',
    );
    await tester.enterText(
      find.byKey(const ValueKey('manual-case-initial-update')),
      '   ',
    );
    await _tapManualWorkCaseSave(tester);

    final created = (await root.workCaseRuntime.listCasesForItem(
      'item-target',
    )).single;
    expect(await root.workCaseRuntime.listUpdatesForCase(created.id), isEmpty);
  });

  testWidgets('canceling the manual WorkCase form writes nothing', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-target', name: '陽台門');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await _openManualWorkCaseForm(tester);
    await tester.enterText(
      find.byKey(const ValueKey('manual-case-title')),
      '陽台門卡住',
    );

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.byType(AddScreen), findsOneWidget);
    expect(await root.workCaseRuntime.listCasesForItem('item-target'), isEmpty);
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
      expect(find.text('保固到期'), findsOneWidget);
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
    await tester.scrollUntilVisible(
      find.text('保固到期').first,
      200,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('保固到期'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('管理').at(1),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').at(1));
    await tester.pumpAndSettle();
    await tester.tap(find.text('保固到期').first);
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

  testWidgets(
    'Add screen creates a formal milestone and hands off to its Item',
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

      await tester.tap(find.text('階段性重點'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('item-ac');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('milestone-title')),
        '評估汰換冷氣',
      );
      await _selectMilestoneDate(tester);
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      final milestone = (await editor.loadMilestones('item-ac')).single;
      expect(milestone.itemId, 'item-ac');
      expect(milestone.triggerType, MilestoneTriggerType.specificDate);
      expect(milestone.triggerDate, isNotNull);
      expect(await editor.loadMilestones('item-first'), isEmpty);
      final detail = tester.widget<ItemDetailScreen>(
        find.byType(ItemDetailScreen),
      );
      expect(detail.item.id, 'item-ac');
      expect(find.text('評估汰換冷氣'), findsOneWidget);
      expect(find.textContaining('日期'), findsWidgets);
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

  testWidgets(
    'Item detail management refreshes created and edited milestones',
    (tester) async {
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
        find.text('管理').at(3),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('管理').at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-entry')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('milestone-title')),
        '評估汰換冷氣',
      );
      await _selectMilestoneDate(tester);
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();
      expect(find.text('評估汰換冷氣'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.text('評估汰換冷氣'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('管理').at(3),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.text('管理').at(3));
      await tester.pumpAndSettle();
      await tester.tap(find.text('評估汰換冷氣'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('milestone-title')),
        '評估更新冷氣',
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();
      expect(find.text('評估更新冷氣'), findsOneWidget);

      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ItemDetailScreen), findsOneWidget);
      expect(find.text('評估更新冷氣'), findsOneWidget);
      expect((await editor.loadMilestones('item-ac')).single.title, '評估更新冷氣');
    },
  );

  testWidgets('milestone relations remain scoped to the selected Item', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await _seedItem(editor, now, id: 'item-other', name: '其他設備');
    await editor.savePlan(
      MaintenancePlan(
        id: 'plan-ac',
        itemId: 'item-ac',
        title: '冷氣大保養',
        planType: MaintenancePlanType.inspection,
        riskLevel: RiskLevel.low,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await editor.savePlan(
      MaintenancePlan(
        id: 'plan-other',
        itemId: 'item-other',
        title: '其他保養',
        planType: MaintenancePlanType.inspection,
        riskLevel: RiskLevel.low,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await editor.saveMilestone(
      Milestone(
        id: 'milestone-previous',
        itemId: 'item-ac',
        title: '完成前期評估',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await editor.saveMilestone(
      Milestone(
        id: 'milestone-other',
        itemId: 'item-other',
        title: '其他設備重點',
        kind: MilestoneKind.majorService,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: MilestoneFormScreen(itemId: 'item-ac')),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('milestone-title')),
      '依前期結果安排汰換',
    );
    tester
        .widget<DropdownButtonFormField<MilestoneTriggerType>>(
          find.byKey(const ValueKey('milestone-trigger')),
        )
        .onChanged!(MilestoneTriggerType.dependencyCompleted);
    await tester.pumpAndSettle();
    final relationFields = tester.widgetList<DropdownButtonFormField<String>>(
      find.byType(DropdownButtonFormField<String>),
    );
    relationFields.first.onChanged!('milestone-previous');
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<String?>>(
          find.byType(DropdownButtonFormField<String?>),
        )
        .onChanged!('plan-ac');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final created = (await editor.loadMilestones(
      'item-ac',
    )).singleWhere((entry) => entry.title == '依前期結果安排汰換');
    expect(created.sourcePlanId, 'plan-ac');
    expect(created.dependencyMilestoneId, 'milestone-previous');
    expect(created.sourcePlanId, isNot('plan-other'));
    expect(created.dependencyMilestoneId, isNot('milestone-other'));
  });

  testWidgets('milestone completion confirms, reloads, and returns changed', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    final milestone = Milestone(
      id: 'milestone-complete',
      itemId: 'item-ac',
      title: '評估汰換冷氣',
      description: '保留說明',
      kind: MilestoneKind.replacementEvaluation,
      triggerType: MilestoneTriggerType.specificDate,
      triggerDate: DateTime.utc(2027, 7, 19),
      status: MilestoneStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await editor.saveMilestone(milestone);
    Object? result;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => MilestoneFormScreen(
                        itemId: 'item-ac',
                        value: milestone,
                        usesTypedResult: true,
                      ),
                    ),
                  );
                },
                child: const Text('開啟'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開啟'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('milestone-complete')), findsOneWidget);
    await tester.ensureVisible(
      find.byKey(const ValueKey('milestone-complete')),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('milestone-complete')));
    await tester.pumpAndSettle();
    expect(find.text('完成這個階段重點？'), findsOneWidget);
    expect(find.text('完成後會留下紀錄。'), findsOneWidget);
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(
      (await editor.loadMilestones('item-ac')).single.status,
      MilestoneStatus.pending,
    );

    await tester.tap(find.byKey(const ValueKey('milestone-complete')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認完成'));
    await tester.pumpAndSettle();
    final completed = (await editor.loadMilestones('item-ac')).single;
    expect(completed.status, MilestoneStatus.completed);
    expect(completed.completedAt, isNotNull);
    expect(completed.updatedAt, completed.completedAt);
    expect(completed.triggerDate, milestone.triggerDate);
    expect(find.text('階段性重點已完成。'), findsOneWidget);
    expect(find.byKey(const ValueKey('milestone-complete')), findsNothing);
    expect(find.byKey(const ValueKey('save-form')), findsNothing);
    expect(find.textContaining('完成時間：'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, isA<MilestoneFormResult>());
  });

  testWidgets('milestone cancellation requires reason and returns changed', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    final milestone = Milestone(
      id: 'milestone-cancel',
      itemId: 'item-ac',
      title: '不再追蹤汰換評估',
      description: '保留原始說明',
      kind: MilestoneKind.replacementEvaluation,
      triggerType: MilestoneTriggerType.specificDate,
      triggerDate: DateTime.utc(2027, 8, 19),
      status: MilestoneStatus.pending,
      createdAt: now,
      updatedAt: now,
    );
    await editor.saveMilestone(milestone);
    Object? result;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<Object?>(
                    MaterialPageRoute(
                      builder: (_) => MilestoneFormScreen(
                        itemId: 'item-ac',
                        value: milestone,
                        usesTypedResult: true,
                      ),
                    ),
                  );
                },
                child: const Text('開啟取消'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('開啟取消'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('milestone-cancel')));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('milestone-complete')), findsOneWidget);
    expect(find.byKey(const ValueKey('milestone-cancel')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('milestone-cancel')));
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('milestone-cancellation-continue')),
    );
    await tester.pumpAndSettle();
    expect(find.text('請輸入取消原因'), findsOneWidget);
    expect(
      (await editor.loadMilestones('item-ac')).single.status,
      MilestoneStatus.pending,
    );
    await tester.enterText(
      find.byKey(const ValueKey('milestone-cancellation-reason')),
      '  已改用其他方案  ',
    );
    await tester.tap(
      find.byKey(const ValueKey('milestone-cancellation-continue')),
    );
    await tester.pumpAndSettle();
    expect(find.text('取消這個階段重點？'), findsOneWidget);
    expect(find.text('取消後會保留紀錄，但不會再出現在待處理項目中。'), findsOneWidget);
    await tester.tap(find.text('返回'));
    await tester.pumpAndSettle();
    expect(
      (await editor.loadMilestones('item-ac')).single.status,
      MilestoneStatus.pending,
    );

    await tester.tap(find.byKey(const ValueKey('milestone-cancel')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('milestone-cancellation-reason')),
      '  已改用其他方案  ',
    );
    await tester.tap(
      find.byKey(const ValueKey('milestone-cancellation-continue')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認取消'));
    await tester.pumpAndSettle();
    final canceled = (await editor.loadMilestones('item-ac')).single;
    expect(canceled.status, MilestoneStatus.canceled);
    expect(canceled.canceledAt, isNotNull);
    expect(canceled.cancellationReason, '已改用其他方案');
    expect(canceled.updatedAt, canceled.canceledAt);
    expect(canceled.completedAt, isNull);
    expect(canceled.triggerDate, milestone.triggerDate);
    expect(find.text('階段性重點已取消。'), findsOneWidget);
    expect(find.byKey(const ValueKey('milestone-complete')), findsNothing);
    expect(find.byKey(const ValueKey('milestone-cancel')), findsNothing);
    expect(find.byKey(const ValueKey('save-form')), findsNothing);
    expect(find.textContaining('取消時間：'), findsOneWidget);
    expect(find.text('取消原因：已改用其他方案'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(result, isA<MilestoneFormResult>());
  });

  testWidgets('cancelled and failed milestone creation do not report success', (
    tester,
  ) async {
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(
          home: PlanningContentScreen(
            kind: PlanningContentKind.milestone,
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
    expect(await editor.loadMilestones('item-ac'), isEmpty);

    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('milestone-title')),
      '不應建立',
    );
    await _selectMilestoneDate(tester);
    await database.close();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.byType(MilestoneFormScreen), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });

  testWidgets('Add screen creates a plan schedule and hands off to its Item', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _seedItem(editor, now, id: 'item-first', name: '其他設備');
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await editor.savePlan(
      MaintenancePlan(
        id: 'plan-filter',
        itemId: 'item-ac',
        title: '清洗濾網',
        planType: MaintenancePlanType.cleaning,
        riskLevel: RiskLevel.low,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: AddScreen())),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('提醒排程'));
    await tester.pumpAndSettle();
    tester
        .widget<DropdownButtonFormField<String>>(
          find.byType(DropdownButtonFormField<String>),
        )
        .onChanged!('item-ac');
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('schedule-source')),
          )
          .initialValue,
      'maintenancePlan:plan-filter',
    );
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final schedule = (await editor.loadSchedules('item-ac')).single;
    expect(schedule.sourceType, 'maintenancePlan');
    expect(schedule.sourceId, 'plan-filter');
    expect(await editor.loadSchedules('item-first'), isEmpty);
    final detail = tester.widget<ItemDetailScreen>(
      find.byType(ItemDetailScreen),
    );
    expect(detail.item.id, 'item-ac');
    expect(find.text('清洗濾網'), findsWidgets);
    expect(find.textContaining('尚未建立排程'), findsNothing);
    expect(find.textContaining('下次'), findsWidgets);
    expect(await root.taskRepository.loadTasks(), isEmpty);
    final history = await root.historyProjectionRepository.projectForItem(
      'item-ac',
    );
    expect(history.entries, isEmpty);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(AddScreen), findsOneWidget);
    expect(find.byType(PlanningContentScreen), findsNothing);
  });

  testWidgets(
    'Add screen creates a reminder schedule and hands off to its Item',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(800, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await _seedItem(editor, now, id: 'item-first', name: '其他設備');
      await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
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
      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: AddScreen())),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('提醒排程'));
      await tester.pumpAndSettle();
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byType(DropdownButtonFormField<String>),
          )
          .onChanged!('item-ac');
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('add-entry')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('schedule-source')),
            )
            .initialValue,
        'generalReminder:reminder-warranty',
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      final schedule = (await editor.loadSchedules('item-ac')).single;
      expect(schedule.sourceType, 'generalReminder');
      expect(schedule.sourceId, 'reminder-warranty');
      expect(await editor.loadSchedules('item-first'), isEmpty);
      final detail = tester.widget<ItemDetailScreen>(
        find.byType(ItemDetailScreen),
      );
      expect(detail.item.id, 'item-ac');
      expect(find.text('保固到期'), findsWidgets);
      expect(find.textContaining('每月'), findsOneWidget);
      expect(await root.taskRepository.loadTasks(), isEmpty);
      final history = await root.historyProjectionRepository.projectForItem(
        'item-ac',
      );
      expect(history.entries, isEmpty);
    },
  );

  testWidgets('Item detail refreshes after schedule management changes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(800, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await _seedItem(editor, now, id: 'item-ac', name: '測試冷氣');
    await editor.savePlan(
      MaintenancePlan(
        id: 'plan-filter',
        itemId: 'item-ac',
        title: '清洗濾網',
        planType: MaintenancePlanType.cleaning,
        riskLevel: RiskLevel.low,
        createdAt: now,
        updatedAt: now,
      ),
    );
    final item = (await root.itemReadRepository.loadItems()).single;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(home: ItemDetailScreen(item: item)),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('尚未建立排程'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('管理').at(2),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('管理').at(2));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-entry')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    expect(find.textContaining('每月'), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.textContaining('尚未建立排程'), findsNothing);
    expect(find.textContaining('下次'), findsWidgets);
    expect(await root.taskRepository.loadTasks(), isEmpty);
  });
}

Future<void> _selectMilestoneDate(WidgetTester tester) async {
  await tester.tap(find.text('尚未設定'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();
}

Future<void> _openManualWorkCaseForm(WidgetTester tester) async {
  final entry = find.text('突發事項／工程');
  await tester.scrollUntilVisible(
    entry,
    200,
    scrollable: find.byType(Scrollable).first,
  );
  await tester.tap(entry);
  await tester.pumpAndSettle();
}

Future<void> _tapManualWorkCaseSave(WidgetTester tester) async {
  final save = find.byKey(const ValueKey('manual-case-save'));
  final scrollable = find.byType(Scrollable).first;
  await tester.scrollUntilVisible(save, 200, scrollable: scrollable);
  await tester.drag(scrollable, const Offset(0, -80));
  await tester.pumpAndSettle();
  await tester.tap(save);
  await tester.pumpAndSettle();
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
