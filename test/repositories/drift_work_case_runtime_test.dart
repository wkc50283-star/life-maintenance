import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_work_case_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftWorkCaseRuntime runtime;
  final now = DateTime.utc(2026, 7, 19, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    runtime = DriftWorkCaseRuntime(
      database: database,
      workCases: repositories.workCases,
      closures: repositories.workCaseClosures,
      tasks: repositories.tasks,
    );
    await repositories.itemCategories.save(
      ItemCategoryRow(
        id: 'category-1',
        systemCode: 'other',
        displayName: '其他',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final id in const ['item-1', 'item-2']) {
      await repositories.items.save(
        ItemRow(
          id: id,
          name: '生活項目 $id',
          categoryId: 'category-1',
          createdAt: now,
          updatedAt: now,
          status: 'active',
        ),
      );
    }
    await repositories.generalReminders.save(
      GeneralReminderRow(
        schemaVersion: 1,
        id: 'reminder-1',
        itemId: 'item-1',
        title: '租約續約',
        reminderType: 'expiry',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.schedules.save(
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
    await repositories.tasks.save(
      TaskRow(
        id: 'task-1',
        itemId: 'item-1',
        sourceType: 'scheduledReminder',
        scheduleId: 'schedule-1',
        generalReminderId: 'reminder-1',
        title: '租約續約',
        dueDate: now,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.maintenancePlans.save(
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
    await repositories.schedules.save(
      ScheduleRow(
        id: 'schedule-plan',
        itemId: 'item-1',
        sourceType: 'maintenancePlan',
        maintenancePlanId: 'plan-1',
        cycleType: 'monthly',
        interval: 1,
        startDate: now,
        nextDueDate: now,
        status: 'active',
        anchorPolicy: 'fixedCalendarPeriod',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.tasks.save(
      TaskRow(
        id: 'task-plan',
        itemId: 'item-1',
        sourceType: 'scheduledMaintenance',
        scheduleId: 'schedule-plan',
        maintenancePlanId: 'plan-1',
        title: '清洗濾網',
        dueDate: now,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.milestones.save(
      Milestone(
        id: 'milestone-1',
        itemId: 'item-1',
        title: '全面檢查',
        kind: MilestoneKind.deepInspection,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.schedules.save(
      ScheduleRow(
        id: 'schedule-milestone',
        itemId: 'item-1',
        sourceType: 'milestone',
        milestoneId: 'milestone-1',
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
    await repositories.tasks.save(
      TaskRow(
        id: 'task-milestone',
        itemId: 'item-1',
        sourceType: 'milestone',
        scheduleId: 'schedule-milestone',
        milestoneId: 'milestone-1',
        title: '全面檢查',
        dueDate: now,
        status: 'pending',
        createdAt: now,
        updatedAt: now,
      ),
    );
  });

  tearDown(() => database.close());

  WorkCase workCase({
    String id = 'case-1',
    String itemId = 'item-1',
    WorkCaseSourceType sourceType = WorkCaseSourceType.manual,
    String? sourceId,
  }) => WorkCase(
    id: id,
    itemId: itemId,
    sourceType: sourceType,
    sourceId: sourceId,
    caseType: WorkCaseType.administrative,
    title: '辦理租約續約',
    status: WorkCaseStatus.inProgress,
    createdAt: now,
    updatedAt: now,
  );

  WorkCaseUpdate update({
    String id = 'update-1',
    String workCaseId = 'case-1',
    int? cost,
  }) => WorkCaseUpdate(
    id: id,
    workCaseId: workCaseId,
    occurredAt: now.add(const Duration(hours: 1)),
    description: '已聯絡房東確認條件',
    cost: cost,
    createdAt: now.add(const Duration(hours: 1)),
  );

  WorkCaseClosure closure({
    String id = 'closure-1',
    WorkCaseFollowUpType followUpType = WorkCaseFollowUpType.none,
    String? nextScheduleId,
    String? nextReminderTaskId,
  }) => WorkCaseClosure(
    id: id,
    workCaseId: 'case-1',
    completedAt: now.add(const Duration(hours: 3)),
    finalResult: '完成續約',
    completionSummary: '雙方完成簽署並留存文件',
    totalCost: 1000,
    followUpType: followUpType,
    nextScheduleId: nextScheduleId,
    nextReminderTaskId: nextReminderTaskId,
    createdAt: now.add(const Duration(hours: 3)),
  );

  test('creates a formal WorkCase from a Task without changing Task', () async {
    final created = await runtime.createFromTask(
      taskId: 'task-1',
      workCase: workCase(),
      initialUpdate: update(),
    );

    expect(created.sourceType, WorkCaseSourceType.generalReminder);
    expect(created.sourceId, 'reminder-1');
    expect(await runtime.listUpdatesForCase(created.id), hasLength(1));
    expect((await repositories.tasks.findById('task-1'))?.status, 'pending');
  });

  test('maps every supported Task source to the formal case source', () async {
    final maintenance = await runtime.createFromTask(
      taskId: 'task-plan',
      workCase: workCase(id: 'case-plan'),
    );
    final milestone = await runtime.createFromTask(
      taskId: 'task-milestone',
      workCase: workCase(id: 'case-milestone'),
    );

    expect(maintenance.sourceType, WorkCaseSourceType.maintenanceTask);
    expect(maintenance.sourceId, 'task-plan');
    expect(milestone.sourceType, WorkCaseSourceType.milestone);
    expect(milestone.sourceId, 'milestone-1');
  });

  test('rejects a Task and WorkCase from different Items', () async {
    await expectLater(
      runtime.createFromTask(
        taskId: 'task-1',
        workCase: workCase(itemId: 'item-2'),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await runtime.findCaseById('case-1'), isNull);
  });

  test('creates a manual WorkCase with multiple immutable updates', () async {
    await runtime.createManual(workCase(), initialUpdate: update());
    await runtime.appendUpdate(
      update(id: 'update-2'),
      status: WorkCaseStatus.waiting,
      statusUpdatedAt: now.add(const Duration(hours: 2)),
    );

    expect(await runtime.listUpdatesForCase('case-1'), hasLength(2));
    expect(
      (await runtime.findCaseById('case-1'))?.status,
      WorkCaseStatus.waiting,
    );
  });

  test('update and status transaction rolls back together', () async {
    await runtime.createManual(workCase());

    await expectLater(
      runtime.appendUpdate(
        update(cost: -1),
        status: WorkCaseStatus.waiting,
        statusUpdatedAt: now.add(const Duration(hours: 2)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await runtime.listUpdatesForCase('case-1'), isEmpty);
    expect(
      (await runtime.findCaseById('case-1'))?.status,
      WorkCaseStatus.inProgress,
    );
  });

  test('closure and terminal status are atomic and unique', () async {
    await runtime.createManual(workCase());
    await runtime.close(closure());

    final closed = await runtime.findCaseById('case-1');
    expect(closed?.status, WorkCaseStatus.completed);
    expect((await runtime.findClosureForCase('case-1'))?.id, 'closure-1');
    await expectLater(
      runtime.close(closure(id: 'closure-2')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(
      await database.select(database.workCaseClosures).get(),
      hasLength(1),
    );
  });

  test(
    'closure, existing Schedule and new reminder commit atomically',
    () async {
      await runtime.createManual(workCase());
      final value = closure(
        followUpType: WorkCaseFollowUpType.scheduleAndReminder,
        nextScheduleId: 'schedule-1',
        nextReminderTaskId: 'task-follow-up',
      );

      await runtime.closeWithFollowUp(
        value,
        nextReminderDueDate: now.add(const Duration(days: 30)),
      );

      expect(
        (await runtime.findCaseById('case-1'))?.status,
        WorkCaseStatus.completed,
      );
      expect(
        (await runtime.findClosureForCase('case-1'))?.nextScheduleId,
        'schedule-1',
      );
      final reminder = await repositories.tasks.findById('task-follow-up');
      expect(reminder?.itemId, 'item-1');
      expect(reminder?.sourceType, 'manual');
      expect(reminder?.status, 'pending');
    },
  );

  test('follow-up failure rolls reminder, Closure and status back', () async {
    await runtime.createManual(workCase());
    final value = closure(
      followUpType: WorkCaseFollowUpType.scheduleAndReminder,
      nextScheduleId: 'missing-schedule',
      nextReminderTaskId: 'task-rolled-back',
    );

    await expectLater(
      runtime.closeWithFollowUp(
        value,
        nextReminderDueDate: now.add(const Duration(days: 30)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await repositories.tasks.findById('task-rolled-back'), isNull);
    expect(await runtime.findClosureForCase('case-1'), isNull);
    expect(
      (await runtime.findCaseById('case-1'))?.status,
      WorkCaseStatus.inProgress,
    );
  });

  test(
    'terminated WorkCase rejects edits, updates, and status changes',
    () async {
      await runtime.createManual(workCase());
      await runtime.close(closure());

      await expectLater(
        runtime.saveOpenCase(
          workCase().copyWith(
            description: '不得修改',
            updatedAt: now.add(const Duration(hours: 4)),
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      await expectLater(
        runtime.appendUpdate(update()),
        throwsA(isA<RepositoryConstraintException>()),
      );
      await expectLater(
        runtime.updateStatus(
          'case-1',
          WorkCaseStatus.inProgress,
          now.add(const Duration(hours: 4)),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
    },
  );

  test('open WorkCase cannot move to another Item or source', () async {
    await runtime.createManual(workCase());

    await expectLater(
      runtime.saveOpenCase(
        workCase(
          itemId: 'item-2',
        ).copyWith(updatedAt: now.add(const Duration(hours: 1))),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect((await runtime.findCaseById('case-1'))?.itemId, 'item-1');
  });
}
