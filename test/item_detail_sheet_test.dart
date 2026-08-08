import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/item_custom_management_period.dart';
import 'package:life_maintenance/models/item_management_period.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/screens/item_detail_screen.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:life_maintenance/screens/formal_planning_screens.dart';
import 'package:life_maintenance/screens/task_reminder_screens.dart';
import 'package:life_maintenance/screens/work_case_screens.dart';
import 'package:life_maintenance/repositories/item_creation_runtime.dart';

void main() {
  testWidgets('items screen shows calm empty state from empty Drift', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();

    expect(find.text('目前還沒有生活項目。'), findsOneWidget);
    expect(find.text('客廳冷氣'), findsNothing);
  });

  testWidgets('full item page projects every formal Drift section read-only', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final now = DateTime.utc(2026, 7, 19, 8);
    await _seedFormalItemDetail(root, now);

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客廳冷氣'));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(find.byType(BottomSheet), findsNothing);
    expect(find.text('生活項目詳情'), findsOneWidget);
    expect(find.text('主資訊'), findsOneWidget);
    expect(find.text('客廳'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('清洗濾網').first,
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('清洗濾網'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-detail-jump-一般提醒')));
    await tester.pumpAndSettle();
    expect(find.text('保固到期提醒'), findsWidgets);

    await tester.drag(find.byType(ListView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-detail-jump-提醒與排程')));
    await tester.pumpAndSettle();
    expect(find.text('清洗濾網'), findsOneWidget);
    expect(find.text('保固到期提醒'), findsWidgets);
    expect(find.text('每月'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('第六年大修'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('第六年大修'), findsOneWidget);
    expect(find.text('條件 6 年'), findsOneWidget);
    expect(find.text('條件未到'), findsOneWidget);
    expect(find.text('尚未達標'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('冷氣異音檢查'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('冷氣異音檢查'), findsOneWidget);
    expect(find.text('下一步：等待到府檢查'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-detail-jump-履歷')));
    await tester.pumpAndSettle();
    expect(find.text('完成冷氣濾網清潔'), findsOneWidget);

    await tester.drag(find.byType(ListView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-detail-jump-附件')));
    await tester.pumpAndSettle();
    expect(find.text('冷氣保固書.pdf'), findsOneWidget);
    expect(find.text('application/pdf · 2.0 KB'), findsOneWidget);
    expect(find.textContaining('managed-item-document'), findsNothing);

    await tester.drag(find.byType(ListView), const Offset(0, 10000));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-detail-jump-基本資料')));
    await tester.pumpAndSettle();
    expect(find.text('夏季使用頻繁'), findsOneWidget);

    expect(
      await root.driftRepositories.maintenancePlans.listForItem('item-1'),
      hasLength(1),
    );
    expect(
      await root.driftRepositories.generalReminders.listForItem('item-1'),
      hasLength(1),
    );
    expect(
      await root.driftRepositories.schedules.listForItem('item-1'),
      hasLength(2),
    );
    expect(await root.workCaseRuntime.listCasesForItem('item-1'), hasLength(1));
    expect(
      await root.maintenanceRecordRepository.listForItem('item-1'),
      hasLength(1),
    );
    expect(
      await root.attachmentRuntime.listForOwner(
        AttachmentOwnerType.item,
        'item-1',
      ),
      hasLength(1),
    );
  });

  testWidgets('item detail projects attention and reloads changed task data', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1200);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final now = DateTime.now();
    await _seedFormalItemDetail(root, now, includeAttention: true);

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('客廳冷氣'));
    await tester.pumpAndSettle();

    expect(find.text('需要注意'), findsWidgets);
    expect(
      find.byKey(const ValueKey('attention-task-task-overdue')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attention-task-task-due')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attention-milestone-milestone-reached')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attention-work-case-case-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('attention-work-case-case-in-progress')),
      findsOneWidget,
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('attention-task-task-overdue')))
          .dy,
      lessThan(
        tester
            .getTopLeft(find.byKey(const ValueKey('attention-task-task-due')))
            .dy,
      ),
    );
    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('attention-task-task-due')))
          .dy,
      lessThan(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey('attention-milestone-milestone-reached'),
              ),
            )
            .dy,
      ),
    );
    expect(
      find.byKey(const ValueKey('attention-task-task-completed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-task-task-canceled')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-task-task-future')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-task-task-postponed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-milestone-milestone-completed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-milestone-milestone-canceled')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-work-case-case-completed')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('attention-work-case-case-canceled')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('attention-milestone-milestone-reached')),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MilestoneFormScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final workCaseAttention = find.byKey(
      const ValueKey('attention-work-case-case-1'),
    );
    await tester.ensureVisible(workCaseAttention);
    await tester.pumpAndSettle();
    await tester.tap(workCaseAttention);
    await tester.pumpAndSettle();
    expect(find.byType(WorkCaseDetailScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    final overdueAttention = find.byKey(
      const ValueKey('attention-task-task-overdue'),
    );
    await tester.ensureVisible(overdueAttention);
    await tester.pumpAndSettle();
    await tester.tap(overdueAttention);
    await tester.pumpAndSettle();
    expect(find.byType(TaskReminderDetailScreen), findsOneWidget);
    await tester.tap(find.text('完成'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('確認完成'));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();
    expect(find.byType(ItemDetailScreen), findsOneWidget);
    expect(
      find.byKey(const ValueKey('attention-task-task-overdue')),
      findsNothing,
    );
  });

  testWidgets('item detail shows the approved empty attention state', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final now = DateTime.now();
    await _seedItem(root, now, id: 'item-empty', name: '書房桌燈');

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('書房桌燈'));
    await tester.pumpAndSettle();

    expect(find.text('需要注意'), findsWidgets);
    final emptyAttention = find.text('目前沒有需要注意的事項');
    await tester.scrollUntilVisible(emptyAttention, 200);
    expect(emptyAttention, findsOneWidget);
  });

  testWidgets(
    'item detail edits fixed and custom periods and preserves created history',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 1200);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);
      addTearDown(database.close);
      final createdAt = DateTime.utc(2026, 8, 8, 8);
      await root.itemCreationRuntime.create(
        ItemCreationRequest(
          itemId: 'item-period-edit',
          name: '客廳冷氣',
          createdAt: createdAt,
          managementPeriods: const {ItemManagementPeriod.month},
          customManagementPeriods: [
            ItemCustomManagementPeriod(
              intervalValue: 2,
              intervalUnit: ItemManagementIntervalUnit.week,
            ),
          ],
        ),
      );
      final item = Item(
        id: 'item-period-edit',
        name: '客廳冷氣',
        category: ItemCategory.other,
        createdAt: createdAt,
      );

      await tester.pumpWidget(_itemDetailApp(root, item));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(find.text('月、每 2 週'), 200);
      expect(find.text('月、每 2 週'), findsOneWidget);

      await _openManagementPeriodForm(tester);
      expect(find.byType(ItemManagementPeriodFormScreen), findsOneWidget);
      expect(
        tester
            .widget<FilterChip>(find.byKey(const ValueKey('item-period-month')))
            .selected,
        isTrue,
      );
      expect(find.text('每 2 週'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('item-period-month')));
      await tester.tap(find.byKey(const ValueKey('item-period-day')));
      await tester.tap(find.byKey(const ValueKey('remove-custom-period-0')));
      await _addCustomPeriod(
        tester,
        value: '3',
        unit: ItemManagementIntervalUnit.quarter,
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      expect(find.byType(ItemDetailScreen), findsOneWidget);
      await tester.scrollUntilVisible(find.text('日、每 3 季'), 200);
      expect(find.text('日、每 3 季'), findsOneWidget);
      final current = await root.itemManagementPeriodRuntime.readCurrent(
        item.id,
      );
      expect(current.fixed, {ItemManagementPeriod.day});
      expect(current.custom, {
        ItemCustomManagementPeriod(
          intervalValue: 3,
          intervalUnit: ItemManagementIntervalUnit.quarter,
        ),
      });
      var projection = await root.historyProjectionRepository.projectForItem(
        item.id,
      );
      expect(projection.itemManagementPeriodChangeEntries, hasLength(1));
      expect(projection.itemCreatedEntries.single.event.managementPeriods, {
        ItemManagementPeriod.month,
      });
      expect(
        projection.itemCreatedEntries.single.event.customManagementPeriods,
        {
          ItemCustomManagementPeriod(
            intervalValue: 2,
            intervalUnit: ItemManagementIntervalUnit.week,
          ),
        },
      );

      await _openManagementPeriodForm(tester);
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();
      projection = await root.historyProjectionRepository.projectForItem(
        item.id,
      );
      expect(projection.itemManagementPeriodChangeEntries, hasLength(1));

      await _openManagementPeriodForm(tester);
      await tester.tap(find.byKey(const ValueKey('item-period-day')));
      await tester.tap(find.byKey(const ValueKey('remove-custom-period-0')));
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();
      expect(find.text('尚未設定'), findsWidgets);
      expect(
        (await root.itemManagementPeriodRuntime.readCurrent(item.id)).fixed,
        isEmpty,
      );
      expect(
        (await root.itemManagementPeriodRuntime.readCurrent(item.id)).custom,
        isEmpty,
      );
      expect(
        (await root.historyProjectionRepository.projectForItem(
          item.id,
        )).itemManagementPeriodChangeEntries,
        hasLength(2),
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.schedules).get(), isEmpty);
      expect(await database.select(database.generalReminders).get(), isEmpty);
    },
  );

  testWidgets('item management periods keep the approved equivalence error', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final createdAt = DateTime.utc(2026, 8, 8, 8);
    await root.itemCreationRuntime.create(
      ItemCreationRequest(
        itemId: 'item-period-equivalence',
        name: '週期測試',
        createdAt: createdAt,
        managementPeriods: const {},
      ),
    );
    final item = Item(
      id: 'item-period-equivalence',
      name: '週期測試',
      category: ItemCategory.other,
      createdAt: createdAt,
    );
    await tester.pumpWidget(_itemDetailApp(root, item));
    await tester.pumpAndSettle();
    await _openManagementPeriodForm(tester);

    await tester.tap(find.byKey(const ValueKey('item-period-week')));
    await _addCustomPeriod(
      tester,
      value: '7',
      unit: ItemManagementIntervalUnit.day,
    );
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pump();

    expect(find.text('管理週期「每 7 天」與「週」等價，請保留其中一筆。'), findsOneWidget);
    expect(
      await root.itemManagementPeriodRuntime.listChanges(item.id),
      isEmpty,
    );
  });

  testWidgets('archived item does not expose management period editing', (
    tester,
  ) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final item = Item(
      id: 'archived-period-item',
      name: '已封存項目',
      category: ItemCategory.other,
      createdAt: DateTime.utc(2026, 8, 8, 8),
      status: ItemStatus.archived,
    );
    await tester.pumpWidget(_itemDetailApp(root, item));
    await tester.pumpAndSettle();

    final section = find.byKey(const ValueKey('item-management-periods'));
    expect(
      find.descendant(of: section, matching: find.text('管理')),
      findsNothing,
    );
  });

  testWidgets('item detail separates information and preserves section order', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 3000);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final now = DateTime.utc(2026, 7, 29, 8);
    await _seedItem(root, now, id: 'item-sections', name: '測試桌燈');

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('測試桌燈'));
    await tester.pumpAndSettle();

    const sectionTitles = [
      '主資訊',
      '需要注意',
      '保養項目',
      '一般提醒',
      '提醒與排程',
      '階段性重點／大修',
      '進行中案件',
      '已結案件',
      '履歷',
      '附件',
      '基本資料',
    ];
    expect(find.text('主資訊'), findsOneWidget);
    for (final title in sectionTitles.skip(1)) {
      expect(find.text(title), findsNWidgets(2));
    }
    for (var index = 0; index < sectionTitles.length - 1; index += 1) {
      expect(
        tester.getTopLeft(find.text(sectionTitles[index]).last).dy,
        lessThan(
          tester.getTopLeft(find.text(sectionTitles[index + 1]).last).dy,
        ),
      );
    }
    expect(
      tester.getTopLeft(find.text('測試桌燈').last).dy,
      lessThan(tester.getTopLeft(find.text('主資訊')).dy),
    );

    for (final label in const ['分類', '狀態', '位置']) {
      expect(find.text(label), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(label)).dy,
        greaterThan(tester.getTopLeft(find.text('主資訊')).dy),
      );
      expect(
        tester.getTopLeft(find.text(label)).dy,
        lessThan(tester.getTopLeft(find.text('需要注意').last).dy),
      );
    }
    for (final label in const ['建立日期', '購買日期', '保固到期', '管理年限', '備註']) {
      expect(find.text(label), findsOneWidget);
      expect(
        tester.getTopLeft(find.text(label)).dy,
        greaterThan(tester.getTopLeft(find.text('基本資料').last).dy),
      );
    }
    expect(find.text('未設定'), findsNWidgets(5));
    expect(find.text('目前沒有需要注意的事項'), findsOneWidget);
  });

  testWidgets('item detail jump navigation reaches every formal section', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    final now = DateTime.utc(2026, 7, 29, 8);
    await _seedItem(root, now, id: 'item-jump', name: '導覽測試桌燈');

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('導覽測試桌燈'));
    await tester.pumpAndSettle();

    const jumpTitles = [
      '需要注意',
      '保養項目',
      '一般提醒',
      '提醒與排程',
      '階段性重點／大修',
      '進行中案件',
      '已結案件',
      '履歷',
      '附件',
      '基本資料',
    ];
    expect(find.text('快速前往'), findsOneWidget);
    for (final title in jumpTitles) {
      await tester.drag(find.byType(ListView), const Offset(0, 10000));
      await tester.pumpAndSettle();
      final jump = find.byKey(ValueKey('item-detail-jump-$title'));
      expect(jump, findsOneWidget);
      await tester.tap(jump);
      await tester.pumpAndSettle();

      final sectionTitle = find.text(title).last;
      expect(sectionTitle, findsOneWidget);
      final sectionTop = tester.getTopLeft(sectionTitle).dy;
      expect(sectionTop, greaterThanOrEqualTo(0));
      expect(sectionTop, lessThan(800));
    }

    expect(await root.itemReadRepository.loadItems(), hasLength(1));
    expect(await root.taskRepository.loadTasks(), isEmpty);
  });
}

