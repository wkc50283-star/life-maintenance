import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_plan.dart';
import 'package:life_maintenance/models/maintenance_plan_enums.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/screens/today_screen.dart';
import 'package:life_maintenance/services/legacy_drift_import_service.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    LocalDataIntegrityService.instance.resetForTesting();
  });

  testWidgets(
    'today generates a formal Drift Task without writing the legacy source',
    (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(
        now.year,
        now.month,
        now.day,
        8,
      ).subtract(const Duration(days: 1));
      final item = Item(
        id: 'item-1',
        name: '客廳冷氣',
        category: ItemCategory.appliance,
        createdAt: dueDate.subtract(const Duration(days: 30)),
      );
      final schedule = Schedule(
        id: 'schedule-1',
        itemId: item.id,
        cardId: 'card-aircon-filter-cleaning',
        cycleType: CycleType.monthly,
        interval: 1,
        startDate: dueDate.subtract(const Duration(days: 30)),
        nextDueDate: dueDate,
        title: '清洗濾網',
      );
      final rawItems = jsonEncode([item.toJson()]);
      final rawSchedules = jsonEncode([schedule.toJson()]);
      SharedPreferences.setMockInitialValues({
        'items': rawItems,
        'schedules': rawSchedules,
      });
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      await _importLegacy(database, storage);
      final root = AppCompositionRoot(database: database);
      await root.initialize();
      final generated = root.maintenanceTaskService.generateDueTasks(
        schedules: await root.scheduleRepository.loadSchedules(),
        existingTasks: await root.taskRepository.loadTasks(),
        today: now,
      );
      expect(generated, hasLength(1));
      await root.taskRepository.saveGeneratedTasks(generated);
      expect(await root.taskRepository.loadTasks(), hasLength(1));

      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();

      final tasks = await root.driftRepositories.tasks.listAll();
      expect(tasks, hasLength(1));
      expect(tasks.single.scheduleId, schedule.id);
      expect(tasks.single.dueDate, dueDate);
      expect(tasks.single.sourceType, 'scheduledMaintenance');
      expect(find.text('完成'), findsNothing);
      expect(await storage.readString('tasks'), isNull);
      expect(await storage.readString('maintenance_records'), isNull);
      expect(await storage.readString('items'), rawItems);
      expect(await storage.readString('schedules'), rawSchedules);

      await database.close();
    },
  );

  testWidgets(
    'an imported Task remains a reminder and creates no MaintenanceRecord',
    (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day, 8);
      final item = Item(
        id: 'item-1',
        name: '房屋租約',
        category: ItemCategory.house,
        createdAt: dueDate.subtract(const Duration(days: 30)),
      );
      final schedule = Schedule(
        id: 'schedule-1',
        itemId: item.id,
        cardId: 'manual-expiry-reminder',
        cycleType: CycleType.custom,
        interval: 1,
        startDate: dueDate.subtract(const Duration(days: 30)),
        nextDueDate: dueDate,
        title: '租約續約',
      );
      final task = Task(
        id: 'task-1',
        itemId: item.id,
        cardId: schedule.cardId,
        scheduleId: schedule.id,
        title: '租約續約',
        dueDate: dueDate,
      );
      final rawTasks = jsonEncode([task.toJson()]);
      SharedPreferences.setMockInitialValues({
        'items': jsonEncode([item.toJson()]),
        'schedules': jsonEncode([schedule.toJson()]),
        'tasks': rawTasks,
      });
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      await _importLegacy(database, storage);
      final root = AppCompositionRoot(database: database);
      await root.initialize();

      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('租約續約'), findsWidgets);
      expect(find.text('完成'), findsNothing);
      expect(
        await root.driftRepositories.maintenanceRecords.listForItem(item.id),
        isEmpty,
      );
      expect(await storage.readString('tasks'), rawTasks);

      await database.close();
    },
  );

  testWidgets(
    'formal plan and reminder schedules persist unique titled Tasks',
    (tester) async {
      final now = DateTime.now();
      final dueDate = DateTime(now.year, now.month, now.day, 8);
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);
      await _seedFormalDueSources(root, dueDate);
      await root.driftRepositories.tasks.save(
        TaskRow(
          id: 'task-plan-previous',
          itemId: 'item-1',
          sourceType: 'scheduledMaintenance',
          scheduleId: 'schedule-plan',
          maintenancePlanId: 'plan-filter',
          title: '清洗濾網',
          dueDate: dueDate.subtract(const Duration(days: 30)),
          status: TaskStatus.pending.name,
          createdAt: dueDate.subtract(const Duration(days: 30)),
          updatedAt: dueDate.subtract(const Duration(days: 30)),
        ),
      );
      final schedulesBefore = await root.driftRepositories.schedules.listAll();

      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();

      var tasks = await root.taskRepository.loadTasks();
      expect(tasks, hasLength(3));
      final planTask = tasks.singleWhere(
        (task) => task.scheduleId == 'schedule-plan' && task.dueDate == dueDate,
      );
      expect(planTask.itemId, 'item-1');
      expect(planTask.title, '清洗濾網');
      expect(planTask.status, TaskStatus.pending);
      expect(planTask.overdue, isFalse);
      final reminderTask = tasks.singleWhere(
        (task) =>
            task.scheduleId == 'schedule-reminder' && task.dueDate == dueDate,
      );
      expect(reminderTask.itemId, 'item-1');
      expect(reminderTask.title, '保固到期');
      expect(reminderTask.title, isNot('清洗濾網'));
      expect(reminderTask.title, isNot('保養提醒'));
      expect(reminderTask.status, TaskStatus.pending);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();
      tasks = await root.taskRepository.loadTasks();
      expect(tasks, hasLength(3));
      expect(tasks.where((task) => task.id == planTask.id), hasLength(1));
      expect(tasks.where((task) => task.id == reminderTask.id), hasLength(1));
      expect(await root.driftRepositories.schedules.listAll(), schedulesBefore);
      expect(
        (await root.historyProjectionRepository.projectForItem(
          'item-1',
        )).entries,
        isEmpty,
      );
      expect(
        await root.driftRepositories.maintenanceRecords.listForItem('item-1'),
        isEmpty,
      );

      await database.close();
    },
  );

  testWidgets('read-only runtime computes but does not persist due Tasks', (
    tester,
  ) async {
    final now = DateTime.now();
    final dueDate = DateTime(now.year, now.month, now.day, 8);
    final database = AppDatabase(NativeDatabase.memory());
    final root = _ReadOnlyRoot(database: database);
    await _seedFormalDueSources(root, dueDate);

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: TodayScreen())),
      ),
    );
    await tester.pumpAndSettle();

    expect(await root.taskRepository.loadTasks(), isEmpty);
    expect(find.text('清洗濾網'), findsNothing);
    expect(find.text('保固到期'), findsNothing);

    await database.close();
  });
}

