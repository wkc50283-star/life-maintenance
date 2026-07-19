import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/legacy_drift_import_report.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    LocalDataIntegrityService.instance.resetForTesting();
  });

  test(
    'constructs one database, Drift repository set, and runtime services',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: LocalStorageService(),
      );

      expect(root.database, same(database));
      expect(root.driftRepositories.items, isNotNull);
      expect(root.driftRepositories.tasks, isNotNull);
      expect(root.driftRepositories.workCases, isNotNull);
      expect(root.driftRepositories.workCaseClosures, isNotNull);
      expect(root.itemRepository, isNotNull);
      expect(root.localDataBackupService, isNotNull);
      expect(root.maintenanceTaskService, isNotNull);
      await database.close();
    },
  );

  testWidgets('scope exposes the injected root', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
      legacyStorage: LocalStorageService(),
    );
    late AppRuntimeDependencies resolved;

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: Builder(
          builder: (context) {
            resolved = AppCompositionScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, same(root));
    await root.database.close();
  });

  test(
    'startup imports once, switches Item reads, and freezes source',
    () async {
      final item = Item(
        id: 'item-1',
        name: '客廳冷氣',
        category: ItemCategory.appliance,
        createdAt: DateTime.utc(2026, 1, 2),
        location: '客廳',
      );
      final rawItems = jsonEncode([item.toJson()]);
      SharedPreferences.setMockInitialValues({'items': rawItems});
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );

      final first = await root.initialize();

      expect(first.mode, RuntimeDataMode.driftHistoryAttachments);
      expect(first.usesDriftPlanning, isTrue);
      expect(first.usesDriftTasks, isTrue);
      expect(first.usesDriftWorkCases, isTrue);
      expect(first.usesDriftHistoryAttachments, isTrue);
      expect(root.workCaseRuntime, isNotNull);
      expect(root.historyProjectionRepository, isNotNull);
      expect(root.attachmentRuntime, isNotNull);
      expect(root.usesDriftPlanning, isTrue);
      expect(root.maintenancePlanRepository, isNotNull);
      expect(root.generalReminderRepository, isNotNull);
      expect(root.milestoneRepository, isNotNull);
      expect(first.importReport?.status, LegacyDriftImportStatus.imported);
      expect(root.legacyWritesEnabled, isFalse);
      final importedItems = await root.itemReadRepository.loadItems();
      expect(importedItems.single.id, item.id);
      expect(importedItems.single.name, item.name);
      expect(importedItems.single.category, item.category);
      expect(importedItems.single.location, item.location);
      expect(await storage.readString('items'), rawItems);
      expect(await storage.readString('backup_v1_items'), rawItems);
      final schedule = Schedule(
        id: 'schedule-1',
        itemId: item.id,
        cardId: 'manual-expiry-reminder',
        cycleType: CycleType.custom,
        interval: 1,
        startDate: DateTime.utc(2026, 1, 2),
        nextDueDate: DateTime.utc(2027, 1, 2),
        title: '保固到期',
      );
      await root.scheduleRepository.saveSchedules([schedule]);
      expect(
        (await root.scheduleRepository.loadSchedules()).single.id,
        schedule.id,
      );
      expect(await storage.readString('schedules'), isNull);
      expect(await storage.readString('backup_v1_schedules'), isNull);
      expect(
        await root.generalReminderRepository?.findById(
          'runtime-reminder-${schedule.id}',
        ),
        isNotNull,
      );
      await root.taskRepository.saveGeneratedTasks([
        Task(
          id: 'task-1',
          itemId: item.id,
          cardId: schedule.cardId,
          scheduleId: schedule.id,
          title: schedule.title!,
          dueDate: schedule.nextDueDate,
        ),
      ]);
      expect((await root.taskRepository.loadTasks()).single.id, 'task-1');
      expect(await storage.readString('tasks'), isNull);
      final caseTime = DateTime.utc(2027, 1, 3);
      await root.workCaseRuntime!.createManual(
        WorkCase(
          id: 'case-1',
          itemId: item.id,
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.administrative,
          title: '處理保固文件',
          status: WorkCaseStatus.inProgress,
          createdAt: caseTime,
          updatedAt: caseTime,
        ),
      );
      await expectLater(
        storage.saveString('items', '[]'),
        throwsA(isA<LegacyStorageReadOnlyException>()),
      );
      await expectLater(
        storage.remove('items'),
        throwsA(isA<LegacyStorageReadOnlyException>()),
      );

      final restartedStorage = LocalStorageService();
      final restartedRoot = AppCompositionRoot(
        database: database,
        legacyStorage: restartedStorage,
      );
      final restarted = await restartedRoot.initialize();
      expect(restarted.mode, RuntimeDataMode.driftHistoryAttachments);
      expect(
        restarted.importReport?.status,
        LegacyDriftImportStatus.alreadyImported,
      );
      expect(
        (await restartedRoot.itemReadRepository.loadItems()).single.id,
        item.id,
      );
      expect(
        (await restartedRoot.taskRepository.loadTasks()).single.id,
        'task-1',
      );
      expect(
        (await restartedRoot.workCaseRuntime!.findCaseById('case-1'))?.title,
        '處理保固文件',
      );
      expect(await restartedStorage.readString('items'), rawItems);

      await database.close();
    },
  );

  test(
    'blocked startup rolls back and keeps legacy runtime writable',
    () async {
      final item = Item(
        id: 'item-1',
        name: '家中汽車',
        category: ItemCategory.vehicle,
        createdAt: DateTime.utc(2026, 2, 3),
      );
      final rawItems = jsonEncode([item.toJson()]);
      SharedPreferences.setMockInitialValues({
        'items': rawItems,
        'backup_v1_items': '[]',
      });
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );

      final result = await root.initialize();

      expect(result.mode, RuntimeDataMode.legacy);
      expect(root.workCaseRuntime, isNull);
      expect(root.historyProjectionRepository, isNull);
      expect(root.attachmentRuntime, isNull);
      expect(result.importReport?.status, LegacyDriftImportStatus.blocked);
      expect(root.legacyWritesEnabled, isTrue);
      expect((await root.itemReadRepository.loadItems()).single.id, item.id);
      expect(await root.driftRepositories.items.listAll(), isEmpty);
      await storage.saveString('items', rawItems);
      expect(await storage.readString('backup_v1_items'), '[]');

      await database.close();
    },
  );
}
