import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
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
    await repositories.tasks.save(
      TaskRow(
        id: 'task-2',
        itemId: 'item-1',
        sourceType: 'scheduledReminder',
        scheduleId: 'schedule-1',
        generalReminderId: 'reminder-1',
        title: '租約續約',
        dueDate: now.add(const Duration(days: 30)),
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
    expect(created.sourceTaskId, 'task-1');
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
    expect(maintenance.sourceTaskId, 'task-plan');
    expect(milestone.sourceType, WorkCaseSourceType.milestone);
    expect(milestone.sourceId, 'milestone-1');
    expect(milestone.sourceTaskId, 'task-milestone');
  });

  test(
    'keeps same Reminder cases linked to their exact source Tasks',
    () async {
      final first = await runtime.createFromTask(
        taskId: 'task-1',
        workCase: workCase(id: 'case-1'),
      );
      final second = await runtime.createFromTask(
        taskId: 'task-2',
        workCase: workCase(id: 'case-2'),
      );

      expect(first.sourceId, second.sourceId);
      expect(first.sourceTaskId, 'task-1');
      expect(second.sourceTaskId, 'task-2');
      expect(
        (await runtime.listBySourceTaskId('task-1')).map((value) => value.id),
        ['case-1'],
      );
      expect(
        (await runtime.listBySourceTaskId('task-2')).map((value) => value.id),
        ['case-2'],
      );
    },
  );

  test(
    'manual cases keep no source Task and model JSON stays compatible',
    () async {
      final linked = workCase(sourceId: 'reminder-1').copyWith(
        sourceType: WorkCaseSourceType.generalReminder,
        sourceTaskId: 'task-1',
      );
      final decoded = WorkCase.fromJson(linked.toJson());
      final legacy = Map<String, dynamic>.from(linked.toJson())
        ..remove('sourceTaskId');

      expect(decoded.sourceTaskId, 'task-1');
      expect(decoded.copyWith().sourceTaskId, 'task-1');
      expect(decoded.copyWith(sourceTaskId: null).sourceTaskId, isNull);
      expect(WorkCase.fromJson(legacy).sourceTaskId, isNull);

      await runtime.createManual(workCase());
      expect((await runtime.findCaseById('case-1'))?.sourceTaskId, isNull);
      expect(await runtime.listBySourceTaskId('task-1'), isEmpty);
    },
  );

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
    'closing a Reminder case atomically completes its exact Task and Schedule',
    () async {
      await runtime.createFromTask(taskId: 'task-1', workCase: workCase());
      await runtime.appendUpdate(update());
      await runtime.appendUpdate(update(id: 'update-2'));
      final value = closure();

      await runtime.close(value);

      final closed = await runtime.findCaseById('case-1');
      final sourceTask = await repositories.tasks.findById('task-1');
      final schedule = await repositories.schedules.findById('schedule-1');
      expect(closed?.status, WorkCaseStatus.completed);
      expect(closed?.closedAt, value.completedAt);
      expect((await runtime.findClosureForCase('case-1'))?.id, value.id);
      expect(sourceTask?.status, TaskStatus.completed.name);
      expect(sourceTask?.completedAt, value.completedAt);
      expect(sourceTask?.postponedAt, isNull);
      expect(schedule?.nextDueDate, DateTime.utc(2027, 7, 19, 8));
      expect(
        await repositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );

      final history = DriftHistoryProjectionRepository(
        database: database,
        attachments: repositories.attachments,
      );
      final projection = await history.projectForItem('item-1');
      final caseEntries = projection.entries.whereType<WorkCaseHistoryEntry>();
      expect(caseEntries, hasLength(1));
      expect(caseEntries.single.updates, hasLength(2));
      expect(caseEntries.single.closure?.id, value.id);
      expect(
        projection.entries.whereType<TaskHistoryEntry>().where(
          (entry) => entry.task.id == 'task-1',
        ),
        isEmpty,
      );
    },
  );

  test('closing a Maintenance case completes its exact source Task', () async {
    final created = await runtime.createFromTask(
      taskId: 'task-plan',
      workCase: workCase(id: 'case-plan'),
    );
    final value = closure(id: 'closure-plan').copyWith(workCaseId: created.id);

    await runtime.close(value);

    final sourceTask = await repositories.tasks.findById('task-plan');
    final schedule = await repositories.schedules.findById('schedule-plan');
    expect(
      (await runtime.findCaseById('case-plan'))?.status,
      WorkCaseStatus.completed,
    );
    expect(sourceTask?.status, TaskStatus.completed.name);
    expect(sourceTask?.completedAt, value.completedAt);
    expect(schedule?.nextDueDate, DateTime.utc(2026, 8, 19, 8));
    expect(
      await repositories.maintenanceRecords.listForItem('item-1'),
      isEmpty,
    );
  });

  test(
    'postponed and overdue source Tasks settle through case closure',
    () async {
      final reminderTask = (await repositories.tasks.findById('task-1'))!;
      final planTask = (await repositories.tasks.findById('task-plan'))!;
      await repositories.tasks.save(
        reminderTask.copyWith(
          status: TaskStatus.postponed.name,
          postponedAt: Value(now),
        ),
      );
      await repositories.tasks.save(
        planTask.copyWith(status: TaskStatus.overdue.name),
      );
      await runtime.createFromTask(taskId: 'task-1', workCase: workCase());
      await runtime.createFromTask(
        taskId: 'task-plan',
        workCase: workCase(id: 'case-plan'),
      );

      await runtime.close(closure());
      await runtime.close(
        closure(id: 'closure-plan').copyWith(workCaseId: 'case-plan'),
      );

      for (final taskId in ['task-1', 'task-plan']) {
        final task = await repositories.tasks.findById(taskId);
        expect(task?.status, TaskStatus.completed.name);
        expect(task?.postponedAt, isNull);
      }
    },
  );

  test('unsupported source Schedule rolls the whole closure back', () async {
    await runtime.createFromTask(taskId: 'task-1', workCase: workCase());
    final schedule = (await repositories.schedules.findById('schedule-1'))!;
    await repositories.schedules.save(
      schedule.copyWith(
        cycleType: 'custom',
        anchorPolicy: 'userDefined',
        userDefinedNextDate: Value(now.add(const Duration(days: 30))),
      ),
    );
    final taskBefore = await repositories.tasks.findById('task-1');
    final scheduleBefore = await repositories.schedules.findById('schedule-1');

    await expectLater(
      runtime.close(closure()),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect((await runtime.findCaseById('case-1'))?.isOpen, isTrue);
    expect(await runtime.findClosureForCase('case-1'), isNull);
    expect(await repositories.tasks.findById('task-1'), taskBefore);
    expect(await repositories.schedules.findById('schedule-1'), scheduleBefore);
  });

  test('Schedule write failure rolls every closure fact back', () async {
    await runtime.createFromTask(taskId: 'task-1', workCase: workCase());
    await database.customStatement('''
      CREATE TRIGGER reject_case_schedule_advance
      BEFORE UPDATE ON schedules
      BEGIN SELECT RAISE(ABORT, 'reject schedule update'); END
    ''');
    final taskBefore = await repositories.tasks.findById('task-1');
    final scheduleBefore = await repositories.schedules.findById('schedule-1');

    await expectLater(runtime.close(closure()), throwsA(anything));

    expect((await runtime.findCaseById('case-1'))?.isOpen, isTrue);
    expect(await runtime.findClosureForCase('case-1'), isNull);
    expect(await repositories.tasks.findById('task-1'), taskBefore);
    expect(await repositories.schedules.findById('schedule-1'), scheduleBefore);
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