class _ReadOnlyRoot extends AppCompositionRoot {
  _ReadOnlyRoot({required super.database});

  @override
  bool get formalWritesEnabled => false;
}

Future<void> _seedFormalDueSources(
  AppCompositionRoot root,
  DateTime dueDate,
) async {
  final createdAt = dueDate.subtract(const Duration(days: 30));
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'appliance',
      displayName: '家電',
      sortOrder: 0,
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: 'item-1',
      name: '測試冷氣',
      categoryId: 'category-1',
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.maintenancePlans.save(
    MaintenancePlan(
      id: 'plan-filter',
      itemId: 'item-1',
      title: '清洗濾網',
      planType: MaintenancePlanType.cleaning,
      riskLevel: RiskLevel.low,
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.generalReminders.save(
    GeneralReminderRow(
      schemaVersion: 1,
      id: 'reminder-warranty',
      itemId: 'item-1',
      title: '保固到期',
      reminderType: 'expiry',
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-plan',
      itemId: 'item-1',
      sourceType: 'maintenancePlan',
      maintenancePlanId: 'plan-filter',
      cycleType: 'monthly',
      interval: 1,
      startDate: createdAt,
      nextDueDate: dueDate,
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.schedules.save(
    ScheduleRow(
      id: 'schedule-reminder',
      itemId: 'item-1',
      sourceType: 'generalReminder',
      generalReminderId: 'reminder-warranty',
      cycleType: 'yearly',
      interval: 1,
      startDate: createdAt,
      nextDueDate: dueDate,
      status: 'active',
      anchorPolicy: 'fixedCalendarPeriod',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}

Future<void> _importLegacy(
  AppDatabase database,
  LocalStorageService storage,
) async {
  await LocalDataBackupService(storage).createPreMigrationBackups();
  await LegacyDriftImportService(
    database: database,
    source: SharedPreferencesLegacyImportSource(storage),
  ).execute(
    sourceWritesAreDisabled: true,
    allowVerifiedPlanningMutations: true,
  );
}
