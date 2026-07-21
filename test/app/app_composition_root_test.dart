import 'package:drift/drift.dart' show LazyDatabase;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(SharedPreferences.resetStatic);

  test(
    'initialization opens the formal database before screens load',
    () async {
      var openCount = 0;
      final database = AppDatabase(
        LazyDatabase(() async {
          openCount++;
          return NativeDatabase.memory();
        }),
      );
      final root = AppCompositionRoot(database: database);

      expect(openCount, 0);
      await root.initialize();
      expect(openCount, 1);

      await database.close();
    },
  );

  test(
    'constructs one database and the complete formal Drift runtime',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);

      expect(root.database, same(database));
      expect(root.driftRepositories.items, isNotNull);
      expect(root.driftRepositories.tasks, isNotNull);
      expect(root.driftRepositories.workCases, isNotNull);
      expect(root.driftRepositories.workCaseClosures, isNotNull);
      expect(root.itemReadRepository, isNotNull);
      expect(root.maintenanceRecordRepository, isNotNull);
      expect(root.workCaseRuntime, isNotNull);
      expect(root.taskReminderRuntime, isNotNull);
      expect(root.historyProjectionRepository, isNotNull);
      expect(root.attachmentRuntime, isNotNull);
      expect(root.maintenanceTaskService, isNotNull);
      expect(root.usesDriftPlanning, isTrue);
      expect(root.formalWritesEnabled, isTrue);

      final initialized = await root.initialize();
      expect(initialized.mode, RuntimeDataMode.driftMaintenanceRecords);
      expect(initialized.usesDriftItemRead, isTrue);
      expect(initialized.usesDriftPlanning, isTrue);
      expect(initialized.usesDriftTasks, isTrue);
      expect(initialized.usesDriftWorkCases, isTrue);
      expect(initialized.usesDriftHistoryAttachments, isTrue);
      expect(initialized.usesDriftMaintenanceRecords, isTrue);
      await database.close();
    },
  );

  testWidgets('scope exposes the injected root', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
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
    'cold start uses Drift only and never reads legacy business data',
    () async {
      SharedPreferences.setMockInitialValues({
        'items': '{malformed-legacy-data',
        'backup_v1_items': 'immutable-backup',
      });
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);
      await _seedItem(root);

      final first = await root.initialize();

      expect(first.mode, RuntimeDataMode.driftMaintenanceRecords);
      expect((await root.itemReadRepository.loadItems()).single.id, 'item-1');
      final preferences = await SharedPreferences.getInstance();
      expect(preferences.getString('items'), '{malformed-legacy-data');
      expect(preferences.getString('backup_v1_items'), 'immutable-backup');

      final schedule = Schedule(
        id: 'schedule-1',
        itemId: 'item-1',
        cardId: 'manual-expiry-reminder',
        cycleType: CycleType.custom,
        interval: 1,
        startDate: DateTime.utc(2026, 1, 2),
        nextDueDate: DateTime.utc(2027, 1, 2),
        title: '保固到期',
      );
      await root.scheduleRepository.saveSchedules([schedule]);
      await root.taskRepository.saveGeneratedTasks([
        Task(
          id: 'task-1',
          itemId: 'item-1',
          cardId: schedule.cardId,
          scheduleId: schedule.id,
          title: schedule.title!,
          dueDate: schedule.nextDueDate,
        ),
      ]);
      final caseTime = DateTime.utc(2027, 1, 3);
      await root.workCaseRuntime.createManual(
        WorkCase(
          id: 'case-1',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.administrative,
          title: '處理保固文件',
          status: WorkCaseStatus.inProgress,
          createdAt: caseTime,
          updatedAt: caseTime,
        ),
      );

      final restarted = AppCompositionRoot(database: database);
      await restarted.initialize();
      expect(
        (await restarted.itemReadRepository.loadItems()).single.id,
        'item-1',
      );
      expect((await restarted.taskRepository.loadTasks()).single.id, 'task-1');
      expect(
        (await restarted.workCaseRuntime.findCaseById('case-1'))?.title,
        '處理保固文件',
      );
      expect(preferences.getString('items'), '{malformed-legacy-data');
      expect(preferences.getString('backup_v1_items'), 'immutable-backup');
      await database.close();
    },
  );
}

Future<void> _seedItem(AppCompositionRoot root) async {
  final createdAt = DateTime.utc(2026, 1, 2);
  await root.driftRepositories.itemCategories.save(
    ItemCategoryRow(
      id: 'category-1',
      systemCode: 'homeAndAppliance',
      displayName: '家電與居家設備',
      sortOrder: 0,
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
  await root.driftRepositories.items.save(
    ItemRow(
      id: 'item-1',
      name: '客廳冷氣',
      categoryId: 'category-1',
      location: '客廳',
      status: 'active',
      createdAt: createdAt,
      updatedAt: createdAt,
    ),
  );
}
