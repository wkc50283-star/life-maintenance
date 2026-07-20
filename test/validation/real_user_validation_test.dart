import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/screens/history_screen.dart';

void main() {
  test(
    'real lifecycle survives cold starts, multiple days, backup and restore',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-management-real-user-',
      );
      final databaseFile = File('${directory.path}/life.sqlite');
      final backupFile = File('${directory.path}/life.backup.sqlite');
      final restoredFile = File('${directory.path}/life.restored.sqlite');
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final dayOne = DateTime.utc(2026, 7, 1, 9);
      var root = _open(databaseFile);
      await _createItemPlanAndTask(root, dayOne);
      final taskBeforeCase = await root.driftRepositories.tasks.findById(
        'task-plan-1',
      );
      expect(taskBeforeCase?.sourceType, 'scheduledMaintenance');
      expect(taskBeforeCase?.maintenancePlanId, 'plan-1');

      final startedCase = await root.taskReminderRuntime.startWorkCase(
        taskId: 'task-plan-1',
        workCase: WorkCase(
          id: 'case-1',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.maintenanceTask,
          caseType: WorkCaseType.maintenance,
          title: '冷氣濾網清潔',
          description: '開始處理本次保養提醒',
          occurredAt: dayOne,
          startedAt: dayOne,
          status: WorkCaseStatus.inProgress,
          createdAt: dayOne,
          updatedAt: dayOne,
        ),
      );
      expect(startedCase.sourceId, 'task-plan-1');
      expect(await root.workCaseRuntime.findClosureForCase('case-1'), isNull);
      expect(
        await root.historyProjectionRepository.projectForItem('item-1'),
        isA<HistoryProjection>().having(
          (projection) => projection.entries,
          'entries before closure',
          isEmpty,
        ),
      );
      await root.database.close();

      // Day two starts from disk again, like a full process cold start.
      final dayTwo = dayOne.add(const Duration(days: 1));
      root = _open(databaseFile);
      expect((await root.initialize()).usesDriftWorkCases, isTrue);
      expect(
        (await root.workCaseRuntime.findCaseById('case-1'))?.isOpen,
        isTrue,
      );
      await root.workCaseRuntime.appendUpdate(
        WorkCaseUpdate(
          id: 'update-1',
          workCaseId: 'case-1',
          occurredAt: dayTwo,
          description: '已拆下濾網並完成清洗',
          contactOrVendor: '自行處理',
          result: '等待完全晾乾',
          cost: 0,
          waitingReason: '濾網仍有水氣',
          nextAction: '隔日裝回並測試',
          createdAt: dayTwo,
        ),
        status: WorkCaseStatus.waiting,
        statusUpdatedAt: dayTwo,
      );
      expect(
        (await root.workCaseRuntime.findCaseById('case-1'))?.status,
        WorkCaseStatus.waiting,
      );
      await root.database.close();

      // Day five resumes the same case and closes it through the one Closure.
      final dayFive = dayOne.add(const Duration(days: 4));
      root = _open(databaseFile);
      await root.workCaseRuntime.appendUpdate(
        WorkCaseUpdate(
          id: 'update-2',
          workCaseId: 'case-1',
          occurredAt: dayFive,
          description: '裝回濾網並完成運轉測試',
          result: '風量與運轉皆正常',
          partsOrItems: const ['冷氣濾網'],
          note: '清洗後無異味',
          createdAt: dayFive,
        ),
        status: WorkCaseStatus.inProgress,
        statusUpdatedAt: dayFive,
      );
      await root.workCaseRuntime.close(
        WorkCaseClosure(
          id: 'closure-1',
          workCaseId: 'case-1',
          completedAt: dayFive,
          finalResult: '清潔完成，運轉正常',
          completionSummary: '清洗、晾乾、裝回並測試完成',
          totalCost: 0,
          followUpNotes: '下次清潔時留意濾網卡榫',
          createdAt: dayFive,
        ),
      );

      final completedCase = await root.workCaseRuntime.findCaseById('case-1');
      expect(completedCase?.status, WorkCaseStatus.completed);
      expect(
        await root.workCaseRuntime.listUpdatesForCase('case-1'),
        hasLength(2),
      );
      expect(
        await root.driftRepositories.tasks.findById('task-plan-1'),
        taskBeforeCase,
        reason: 'Task remains the original reminder after case closure.',
      );
      final history = await root.historyProjectionRepository.projectForItem(
        'item-1',
      );
      final historyCase = history.entries
          .whereType<WorkCaseHistoryEntry>()
          .single;
      expect(historyCase.updates.map((update) => update.id), [
        'update-1',
        'update-2',
      ]);
      expect(historyCase.closure?.id, 'closure-1');
      expect(historyCase.relatedTasks.single.id, 'task-plan-1');
      expect(
        await root.database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      await root.database.close();

      // Backup and restore operate only on a closed, consistent database file.
      await databaseFile.copy(backupFile.path);
      await backupFile.copy(restoredFile.path);
      root = _open(restoredFile);
      expect((await root.initialize()).usesDriftHistoryAttachments, isTrue);
      expect(
        (await root.driftRepositories.items.findById('item-1'))?.name,
        '客廳冷氣',
      );
      expect(
        (await root.maintenancePlanRepository.findById('plan-1'))?.title,
        '清洗濾網',
      );
      expect(
        await root.workCaseRuntime.listUpdatesForCase('case-1'),
        hasLength(2),
      );
      expect(
        (await root.workCaseRuntime.findClosureForCase('case-1'))?.id,
        'closure-1',
      );
      expect(
        (await root.historyProjectionRepository.projectForItem(
          'item-1',
        )).entries.whereType<WorkCaseHistoryEntry>(),
        hasLength(1),
      );
      expect(
        await root.database
            .customSelect('PRAGMA integrity_check')
            .get()
            .then((rows) => rows.single.data.values.single),
        'ok',
      );
      await root.database.close();
    },
  );

  testWidgets('mobile History opens a closed case with its complete timeline', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final now = DateTime.now().subtract(const Duration(days: 2));
    await _createItemPlanAndTask(root, now);
    await root.taskReminderRuntime.startWorkCase(
      taskId: 'task-plan-1',
      workCase: WorkCase(
        id: 'case-mobile',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.maintenanceTask,
        caseType: WorkCaseType.maintenance,
        title: '冷氣濾網清潔',
        startedAt: now,
        status: WorkCaseStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await root.workCaseRuntime.appendUpdate(
      WorkCaseUpdate(
        id: 'update-mobile',
        workCaseId: 'case-mobile',
        occurredAt: now.add(const Duration(days: 1)),
        description: '完成濾網清洗與晾乾',
        result: '準備裝回測試',
        createdAt: now.add(const Duration(days: 1)),
      ),
    );
    await root.workCaseRuntime.close(
      WorkCaseClosure(
        id: 'closure-mobile',
        workCaseId: 'case-mobile',
        completedAt: now.add(const Duration(days: 2)),
        finalResult: '運轉正常',
        completionSummary: '濾網已清洗、裝回並測試',
        totalCost: 0,
        followUpNotes: '下個月再查看積塵情況',
        createdAt: now.add(const Duration(days: 2)),
      ),
    );

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('冷氣濾網清潔'), findsOneWidget);
    expect(find.text('案件史略'), findsOneWidget);
    expect(find.text('濾網已清洗、裝回並測試'), findsOneWidget);
    expect(find.text('處理進度：1 筆'), findsOneWidget);
    expect(find.text('運轉正常'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('冷氣濾網清潔'));
    await tester.pumpAndSettle();
    expect(find.text('案件詳情'), findsOneWidget);
    expect(find.text('完成濾網清洗與晾乾'), findsOneWidget);
    expect(find.text('濾網已清洗、裝回並測試'), findsOneWidget);
    expect(find.textContaining('case-mobile'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}

AppCompositionRoot _open(File file) =>
    AppCompositionRoot(database: AppDatabase(NativeDatabase(file)));

Future<void> _createItemPlanAndTask(
  AppCompositionRoot root,
  DateTime now,
) async {
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
  await root.maintenancePlanRepository.save(
    MaintenancePlan(
      id: 'plan-1',
      itemId: 'item-1',
      title: '清洗濾網',
      description: '維持風量與室內空氣品質',
      planType: MaintenancePlanType.cleaning,
      riskLevel: RiskLevel.low,
      createdAt: now,
      updatedAt: now,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-1',
      itemId: 'item-1',
      sourceType: 'maintenancePlan',
      maintenancePlanId: 'plan-1',
      cycleType: CycleType.monthly.name,
      interval: 1,
      startDate: now,
      nextDueDate: now,
      status: ScheduleStatus.active.name,
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: now,
      updatedAt: now,
    ),
  );
  final generated = root.maintenanceTaskService.generateDueTasks(
    schedules: await root.scheduleRepository.loadSchedules(),
    existingTasks: await root.taskRepository.loadTasks(),
    today: now,
  );
  expect(generated, hasLength(1));
  await root.taskRepository.saveGeneratedTasks([
    generated.single.copyWith(id: 'task-plan-1'),
  ]);
}
