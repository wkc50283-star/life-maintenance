import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/drift/drift_task_runtime_repository.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftTaskRuntimeRepository runtimeRepository;
  final now = DateTime.utc(2026, 7, 19, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    runtimeRepository = DriftTaskRuntimeRepository(
      database: database,
      repositories: repositories,
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
    await repositories.items.save(
      ItemRow(
        id: 'item-1',
        name: '房屋租約',
        categoryId: 'category-1',
        createdAt: now,
        updatedAt: now,
        status: 'active',
      ),
    );
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
        legacyCardId: 'manual-expiry-reminder',
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
  });

  tearDown(() => database.close());

  Task task({String id = 'task-1', String scheduleId = 'schedule-1'}) => Task(
    id: id,
    itemId: 'item-1',
    cardId: 'manual-expiry-reminder',
    scheduleId: scheduleId,
    title: '租約續約',
    dueDate: now,
  );

  test('generates a reminder Task from the formal Schedule source', () async {
    await runtimeRepository.saveGeneratedTasks([task()]);

    final row = await repositories.tasks.findById('task-1');
    expect(row?.sourceType, 'scheduledReminder');
    expect(row?.generalReminderId, 'reminder-1');
    expect(row?.scheduleId, 'schedule-1');
    expect((await runtimeRepository.loadTasks()).single.id, 'task-1');
  });

  test('same scheduleId and dueDate is idempotent', () async {
    await runtimeRepository.saveGeneratedTasks([task()]);
    await runtimeRepository.saveGeneratedTasks([task(id: 'task-duplicate')]);

    expect(await repositories.tasks.listAll(), hasLength(1));
    expect((await repositories.tasks.listAll()).single.id, 'task-1');
  });

  test('generation transaction rolls back when a source is invalid', () async {
    await expectLater(
      runtimeRepository.saveGeneratedTasks([
        task(),
        task(id: 'task-invalid', scheduleId: 'missing-schedule'),
      ]),
      throwsA(isA<RepositoryConstraintException>()),
    );

    expect(await repositories.tasks.listAll(), isEmpty);
  });

  test(
    'rejects duplicate composite keys inside one generation batch',
    () async {
      await expectLater(
        runtimeRepository.saveGeneratedTasks([task(), task(id: 'task-2')]),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(await repositories.tasks.listAll(), isEmpty);
    },
  );
}
