import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/repositories/drift/drift_schedule_runtime_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftScheduleRuntimeRepository runtimeRepository;
  late DateTime now;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    runtimeRepository = DriftScheduleRuntimeRepository(
      database: database,
      repositories: repositories,
    );
    now = DateTime.utc(2026, 7, 19, 8);
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
    await repositories.items.save(
      ItemRow(
        id: 'item-1',
        name: '客廳冷氣',
        categoryId: 'category-1',
        createdAt: now,
        updatedAt: now,
        status: 'active',
      ),
    );
  });

  tearDown(() async {
    await database.close();
  });

  Schedule manualSchedule({
    required String id,
    DateTime? nextDueDate,
    String title = '保固到期',
  }) {
    return Schedule(
      id: id,
      itemId: 'item-1',
      cardId: 'manual-expiry-reminder',
      cycleType: CycleType.custom,
      interval: 1,
      startDate: now,
      nextDueDate: nextDueDate ?? DateTime.utc(2027, 7, 19, 8),
      title: title,
    );
  }

  test('reads every formal source and preserves anchor policy', () async {
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
    await repositories.milestones.save(
      Milestone(
        id: 'milestone-1',
        itemId: 'item-1',
        title: '第六年全面檢查',
        kind: MilestoneKind.deepInspection,
        triggerType: MilestoneTriggerType.manual,
        status: MilestoneStatus.pending,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.generalReminders.save(
      GeneralReminderRow(
        schemaVersion: 1,
        id: 'reminder-1',
        itemId: 'item-1',
        title: '保固到期',
        reminderType: 'expiry',
        status: 'active',
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
        legacyCardId: 'filter-cleaning',
        cycleType: 'monthly',
        interval: 1,
        startDate: now,
        nextDueDate: DateTime.utc(2026, 8, 19, 8),
        status: 'active',
        anchorPolicy: 'completionBased',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.schedules.save(
      ScheduleRow(
        id: 'schedule-reminder',
        itemId: 'item-1',
        sourceType: 'generalReminder',
        generalReminderId: 'reminder-1',
        cycleType: 'custom',
        interval: 1,
        startDate: now,
        nextDueDate: DateTime.utc(2027, 7, 19, 8),
        status: 'active',
        anchorPolicy: 'userDefined',
        userDefinedNextDate: DateTime.utc(2027, 7, 19, 8),
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
        nextDueDate: DateTime.utc(2027, 7, 19, 8),
        status: 'paused',
        anchorPolicy: 'fixedCalendarPeriod',
        createdAt: now,
        updatedAt: now,
      ),
    );

    final schedules = await runtimeRepository.loadSchedules();

    expect(schedules, hasLength(3));
    expect(
      schedules.singleWhere((value) => value.id == 'schedule-plan').title,
      '清洗濾網',
    );
    expect(
      schedules
          .singleWhere((value) => value.id == 'schedule-plan')
          .strictPeriodMode,
      isFalse,
    );
    expect(
      schedules.singleWhere((value) => value.id == 'schedule-reminder').cardId,
      'manual-expiry-reminder',
    );
    expect(
      schedules.singleWhere((value) => value.id == 'schedule-milestone').status,
      ScheduleStatus.paused,
    );
  });

  test(
    'creates GeneralReminder and Schedule atomically without legacy writes',
    () async {
      final schedule = manualSchedule(id: 'schedule-1');

      await runtimeRepository.saveSchedules([schedule]);

      final row = await repositories.schedules.findById(schedule.id);
      expect(row?.sourceType, 'generalReminder');
      expect(row?.anchorPolicy, 'userDefined');
      expect(row?.userDefinedNextDate, schedule.nextDueDate);
      final reminder = await repositories.generalReminders.findById(
        'runtime-reminder-${schedule.id}',
      );
      expect(reminder?.title, '保固到期');
      expect((await runtimeRepository.loadSchedules()).single.title, '保固到期');
    },
  );

  test('preserves completion-based policy when runtime reschedules', () async {
    await repositories.maintenancePlans.save(
      MaintenancePlan(
        id: 'plan-1',
        itemId: 'item-1',
        title: '更換機油',
        planType: MaintenancePlanType.routineService,
        riskLevel: RiskLevel.medium,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await repositories.schedules.save(
      ScheduleRow(
        id: 'schedule-1',
        itemId: 'item-1',
        sourceType: 'maintenancePlan',
        maintenancePlanId: 'plan-1',
        cycleType: 'monthly',
        interval: 1,
        startDate: now,
        nextDueDate: DateTime.utc(2026, 8, 19, 8),
        status: 'active',
        anchorPolicy: 'completionBased',
        createdAt: now,
        updatedAt: now,
      ),
    );
    final schedule = (await runtimeRepository.loadSchedules()).single;

    await runtimeRepository.saveSchedules([
      schedule.copyWith(nextDueDate: DateTime.utc(2026, 9, 19, 8)),
    ]);

    expect(
      (await repositories.schedules.findById('schedule-1'))?.anchorPolicy,
      'completionBased',
    );
  });

  test('unchanged ended rows do not block another Schedule update', () async {
    final ended = manualSchedule(id: 'schedule-ended');
    final active = manualSchedule(id: 'schedule-active');
    await runtimeRepository.saveSchedules([ended, active]);
    await runtimeRepository.saveSchedules([
      ended.copyWith(status: ScheduleStatus.ended),
      active,
    ]);

    final newDate = DateTime.utc(2028, 7, 19, 8);
    await runtimeRepository.saveSchedules([
      ended.copyWith(status: ScheduleStatus.ended),
      active.copyWith(nextDueDate: newDate),
    ]);

    expect(
      (await repositories.schedules.findById(active.id))?.nextDueDate,
      newDate,
    );
  });

  test(
    'rolls back the whole batch when one new source is unsupported',
    () async {
      final valid = manualSchedule(id: 'schedule-valid');
      final invalid = Schedule(
        id: 'schedule-invalid',
        itemId: 'item-1',
        cardId: 'unverified-card',
        cycleType: CycleType.monthly,
        interval: 1,
        startDate: now,
        nextDueDate: DateTime.utc(2026, 8, 19, 8),
      );

      await expectLater(
        runtimeRepository.saveSchedules([valid, invalid]),
        throwsA(isA<RepositoryConstraintException>()),
      );

      expect(await repositories.schedules.listAll(), isEmpty);
      expect(
        await repositories.generalReminders.findById(
          'runtime-reminder-${valid.id}',
        ),
        isNull,
      );
    },
  );

  test('rejects implicit deletion of a formal Schedule', () async {
    await runtimeRepository.saveSchedules([manualSchedule(id: 'schedule-1')]);

    await expectLater(
      runtimeRepository.saveSchedules(const []),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await repositories.schedules.listAll(), hasLength(1));
  });
}
