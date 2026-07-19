import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_task_reminder_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_work_case_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';
import 'package:life_maintenance/repositories/task_reminder_runtime.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftTaskReminderRuntime runtime;
  final now = DateTime.utc(2026, 7, 19, 8);

  TaskRow task(String id, DateTime dueDate) => TaskRow(
    id: id,
    itemId: 'item-1',
    sourceType: 'scheduledReminder',
    scheduleId: 'schedule-1',
    generalReminderId: 'reminder-1',
    title: '租約續約',
    dueDate: dueDate,
    status: TaskStatus.pending.name,
    createdAt: now,
    updatedAt: now,
  );

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    final cases = DriftWorkCaseRuntime(
      database: database,
      workCases: repositories.workCases,
      closures: repositories.workCaseClosures,
      tasks: repositories.tasks,
    );
    runtime = DriftTaskReminderRuntime(
      database: database,
      repositories: repositories,
      workCaseRuntime: cases,
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
    expect(detail?.canStartWorkCase, isTrue);
  });

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