Widget _itemDetailApp(AppCompositionRoot root, Item item) {
  return AppCompositionScope(
    root: root,
    child: MaterialApp(home: ItemDetailScreen(item: item)),
  );
}

Future<void> _openManagementPeriodForm(WidgetTester tester) async {
  final section = find.byKey(const ValueKey('item-management-periods'));
  await tester.scrollUntilVisible(section, 200);
  await tester.pumpAndSettle();
  await tester.tap(find.descendant(of: section, matching: find.text('管理')));
  await tester.pumpAndSettle();
}

Future<void> _addCustomPeriod(
  WidgetTester tester, {
  required String value,
  required ItemManagementIntervalUnit unit,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('custom-period-value')),
    value,
  );
  await tester.tap(find.byKey(const ValueKey('custom-period-unit')));
  await tester.pumpAndSettle();
  await tester.tap(find.text(_intervalUnitLabel(unit)).last);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-custom-period')));
  await tester.pump();
}

String _intervalUnitLabel(ItemManagementIntervalUnit unit) => switch (unit) {
  ItemManagementIntervalUnit.day => '天',
  ItemManagementIntervalUnit.week => '週',
  ItemManagementIntervalUnit.month => '月',
  ItemManagementIntervalUnit.quarter => '季',
  ItemManagementIntervalUnit.halfYear => '半年',
  ItemManagementIntervalUnit.year => '年',
};

