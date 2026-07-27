import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_task_reminder_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_work_case_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';
import 'package:life_maintenance/repositories/task_reminder_runtime.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftTaskReminderRuntime runtime;
  late DriftWorkCaseRuntime caseRuntime;
  final now = DateTime.utc(2026, 7, 19, 8);

  TaskRow task(
    String id,
    DateTime dueDate, {
    String scheduleId = 'schedule-1',
  }) => TaskRow(
    id: id,
    itemId: 'item-1',
    sourceType: 'scheduledReminder',
    scheduleId: scheduleId,
    generalReminderId: 'reminder-1',
    title: '租約續約',
    dueDate: dueDate,
    status: TaskStatus.pending.name,
    createdAt: now,
    updatedAt: now,
  );

  Future<void> seedMaintenanceTask({
    String cycleType = 'monthly',
    TaskStatus status = TaskStatus.pending,
  }) async {
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
        cycleType: cycleType,
        interval: 1,
        startDate: now,
        nextDueDate: now,
        status: ScheduleStatus.active.name,
        anchorPolicy: cycleType == 'custom'
            ? 'userDefined'
            : 'fixedCalendarPeriod',
        userDefinedNextDate: cycleType == 'custom'
            ? now.add(const Duration(days: 30))
            : null,
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
        status: status.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    caseRuntime = DriftWorkCaseRuntime(
      database: database,
      workCases: repositories.workCases,
      closures: repositories.workCaseClosures,
      tasks: repositories.tasks,
    );
    runtime = DriftTaskReminderRuntime(
      database: database,
      repositories: repositories,
      workCaseRuntime: caseRuntime,
    );
    await repositories.itemCategories.save(
      ItemCategoryRow(
        id: 'category-1',
        systemCode: 'document',
        displayName: '文件',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.items.save(
      ItemRow(
        id: 'item-1',
        name: '房屋租約',
        categoryId: 'category-1',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.generalReminders.save(
      GeneralReminderRow(
        schemaVersion: 1,
        id: 'reminder-1',
        itemId: 'item-1',
        title: '租約續約',
        description: '確認條件並預留辦理時間',
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
    await repositories.tasks.save(task('task-1', now));
  });

  tearDown(() => database.close());

  test('projects the formal source, Item and Schedule rule', () async {
    final detail = await runtime.findReminder('task-1');

    expect(detail?.itemName, '房屋租約');
    expect(detail?.sourceKind, TaskReminderSourceKind.generalReminder);
    expect(detail?.sourceTitle, '租約續約');
    expect(detail?.sourceDescription, '確認條件並預留辦理時間');
    expect(detail?.scheduleCycleType, 'yearly');
    expect(detail?.scheduleAnchorPolicy, 'fixedCalendarPeriod');
    expect(detail?.canComplete, isTrue);
    expect(detail?.canStartWorkCase, isTrue);
  });

  test('completes a Reminder Task and advances all recurring cycles', () async {
    final dueDate = DateTime.utc(2026, 1, 31, 8);
    final expectedDates = <String, DateTime>{
      'daily': DateTime.utc(2026, 2, 2, 8),
      'weekly': DateTime.utc(2026, 2, 14, 8),
      'monthly': DateTime.utc(2026, 3, 31, 8),
      'quarterly': DateTime.utc(2026, 7, 31, 8),
      'semiAnnual': DateTime.utc(2027, 1, 31, 8),
      'yearly': DateTime.utc(2028, 1, 31, 8),
    };

    for (final MapEntry(key: cycle, value: expected) in expectedDates.entries) {
      final schedule = (await repositories.schedules.findById('schedule-1'))!;
      final scheduleId = 'schedule-$cycle';
      await repositories.schedules.save(
        schedule.copyWith(
          id: scheduleId,
          cycleType: cycle,
          interval: 2,
          nextDueDate: dueDate,
          updatedAt: dueDate,
        ),
      );
      final taskId = 'task-$cycle';
      await repositories.tasks.save(
        task(taskId, dueDate, scheduleId: scheduleId),
      );

      await runtime.complete(taskId, dueDate);

      final completed = await repositories.tasks.findById(taskId);
      final advanced = await repositories.schedules.findById(scheduleId);
      expect(completed?.status, TaskStatus.completed.name, reason: cycle);
      expect(completed?.completedAt, dueDate, reason: cycle);
      expect(completed?.postponedAt, isNull, reason: cycle);
      expect(completed?.dueDate, dueDate, reason: cycle);
      expect(advanced?.nextDueDate, expected, reason: cycle);
      expect(advanced?.cycleType, cycle, reason: cycle);
      expect(advanced?.interval, 2, reason: cycle);
      expect(await repositories.tasks.listAll(), isNotEmpty);
    }
  });

  test('completionBased anchor advances from completion time', () async {
    final schedule = (await repositories.schedules.findById('schedule-1'))!;
    final dueDate = DateTime.utc(2026, 7, 19, 8);
    final completedAt = DateTime.utc(2026, 7, 25, 10);
    await repositories.schedules.save(
      schedule.copyWith(
        cycleType: 'monthly',
        interval: 1,
        nextDueDate: dueDate,
        anchorPolicy: 'completionBased',
      ),
    );

    await runtime.complete('task-1', completedAt);

    expect(
      (await repositories.schedules.findById('schedule-1'))?.nextDueDate,
      DateTime.utc(2026, 8, 25, 10),
    );
  });

  test('custom Schedule is not completable in detail or Runtime', () async {
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

    expect((await runtime.findReminder('task-1'))?.canComplete, isFalse);
    await expectLater(
      runtime.complete('task-1', now),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await repositories.tasks.findById('task-1'), taskBefore);
    expect(await repositories.schedules.findById('schedule-1'), scheduleBefore);
  });

  test(
    'exact open source Task case blocks completion only for that Task',
    () async {
      await repositories.tasks.save(
        task('task-2', now.add(const Duration(days: 1))),
      );
      await runtime.startWorkCase(
        taskId: 'task-2',
        workCase: WorkCase(
          id: 'case-2',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.administrative,
          title: '處理另一個到期實例',
          startedAt: now,
          status: WorkCaseStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      );
      await caseRuntime.updateStatus(
        'case-2',
        WorkCaseStatus.waiting,
        now.add(const Duration(hours: 1)),
      );

      expect((await runtime.findReminder('task-1'))?.canComplete, isTrue);
      expect((await runtime.findReminder('task-2'))?.canComplete, isFalse);
      await expectLater(
        runtime.complete('task-2', now),
        throwsA(isA<RepositoryConstraintException>()),
      );
      await runtime.complete('task-1', now);
      expect(
        (await repositories.tasks.findById('task-1'))?.status,
        TaskStatus.completed.name,
      );
      expect((await caseRuntime.findCaseById('case-2'))?.isOpen, isTrue);
    },
  );

  test('a closed source Task case does not block completion', () async {
    await runtime.startWorkCase(
      taskId: 'task-1',
      workCase: WorkCase(
        id: 'case-1',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.administrative,
        title: '完成續約處理',
        startedAt: now,
        status: WorkCaseStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await caseRuntime.close(
      WorkCaseClosure(
        id: 'closure-1',
        workCaseId: 'case-1',
        completedAt: now,
        finalResult: '已完成',
        completionSummary: '完成續約處理',
        totalCost: 0,
        createdAt: now,
      ),
    );

    expect((await runtime.findReminder('task-1'))?.canComplete, isTrue);
    await runtime.complete('task-1', now);
    expect(
      (await repositories.tasks.findById('task-1'))?.status,
      TaskStatus.completed.name,
    );
  });

  test('terminal and non-Reminder Tasks cannot complete twice', () async {
    await runtime.complete('task-1', now);
    final completed = await repositories.tasks.findById('task-1');
    final schedule = await repositories.schedules.findById('schedule-1');

    await expectLater(
      runtime.complete('task-1', now.add(const Duration(days: 1))),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await repositories.tasks.findById('task-1'), completed);
    expect(await repositories.schedules.findById('schedule-1'), schedule);

    await repositories.tasks.save(
      TaskRow(
        id: 'manual-task',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '手動提醒',
        dueDate: now,
        status: TaskStatus.pending.name,
        createdAt: now,
        updatedAt: now,
      ),
    );
    expect((await runtime.findReminder('manual-task'))?.canComplete, isFalse);
    await expectLater(
      runtime.complete('manual-task', now),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test('Schedule write failure rolls Task completion back', () async {
    await database.customStatement('''
      CREATE TRIGGER reject_schedule_advance
      BEFORE UPDATE ON schedules
      BEGIN SELECT RAISE(ABORT, 'reject schedule update'); END
    ''');
    final taskBefore = await repositories.tasks.findById('task-1');
    final scheduleBefore = await repositories.schedules.findById('schedule-1');

    await expectLater(runtime.complete('task-1', now), throwsA(anything));

    expect(await repositories.tasks.findById('task-1'), taskBefore);
    expect(await repositories.schedules.findById('schedule-1'), scheduleBefore);
  });

  test('completed Task is projected once without parallel records', () async {
    final history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );
    expect(
      (await history.projectForItem(
        'item-1',
      )).entries.whereType<TaskHistoryEntry>(),
      isEmpty,
    );

    await runtime.complete('task-1', now);
    final entries = (await history.projectForItem(
      'item-1',
    )).entries.whereType<TaskHistoryEntry>().toList();

    expect(entries, hasLength(1));
    expect(entries.single.task.id, 'task-1');
    expect(entries.single.task.title, '租約續約');
    expect(entries.single.task.status, TaskStatus.completed.name);
    expect(entries.single.occurredAt, now);
    expect(
      await repositories.maintenanceRecords.listForItem('item-1'),
      isEmpty,
    );
    expect(await repositories.workCases.listCasesForItem('item-1'), isEmpty);
  });

  test(
    'completes a MaintenancePlan Task and projects its existing History',
    () async {
      await seedMaintenanceTask();
      final history = DriftHistoryProjectionRepository(
        database: database,
        attachments: repositories.attachments,
      );

      final detail = await runtime.findReminder('task-plan');
      expect(detail?.sourceKind, TaskReminderSourceKind.maintenancePlan);
      expect(detail?.canComplete, isTrue);

      await runtime.complete('task-plan', now);

      final completed = await repositories.tasks.findById('task-plan');
      final schedule = await repositories.schedules.findById('schedule-plan');
      final historyEntries = (await history.projectForItem('item-1')).entries
          .whereType<TaskHistoryEntry>()
          .where((entry) => entry.task.id == 'task-plan');
      expect(completed?.status, TaskStatus.completed.name);
      expect(completed?.completedAt, now);
      expect(completed?.dueDate, now);
      expect(schedule?.nextDueDate, DateTime.utc(2026, 8, 19, 8));
      expect(historyEntries, hasLength(1));
      expect(historyEntries.single.task.title, '清洗濾網');
      expect(historyEntries.single.occurredAt, now);
      expect(
        await repositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );
    },
  );

  test('MaintenancePlan custom and terminal Tasks cannot complete', () async {
    await seedMaintenanceTask(cycleType: 'custom');
    final taskBefore = await repositories.tasks.findById('task-plan');
    final scheduleBefore = await repositories.schedules.findById(
      'schedule-plan',
    );
    expect((await runtime.findReminder('task-plan'))?.canComplete, isFalse);
    await expectLater(
      runtime.complete('task-plan', now),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await repositories.tasks.findById('task-plan'), taskBefore);
    expect(
      await repositories.schedules.findById('schedule-plan'),
      scheduleBefore,
    );

    final schedule = scheduleBefore!;
    await repositories.schedules.save(schedule.copyWith(cycleType: 'monthly'));
    final row = taskBefore!;
    await repositories.tasks.save(
      row.copyWith(status: TaskStatus.completed.name, completedAt: Value(now)),
    );
    await repositories.tasks.save(
      row.copyWith(
        id: 'task-plan-canceled',
        dueDate: now.add(const Duration(days: 1)),
        status: TaskStatus.canceled.name,
      ),
    );
    for (final taskId in ['task-plan', 'task-plan-canceled']) {
      await expectLater(
        runtime.complete(taskId, now.add(const Duration(days: 1))),
        throwsA(isA<RepositoryConstraintException>()),
      );
    }
    expect(
      (await repositories.schedules.findById('schedule-plan'))?.nextDueDate,
      now,
    );
  });

  test(
    'MaintenancePlan completion is blocked by the exact open WorkCase',
    () async {
      await seedMaintenanceTask();
      await runtime.startWorkCase(
        taskId: 'task-plan',
        workCase: WorkCase(
          id: 'case-plan',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.maintenance,
          title: '處理清洗濾網',
          startedAt: now,
          status: WorkCaseStatus.inProgress,
          createdAt: now,
          updatedAt: now,
        ),
      );
      expect((await runtime.findReminder('task-plan'))?.canComplete, isFalse);
      await expectLater(
        runtime.complete('task-plan', now),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(
        (await repositories.tasks.findById('task-plan'))?.status,
        TaskStatus.pending.name,
      );
      expect(
        (await repositories.schedules.findById('schedule-plan'))?.nextDueDate,
        now,
      );
      expect(
        (await caseRuntime.findCaseById('case-plan'))?.sourceTaskId,
        'task-plan',
      );
    },
  );

  test(
    'pause, reschedule and resume update only the mutable Task fields',
    () async {
      final changedAt = now.add(const Duration(hours: 1));
      final newDueDate = now.add(const Duration(days: 30));

      await runtime.pause('task-1', changedAt);
      var row = await repositories.tasks.findById('task-1');
      expect(row?.status, TaskStatus.postponed.name);
      expect(row?.postponedAt, changedAt);
      expect(row?.sourceType, 'scheduledReminder');
      expect(row?.generalReminderId, 'reminder-1');

      await runtime.reschedule('task-1', newDueDate, changedAt);
      row = await repositories.tasks.findById('task-1');
      expect(row?.dueDate, newDueDate);
      expect(row?.status, TaskStatus.postponed.name);

      await runtime.resume('task-1', changedAt);
      row = await repositories.tasks.findById('task-1');
      expect(row?.status, TaskStatus.pending.name);
      expect(row?.postponedAt, isNull);
      expect(await repositories.workCases.listCasesForItem('item-1'), isEmpty);
      expect(
        await repositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );
    },
  );

  test('duplicate reschedule is rejected and rolls the Task back', () async {
    final occupiedDate = now.add(const Duration(days: 30));
    await repositories.tasks.save(task('task-2', occupiedDate));
    final before = await repositories.tasks.findById('task-1');

    await expectLater(
      runtime.reschedule(
        'task-1',
        occupiedDate,
        now.add(const Duration(hours: 1)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await repositories.tasks.findById('task-1'), before);
  });

  test('reschedule rejects a past date and preserves the Task', () async {
    final before = await repositories.tasks.findById('task-1');

    await expectLater(
      runtime.reschedule('task-1', now.subtract(const Duration(days: 1)), now),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await repositories.tasks.findById('task-1'), before);
  });

  test(
    'starting work creates only an open WorkCase and preserves Task',
    () async {
      final before = await repositories.tasks.findById('task-1');
      final startedAt = now.add(const Duration(hours: 2));

      final created = await runtime.startWorkCase(
        taskId: 'task-1',
        workCase: WorkCase(
          id: 'case-1',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.administrative,
          title: '辦理租約續約',
          startedAt: startedAt,
          status: WorkCaseStatus.inProgress,
          createdAt: startedAt,
          updatedAt: startedAt,
        ),
      );

      expect(created.sourceType, WorkCaseSourceType.generalReminder);
      expect(created.sourceId, 'reminder-1');
      expect(created.status, WorkCaseStatus.inProgress);
      expect(await repositories.tasks.findById('task-1'), before);
      expect(await repositories.workCaseClosures.findForCase('case-1'), isNull);
      expect(
        await repositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );
    },
  );

  test('terminal Tasks cannot be paused, resumed or rescheduled', () async {
    final row = (await repositories.tasks.findById('task-1'))!;
    await repositories.tasks.save(
      row.copyWith(status: TaskStatus.completed.name, completedAt: Value(now)),
    );

    await expectLater(
      runtime.pause('task-1', now),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      runtime.reschedule('task-1', now.add(const Duration(days: 1)), now),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });
}
