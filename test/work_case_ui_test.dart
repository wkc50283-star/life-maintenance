import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/screens/work_case_screens.dart';

void main() {
  testWidgets('case UI appends rich progress and closes through one Closure', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final root = AppCompositionRoot(database: database);
    await _seed(root);
    await root.attachmentRuntime.registerManaged(
      Attachment(
        id: 'attachment-1',
        ownerType: AttachmentOwnerType.workCaseUpdate,
        ownerId: 'update-1',
        kind: AttachmentKind.receipt,
        storageIdentifier: 'managed-case-receipt',
        originalFileName: '檢查收據.pdf',
        mimeType: 'application/pdf',
        contentHash: 'sha256:case-receipt',
        createdAt: DateTime.now(),
      ),
    );

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    expect(find.text('冷氣異音處理'), findsOneWidget);
    expect(find.text('等待中'), findsOneWidget);
    expect(find.text('檢查收據.pdf'), findsOneWidget);
    expect(find.textContaining('managed-case-receipt'), findsNothing);

    await tester.tap(find.widgetWithText(FilledButton, '新增案件進度'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '這次做了什麼'),
      '完成現場檢查',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '聯絡人或廠商'),
      '安心冷氣行',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '這次處理結果'),
      '確認風扇老化',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '這次費用'), '800');
    await tester.enterText(
      find.widgetWithText(TextFormField, '零件或品項（可用逗號分開）'),
      '風扇,固定螺絲',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '等待原因'),
      '等待零件到貨',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '下一步'), '安排更換時間');
    await tester.tap(find.widgetWithText(FilledButton, '保存這筆進度'));
    await tester.pumpAndSettle();

    final updates = await root.workCaseRuntime.listUpdatesForCase('case-1');
    expect(updates, hasLength(2));
    final added = updates.last;
    expect(added.contactOrVendor, '安心冷氣行');
    expect(added.cost, 800);
    expect(added.partsOrItems, ['風扇', '固定螺絲']);
    expect(added.waitingReason, '等待零件到貨');
    expect(added.nextAction, '安排更換時間');
    expect(
      (await root.workCaseRuntime.findCaseById('case-1'))?.status,
      WorkCaseStatus.waiting,
    );

    await tester.tap(find.widgetWithText(OutlinedButton, '進入正式結案'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '完成結果'),
      '運轉恢復正常',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '完修或結案摘要'),
      '更換風扇並完成測試',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '後續注意事項（選填）'),
      '下次保養留意異音',
    );
    await tester.tap(find.byType(DropdownButtonFormField<String?>));
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('冷氣年度檢查').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('建立下一次提醒'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '確認正式結案'));
    await tester.pumpAndSettle();

    expect(find.text('運轉恢復正常'), findsOneWidget);
    expect(find.textContaining('案件已終止'), findsOneWidget);
    expect(find.text('新增案件進度'), findsNothing);
    expect(find.text('取消案件'), findsNothing);
    final closure = await root.workCaseRuntime.findClosureForCase('case-1');
    expect(closure?.followUpType, WorkCaseFollowUpType.scheduleAndReminder);
    expect(closure?.nextScheduleId, 'schedule-1');
    expect(closure?.nextReminderTaskId, isNotNull);
    final reminder = await root.driftRepositories.tasks.findById(
      closure!.nextReminderTaskId!,
    );
    expect(reminder?.sourceType, 'manual');
    expect(reminder?.status, 'pending');
    expect(
      (await root.workCaseRuntime.findCaseById('case-1'))?.status,
      WorkCaseStatus.completed,
    );
    final history = await root.historyProjectionRepository.projectForItem(
      'item-1',
    );
    final historyCase = history.entries
        .whereType<WorkCaseHistoryEntry>()
        .single;
    expect(historyCase.closure?.id, closure.id);
    expect(history.entries.whereType<WorkCaseHistoryEntry>(), hasLength(1));
  });

  testWidgets('cancel entry creates the unique terminal Closure', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 1600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final root = AppCompositionRoot(database: database);
    await _seed(root);

    await tester.pumpWidget(_app(root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('取消案件'));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.widgetWithText(TextFormField, '取消原因'),
      '設備已由原廠直接換新',
    );
    await tester.tap(find.widgetWithText(FilledButton, '確認取消案件'));
    await tester.pumpAndSettle();

    expect(
      (await root.workCaseRuntime.findCaseById('case-1'))?.status,
      WorkCaseStatus.canceled,
    );
    final closure = await root.workCaseRuntime.findClosureForCase('case-1');
    expect(closure?.finalResult, '案件已取消');
    expect(find.text('設備已由原廠直接換新'), findsWidgets);
    expect(find.text('新增案件進度'), findsNothing);
  });
}

Widget _app(AppCompositionRoot root) => AppCompositionScope(
  root: root,
  child: const MaterialApp(
    home: WorkCaseDetailScreen(workCaseId: 'case-1', itemName: '客廳冷氣'),
  ),
);

Future<void> _seed(AppCompositionRoot root) async {
  final now = DateTime.now().subtract(const Duration(hours: 2));
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'appliance',
      displayName: '家電',
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
      title: '冷氣年度檢查',
      reminderType: 'inspection',
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
      nextDueDate: now.add(const Duration(days: 365)),
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
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
      title: '冷氣異音處理',
      description: '運轉時有明顯異音',
      status: WorkCaseStatus.waiting,
      createdAt: now,
      updatedAt: now,
    ),
    initialUpdate: WorkCaseUpdate(
      id: 'update-1',
      workCaseId: 'case-1',
      occurredAt: now,
      description: '已聯絡維修廠商',
      contactOrVendor: '安心冷氣行',
      cost: 200,
      nextAction: '等待到府檢查',
      createdAt: now,
    ),
  );
}