Widget _app(AppCompositionRoot root) {
  return AppCompositionScope(
    root: root,
    child: const MaterialApp(home: Scaffold(body: ItemsScreen())),
  );
}

Future<void> _seedFormalItemDetail(
  AppCompositionRoot root,
  DateTime now, {
  bool includeAttention = false,
}) async {
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'homeAndAppliance',
      displayName: '家電與居家設備',
      sortOrder: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: 'item-1',
      name: '客廳冷氣',
      categoryId: 'category-1',
      createdAt: now,
      updatedAt: now,
      purchaseDate: now.subtract(const Duration(days: 500)),
      warrantyEndDate: now.add(const Duration(days: 200)),
      expectedLifeYears: 10,
      location: '客廳',
      note: '夏季使用頻繁',
      status: 'active',
    ),
  );
  await root.maintenancePlanRepository.save(
    MaintenancePlan(
      id: 'plan-1',
      itemId: 'item-1',
      title: '清洗濾網',
      planType: MaintenancePlanType.cleaning,
      riskLevel: RiskLevel.low,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.generalReminderRepository.save(
    GeneralReminderRow(
      schemaVersion: 1,
      id: 'reminder-1',
      itemId: 'item-1',
      title: '保固到期提醒',
      description: '到期前確認延長保固方案',
      reminderType: 'expiry',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-plan',
      itemId: 'item-1',
      sourceType: 'maintenancePlan',
      maintenancePlanId: 'plan-1',
      cycleType: 'monthly',
      interval: 1,
      startDate: now,
      nextDueDate: now.add(const Duration(days: 20)),
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-reminder',
      itemId: 'item-1',
      sourceType: 'generalReminder',
      generalReminderId: 'reminder-1',
      cycleType: 'yearly',
      interval: 1,
      startDate: now,
      nextDueDate: now.add(const Duration(days: 200)),
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.milestoneRepository.save(
    Milestone(
      id: 'milestone-1',
      itemId: 'item-1',
      title: '第六年大修',
      kind: MilestoneKind.majorService,
      triggerType: MilestoneTriggerType.usageYears,
      thresholdValue: 6,
      thresholdUnit: '年',
      status: MilestoneStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
  );
  if (includeAttention) {
    for (final milestone in [
      Milestone(
        id: 'milestone-reached',
        itemId: 'item-1',
        title: '已達汰換評估條件',
        kind: MilestoneKind.replacementEvaluation,
        triggerType: MilestoneTriggerType.specificDate,
        triggerDate: now.subtract(const Duration(days: 1)),
        status: MilestoneStatus.reached,
        reachedAt: now.subtract(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now,
      ),
      Milestone(
        id: 'milestone-completed',
        itemId: 'item-1',
        title: '已完成重點',
        kind: MilestoneKind.custom,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.completed,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      Milestone(
        id: 'milestone-canceled',
        itemId: 'item-1',
        title: '已取消重點',
        kind: MilestoneKind.custom,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.canceled,
        canceledAt: now,
        cancellationReason: '不再需要',
        createdAt: now,
        updatedAt: now,
      ),
    ]) {
      await root.milestoneRepository.save(milestone);
    }
    for (final task in [
      TaskRow(
        id: 'task-overdue',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '已到期檢查',
        dueDate: now.subtract(const Duration(days: 1)),
        status: TaskStatus.overdue.name,
        createdAt: now,
        updatedAt: now,
      ),
      TaskRow(
        id: 'task-due',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '今天檢查',
        dueDate: now,
        status: TaskStatus.pending.name,
        createdAt: now,
        updatedAt: now,
      ),
      TaskRow(
        id: 'task-completed',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '已完成提醒',
        dueDate: now,
        status: TaskStatus.completed.name,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      TaskRow(
        id: 'task-canceled',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '已取消提醒',
        dueDate: now,
        status: TaskStatus.canceled.name,
        createdAt: now,
        updatedAt: now,
      ),
      TaskRow(
        id: 'task-future',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '未來提醒',
        dueDate: now.add(const Duration(days: 1)),
        status: TaskStatus.pending.name,
        createdAt: now,
        updatedAt: now,
      ),
      TaskRow(
        id: 'task-postponed',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '稍後提醒',
        dueDate: now,
        status: TaskStatus.postponed.name,
        postponedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    ]) {
      await root.driftRepositories.tasks.save(task);
    }
  }
  await root.workCaseRuntime.createManual(
    WorkCase(
      id: 'case-1',
      itemId: 'item-1',
      sourceType: WorkCaseSourceType.manual,
      caseType: WorkCaseType.repair,
      title: '冷氣異音檢查',
      status: WorkCaseStatus.waiting,
      createdAt: now,
      updatedAt: now,
    ),
    initialUpdate: WorkCaseUpdate(
      id: 'update-1',
      workCaseId: 'case-1',
      occurredAt: now,
      description: '已聯絡維修人員',
      nextAction: '等待到府檢查',
      createdAt: now,
    ),
  );
  if (includeAttention) {
    await root.workCaseRuntime.createManual(
      WorkCase(
        id: 'case-in-progress',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.repair,
        title: '冷氣運轉檢查',
        status: WorkCaseStatus.inProgress,
        createdAt: now,
        updatedAt: now.add(const Duration(minutes: 1)),
      ),
    );
    for (final entry in [
      WorkCaseRow(
        schemaVersion: 1,
        id: 'case-completed',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.other,
        title: '已完成案件',
        status: WorkCaseStatus.completed,
        createdAt: now,
        updatedAt: now,
        closedAt: now,
      ),
      WorkCaseRow(
        schemaVersion: 1,
        id: 'case-canceled',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.other,
        title: '已取消案件',
        status: WorkCaseStatus.canceled,
        createdAt: now,
        updatedAt: now,
        closedAt: now,
      ),
    ]) {
      await root.database.into(root.database.workCases).insert(entry);
    }
  }
  await root.maintenanceRecordRepository.createSimpleRecord(
    MaintenanceRecord(
      id: 'record-1',
      itemId: 'item-1',
      recordType: RecordType.regularMaintenance,
      date: now.subtract(const Duration(days: 10)),
      title: '完成冷氣濾網清潔',
      result: '運轉正常',
      createdAt: now.subtract(const Duration(days: 10)),
    ),
  );
  await root.attachmentRuntime.registerManaged(
    Attachment(
      id: 'attachment-1',
      ownerType: AttachmentOwnerType.item,
      ownerId: 'item-1',
      kind: AttachmentKind.document,
      storageIdentifier: 'managed-item-document-1',
      originalFileName: '冷氣保固書.pdf',
      mimeType: 'application/pdf',
      byteSize: 2048,
      contentHash: 'sha256:item-document',
      createdAt: now,
    ),
  );
}

Future<void> _seedItem(
  AppCompositionRoot root,
  DateTime now, {
  required String id,
  required String name,
}) async {
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-$id',
      systemCode: 'other',
      displayName: '其他',
      sortOrder: 0,
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: id,
      name: name,
      categoryId: 'category-$id',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    ),
  );
}
