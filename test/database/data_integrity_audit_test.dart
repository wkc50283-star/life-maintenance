import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case_enums.dart';

void main() {
  test('foreign keys and formal uniqueness constraints remain enabled', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);

    final foreignKeys = await database
        .customSelect('PRAGMA foreign_keys')
        .get();
    expect(foreignKeys.single.data.values.single, 1);

    final expectedForeignKeys = <String>{
      'items.category_id->item_categories.id:RESTRICT',
      'maintenance_plans.item_id->items.id:RESTRICT',
      'maintenance_plan_steps.maintenance_plan_id->maintenance_plans.id:RESTRICT',
      'general_reminders.item_id->items.id:RESTRICT',
      'milestones.item_id->items.id:RESTRICT',
      'milestones.source_plan_id->maintenance_plans.id:RESTRICT',
      'milestones.dependency_milestone_id->milestones.id:RESTRICT',
      'milestones.work_case_id->work_cases.id:RESTRICT',
      'schedules.item_id->items.id:RESTRICT',
      'schedules.maintenance_plan_id->maintenance_plans.id:RESTRICT',
      'schedules.general_reminder_id->general_reminders.id:RESTRICT',
      'schedules.milestone_id->milestones.id:RESTRICT',
      'tasks.item_id->items.id:RESTRICT',
      'tasks.schedule_id->schedules.id:RESTRICT',
      'tasks.maintenance_plan_id->maintenance_plans.id:RESTRICT',
      'tasks.general_reminder_id->general_reminders.id:RESTRICT',
      'tasks.milestone_id->milestones.id:RESTRICT',
      'maintenance_records.item_id->items.id:RESTRICT',
      'maintenance_records.task_id->tasks.id:RESTRICT',
      'maintenance_records.maintenance_plan_id->maintenance_plans.id:RESTRICT',
      'work_cases.item_id->items.id:RESTRICT',
      'work_case_updates.work_case_id->work_cases.id:RESTRICT',
      'work_case_closures.work_case_id->work_cases.id:RESTRICT',
      'work_case_closures.next_schedule_id->schedules.id:RESTRICT',
      'work_case_closures.next_reminder_task_id->tasks.id:RESTRICT',
    };
    final actualForeignKeys = <String>{};
    for (final table in <String>{
      for (final relation in expectedForeignKeys) relation.split('.').first,
    }) {
      final rows = await database
          .customSelect('PRAGMA foreign_key_list($table)')
          .get();
      for (final row in rows) {
        actualForeignKeys.add(
          '$table.${row.read<String>('from')}->'
          '${row.read<String>('table')}.${row.read<String>('to')}:'
          '${row.read<String>('on_delete')}',
        );
      }
    }
    expect(actualForeignKeys, expectedForeignKeys);

    for (final entry in <String, String>{
      'maintenance_plan_steps': 'maintenance_plan_steps_plan_order_idx',
      'tasks': 'tasks_schedule_due_unique_idx',
      'work_case_closures': 'work_case_closures_case_unique_idx',
    }.entries) {
      final indexes = await database
          .customSelect('PRAGMA index_list(${entry.key})')
          .get();
      final index = indexes.singleWhere(
        (row) => row.read<String>('name') == entry.value,
      );
      expect(index.read<int>('unique'), 1, reason: entry.value);
    }

    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
    final integrity = await database
        .customSelect('PRAGMA integrity_check')
        .get();
    expect(integrity.single.data.values.single, 'ok');
  });

  test(
    'commits survive restart and failed transactions remain rolled back',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-management-data-integrity-',
      );
      final file = File('${directory.path}/audit.sqlite');
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });
      final now = DateTime.utc(2026, 7, 20);

      var database = AppDatabase(NativeDatabase(file));
      await database
          .into(database.itemCategories)
          .insert(
            ItemCategoriesCompanion.insert(
              id: 'category-1',
              systemCode: const Value('other'),
              displayName: '其他',
              status: 'active',
              createdAt: now,
              updatedAt: now,
            ),
          );
      await database
          .into(database.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item-1',
              name: '資料完整性項目',
              categoryId: 'category-1',
              createdAt: now,
              updatedAt: now,
              status: 'active',
            ),
          );
      await database.transaction(() async {
        await database
            .into(database.workCases)
            .insert(
              WorkCasesCompanion.insert(
                id: 'committed-case',
                itemId: 'item-1',
                sourceType: WorkCaseSourceType.manual,
                caseType: WorkCaseType.other,
                title: '已承接案件',
                status: WorkCaseStatus.inProgress,
                createdAt: now,
                updatedAt: now,
              ),
            );
      });
      await expectLater(
        database.transaction(() async {
          await database
              .into(database.workCases)
              .insert(
                WorkCasesCompanion.insert(
                  id: 'rolled-back-case',
                  itemId: 'item-1',
                  sourceType: WorkCaseSourceType.manual,
                  caseType: WorkCaseType.other,
                  title: '不得殘留案件',
                  status: WorkCaseStatus.inProgress,
                  createdAt: now,
                  updatedAt: now,
                ),
              );
          await database
              .into(database.workCaseUpdates)
              .insert(
                WorkCaseUpdatesCompanion.insert(
                  id: 'rolled-back-update',
                  workCaseId: 'rolled-back-case',
                  occurredAt: now,
                  description: '不得殘留進度',
                  createdAt: now,
                ),
              );
          throw StateError('Simulated interruption.');
        }),
        throwsStateError,
      );
      await database.close();

      database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
      final cases = await database.select(database.workCases).get();
      expect(cases.map((row) => row.id), ['committed-case']);
      expect(await database.select(database.workCaseUpdates).get(), isEmpty);
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      final integrity = await database
          .customSelect('PRAGMA integrity_check')
          .get();
      expect(integrity.single.data.values.single, 'ok');
    },
  );
}
