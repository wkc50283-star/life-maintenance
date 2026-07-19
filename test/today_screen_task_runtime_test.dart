import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/screens/today_screen.dart';
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
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );
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
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );
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
}
