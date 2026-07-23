import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/enums.dart';
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
    expect(find.text('清洗濾網'), findsNWidgets(2));
    expect(find.text('保固到期提醒'), findsNWidgets(2));

    await tester.scrollUntilVisible(
      find.text('提醒與排程'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('清洗濾網'), findsNWidgets(2));
    expect(find.text('保固到期提醒'), findsNWidgets(2));
    expect(find.text('每月'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('第六年大修'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('第六年大修'), findsOneWidget);
    expect(find.text('條件 6 年'), findsOneWidget);
    expect(find.text('條件未到'), findsOneWidget);
    expect(find.text('尚未達標'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('冷氣異音檢查'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('冷氣異音檢查'), findsOneWidget);
    expect(find.text('下一步：等待到府檢查'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('史略'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('完成冷氣濾網清潔'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('附件'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('冷氣保固書.pdf'), findsOneWidget);
    expect(find.text('application/pdf · 2.0 KB'), findsOneWidget);
    expect(find.textContaining('managed-item-document'), findsNothing);

    await tester.scrollUntilVisible(
      find.text('主資訊'),
      300,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('客廳'), findsOneWidget);
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
}

Widget _app(AppCompositionRoot root) {
  return AppCompositionScope(
    root: root,
    child: const MaterialApp(home: Scaffold(body: ItemsScreen())),
  );
}

Future<void> _seedFormalItemDetail(
  AppCompositionRoot root,
  DateTime now,
) async {
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
