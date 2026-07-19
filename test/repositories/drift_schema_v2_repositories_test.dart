import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/maintenance_plan_step.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_work_case_repository.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftWorkCaseRepository workCases;
  late DateTime now;

  ItemRow item(String id) {
    return ItemRow(
      id: id,
      name: '生活項目 $id',
      categoryId: 'category-1',
      createdAt: now,
      updatedAt: now,
      status: 'active',
    );
  }

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    workCases = DriftWorkCaseRepository(database);
    now = DateTime.utc(2026, 7, 18, 8);

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
    await repositories.items.save(item('item-1'));
    await repositories.items.save(item('item-2'));
  });

  tearDown(() async {
    await database.close();
  });

  MaintenancePlan plan({
    String id = 'plan-1',
    String itemId = 'item-1',
    List<MaintenancePlanStep>? steps,
  }) {
    return MaintenancePlan(
      id: id,
      itemId: itemId,
      title: '濾網清潔',
      planType: MaintenancePlanType.cleaning,
      riskLevel: RiskLevel.low,
      createdAt: now,
      updatedAt: now,
      steps:
          steps ??
          const [
            MaintenancePlanStep(
              id: 'step-1',
              order: 0,
              title: '關閉電源',
              description: '先確認設備停止運轉',
            ),
            MaintenancePlanStep(
              id: 'step-2',
              order: 1,
              title: '清潔濾網',
              description: '依安全說明清潔',
            ),
          ],
    );
  }

  GeneralReminderRow reminder({
    String id = 'reminder-1',
    String itemId = 'item-1',
    String? description,
  }) {
    return GeneralReminderRow(
      schemaVersion: 1,
      id: id,
      itemId: itemId,
      title: '保固到期',
      description: description,
      reminderType: 'warrantyExpiry',
      status: 'active',
      createdAt: now,
      updatedAt: now,
    );
  }

  ScheduleRow reminderSchedule({
    String id = 'schedule-1',
    String itemId = 'item-1',
    String reminderId = 'reminder-1',
  }) {
    return ScheduleRow(
      id: id,
      itemId: itemId,
      sourceType: 'generalReminder',
      generalReminderId: reminderId,
      cycleType: 'yearly',
      interval: 1,
      startDate: now,
      nextDueDate: DateTime.utc(2027, 7, 18, 8),
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: now,
      updatedAt: now,
    );
  }

  TaskRow reminderTask({
    String id = 'task-1',
    String itemId = 'item-1',
    String scheduleId = 'schedule-1',
    String reminderId = 'reminder-1',
    DateTime? dueDate,
  }) {
    return TaskRow(
      id: id,
      itemId: itemId,
      sourceType: 'scheduledReminder',
      scheduleId: scheduleId,
      generalReminderId: reminderId,
      title: '確認保固',
      dueDate: dueDate ?? DateTime.utc(2027, 7, 18, 8),
      status: 'pending',
      createdAt: now,
      updatedAt: now,
    );
  }

  WorkCase manualCase({String id = 'case-1', String itemId = 'item-1'}) {
    return WorkCase(
      id: id,
      itemId: itemId,
      sourceType: WorkCaseSourceType.manual,
      caseType: WorkCaseType.repair,
      title: '冷氣異音',
      status: WorkCaseStatus.inProgress,
      createdAt: now,
      updatedAt: now,
      startedAt: now,
    );
  }

  test('ItemCategory and Item CRUD enforce Item as the root', () async {
    final updated = item('item-1').copyWith(name: '客廳冷氣');
    await repositories.items.save(updated);

    expect((await repositories.items.findById('item-1'))?.name, '客廳冷氣');
    expect(await repositories.items.listAll(), hasLength(2));
    await expectLater(
      repositories.itemCategories.deleteUnused('category-1'),
      throwsA(isA<RepositoryConstraintException>()),
    );

    await repositories.maintenancePlans.save(plan());
    await expectLater(
      repositories.items.deleteUnused('item-1'),
      throwsA(isA<RepositoryConstraintException>()),
    );
    final archivedAt = now.add(const Duration(hours: 1));
    await repositories.items.archive('item-1', archivedAt);
    final archived = await repositories.items.findById('item-1');
    expect(archived?.status, 'archived');
    expect(archived?.archivedAt, archivedAt);
  });

  test(
    'MaintenancePlan and ordered steps round trip through one transaction',
    () async {
      final maintenancePlan = plan();
      await repositories.maintenancePlans.save(maintenancePlan);

      final restored = await repositories.maintenancePlans.findById(
        maintenancePlan.id,
      );
      expect(restored?.toJson(), maintenancePlan.toJson());
      expect(restored?.steps.map((step) => step.order), [0, 1]);
    },
  );

  test('MaintenancePlan step conflict rolls back the new plan', () async {
    await repositories.maintenancePlans.save(plan());

    await expectLater(
      repositories.maintenancePlans.save(
        plan(
          id: 'plan-2',
          steps: const [
            MaintenancePlanStep(
              id: 'step-1',
              order: 0,
              title: '重複主鍵',
              description: '',
            ),
          ],
        ),
      ),
      throwsA(anything),
    );

    expect(await repositories.maintenancePlans.findById('plan-2'), isNull);
    expect(await repositories.maintenancePlans.findById('plan-1'), isNotNull);
  });

  test('Schedule and Task reject cross-Item or mismatched sources', () async {
    await repositories.generalReminders.save(
      reminder(description: '稍後可以清除的說明'),
    );
    await repositories.generalReminders.save(reminder());
    expect(
      (await repositories.generalReminders.findById('reminder-1'))?.description,
      isNull,
    );

    await expectLater(
      repositories.schedules.save(reminderSchedule(itemId: 'item-2')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await repositories.schedules.findById('schedule-1'), isNull);

    await repositories.schedules.save(reminderSchedule());
    await expectLater(
      repositories.tasks.save(reminderTask(itemId: 'item-2')),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await repositories.tasks.findById('task-1'), isNull);

    await repositories.tasks.save(reminderTask());
    expect(await repositories.tasks.listForItem('item-1'), hasLength(1));
  });

  test('duplicate Schedule period cannot create a second Task', () async {
    await repositories.generalReminders.save(reminder());
    await repositories.schedules.save(reminderSchedule());
    await repositories.tasks.save(reminderTask());

    await expectLater(
      repositories.tasks.save(reminderTask(id: 'task-2')),
      throwsA(anything),
    );

    expect(await repositories.tasks.listForItem('item-1'), hasLength(1));
    expect(await repositories.tasks.findById('task-2'), isNull);
  });

  test(
    'Milestone conversion preserves its trigger and rejects cross-Item plan',
    () async {
      await repositories.maintenancePlans.save(plan());
      final milestone = Milestone(
        id: 'milestone-1',
        itemId: 'item-1',
        title: '第六年全面檢查',
        kind: MilestoneKind.deepInspection,
        triggerType: MilestoneTriggerType.usageYears,
        sourcePlanId: 'plan-1',
        thresholdValue: 6,
        thresholdUnit: 'years',
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      );

      await repositories.milestones.save(milestone);
      expect(
        (await repositories.milestones.findById(milestone.id))?.toJson(),
        milestone.toJson(),
      );

      await expectLater(
        repositories.milestones.save(
          milestone.copyWith(id: 'milestone-2', itemId: 'item-2'),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(await repositories.milestones.findById('milestone-2'), isNull);
    },
  );

  test(
    'MaintenanceRecord validates Task and Plan Item in one transaction',
    () async {
      await repositories.generalReminders.save(reminder());
      await repositories.schedules.save(reminderSchedule());
      await repositories.tasks.save(reminderTask());

      final invalid = MaintenanceRecordRow(
        id: 'record-invalid',
        itemId: 'item-2',
        taskId: 'task-1',
        recordType: 'other',
        date: now,
        title: '錯誤跨項目紀錄',
        createdAt: now,
      );
      await expectLater(
        repositories.maintenanceRecords.create(invalid),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(
        await repositories.maintenanceRecords.findById('record-invalid'),
        isNull,
      );

      final valid = MaintenanceRecordRow(
        id: 'record-1',
        itemId: 'item-1',
        taskId: 'task-1',
        recordType: 'expiryHandled',
        date: now,
        title: '已確認保固',
        createdAt: now,
      );
      await repositories.maintenanceRecords.create(valid);
      expect(await repositories.maintenanceRecords.listForItem('item-1'), [
        valid,
      ]);
    },
  );

  test(
    'formal closure is atomic and WorkCase remains separate from Task',
    () async {
      await workCases.saveCase(manualCase());
      await repositories.generalReminders.save(
        reminder(id: 'reminder-2', itemId: 'item-2'),
      );
      await repositories.schedules.save(
        reminderSchedule(
          id: 'schedule-2',
          itemId: 'item-2',
          reminderId: 'reminder-2',
        ),
      );

      final invalidClosure = WorkCaseClosure(
        id: 'closure-invalid',
        workCaseId: 'case-1',
        completedAt: now.add(const Duration(hours: 4)),
        finalResult: '完成',
        completionSummary: '測試正常',
        totalCost: 1200,
        followUpType: WorkCaseFollowUpType.schedule,
        nextScheduleId: 'schedule-2',
        createdAt: now.add(const Duration(hours: 4)),
      );
      await expectLater(
        repositories.workCaseClosures.closeCase(invalidClosure),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(await repositories.workCaseClosures.findForCase('case-1'), isNull);
      expect(
        (await workCases.findCaseById('case-1'))?.status,
        WorkCaseStatus.inProgress,
      );

      final completedAt = now.add(const Duration(hours: 5));
      final closure = WorkCaseClosure(
        id: 'closure-1',
        workCaseId: 'case-1',
        completedAt: completedAt,
        finalResult: '恢復正常',
        completionSummary: '更換零件並完成測試',
        totalCost: 1200,
        createdAt: completedAt,
      );
      await repositories.workCaseClosures.closeCase(closure);

      expect(
        (await repositories.workCaseClosures.findForCase('case-1'))?.toJson(),
        closure.toJson(),
      );
      final closedCase = await workCases.findCaseById('case-1');
      expect(closedCase?.status, WorkCaseStatus.completed);
      expect(closedCase?.closedAt, completedAt);
      await expectLater(
        workCases.appendUpdate(
          WorkCaseUpdate(
            id: 'late-update',
            workCaseId: 'case-1',
            occurredAt: completedAt.add(const Duration(minutes: 1)),
            description: '結案後不得追加',
            createdAt: completedAt.add(const Duration(minutes: 1)),
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
    },
  );

  test('Attachment validates owner and records lifecycle timestamps', () async {
    final invalid = Attachment(
      id: 'attachment-invalid',
      ownerType: AttachmentOwnerType.item,
      ownerId: 'missing-item',
      kind: AttachmentKind.photo,
      storageIdentifier: 'managed/photo.jpg',
      mimeType: 'image/jpeg',
      createdAt: now,
    );
    await expectLater(
      repositories.attachments.create(invalid),
      throwsA(isA<RepositoryConstraintException>()),
    );

    final attachment = Attachment(
      id: 'attachment-1',
      ownerType: AttachmentOwnerType.item,
      ownerId: 'item-1',
      kind: AttachmentKind.photo,
      storageIdentifier: 'managed/photo.jpg',
      mimeType: 'image/jpeg',
      contentHash: 'sha256:test',
      createdAt: now,
    );
    await repositories.attachments.create(attachment);
    final verifiedAt = now.add(const Duration(minutes: 1));
    final missingAt = now.add(const Duration(minutes: 2));
    final deletedAt = now.add(const Duration(minutes: 3));
    await repositories.attachments.markAvailable(attachment.id, verifiedAt);
    await repositories.attachments.markMissing(attachment.id, missingAt);
    await repositories.attachments.markDeleted(attachment.id, deletedAt);

    final restored = await repositories.attachments.findById(attachment.id);
    expect(restored?.verifiedAt, verifiedAt);
    expect(restored?.missingAt, missingAt);
    expect(restored?.deletedAt, deletedAt);
    expect(restored?.state, AttachmentState.deleted);
  });

  test('canceling a WorkCase also requires one formal Closure', () async {
    await workCases.saveCase(manualCase(id: 'case-cancel'));
    final canceledAt = now.add(const Duration(hours: 2));
    final closure = WorkCaseClosure(
      id: 'closure-cancel',
      workCaseId: 'case-cancel',
      completedAt: canceledAt,
      finalResult: '取消處理',
      completionSummary: '問題未再出現，使用者決定停止處理',
      totalCost: 0,
      createdAt: canceledAt,
    );

    await repositories.workCaseClosures.cancelCase(
      closure,
      cancellationReason: '目前不需要繼續處理',
    );

    final canceled = await workCases.findCaseById('case-cancel');
    expect(canceled?.status, WorkCaseStatus.canceled);
    expect(canceled?.canceledAt, canceledAt);
    expect(canceled?.cancellationReason, '目前不需要繼續處理');
    expect(
      (await repositories.workCaseClosures.findForCase('case-cancel'))?.id,
      closure.id,
    );
  });

  test('all Repository writes leave foreign keys valid', () async {
    final violations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    expect(violations, isEmpty);
  });
}
