import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/screens/today_screen.dart';

const _itemCount = 80;
const _factsPerItem = 5;
const _taskCount = _itemCount * _factsPerItem;
const _recordCount = _itemCount * _factsPerItem;
const _attachmentCount = _recordCount * 2;
const _queryBudget = Duration(seconds: 3);
const _screenBudget = Duration(seconds: 8);
const _memoryBudgetBytes = 384 * 1024 * 1024;

void main() {
  test('large formal reads stay indexed and within the query budget', () async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    await _seedLargeDataset(database);

    await _expectIndexed(
      database,
      'SELECT * FROM tasks WHERE item_id = ? AND status = ?',
      ['item-0', 'pending'],
      'tasks_item_status_idx',
    );
    await _expectIndexed(
      database,
      'SELECT * FROM maintenance_records WHERE item_id = ? ORDER BY date',
      ['item-0'],
      'maintenance_records_item_date_idx',
    );
    await _expectIndexed(
      database,
      'SELECT * FROM attachments WHERE owner_type = ? AND owner_id = ?',
      ['maintenanceRecord', 'record-0-0'],
      'attachments_owner_status_idx',
    );
    await _expectIndexed(
      database,
      'SELECT * FROM work_cases WHERE item_id = ? AND status = ?',
      ['item-0', 'inProgress'],
      'work_cases_item_status_idx',
    );

    final stopwatch = Stopwatch()..start();
    final items = await root.itemReadRepository.loadItems();
    final tasks = await root.taskRepository.loadTasks();
    final history = await root.historyProjectionRepository.projectForItem(
      'item-0',
    );
    final attachments = await root.attachmentRuntime.listForOwner(
      AttachmentOwnerType.maintenanceRecord,
      'record-0-0',
    );
    final allAttachmentRows = await database.select(database.attachments).get();
    stopwatch.stop();

    expect(items, hasLength(_itemCount));
    expect(tasks, hasLength(_taskCount));
    expect(history.entries, hasLength(_factsPerItem));
    expect(attachments, hasLength(2));
    expect(allAttachmentRows, hasLength(_attachmentCount));
    expect(
      stopwatch.elapsed,
      lessThan(_queryBudget),
      reason: 'Large indexed reads exceeded the formal query budget.',
    );
  });

  testWidgets(
    'large overview loads and scrolls within time and memory budgets',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(430, 900);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(database: database);
      addTearDown(database.close);
      await _seedLargeDataset(database);
      final memoryBefore = ProcessInfo.currentRss;
      final stopwatch = Stopwatch()..start();

      await tester.pumpWidget(
        AppCompositionScope(
          root: root,
          child: const MaterialApp(home: Scaffold(body: TodayScreen())),
        ),
      );
      await tester.pumpAndSettle();
      stopwatch.stop();
      final memoryGrowth = ProcessInfo.currentRss - memoryBefore;

      expect(find.text('今日提醒 $_taskCount'), findsOneWidget);
      expect(stopwatch.elapsed, lessThan(_screenBudget));
      expect(memoryGrowth, lessThan(_memoryBudgetBytes));
      for (var index = 0; index < 5; index++) {
        await tester.drag(find.byType(ListView), const Offset(0, -700));
        await tester.pump();
      }
      expect(tester.takeException(), null);
    },
  );

  testWidgets('large History list loads and scrolls within the screen budget', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(430, 900);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    addTearDown(database.close);
    await _seedLargeDataset(database);
    final stopwatch = Stopwatch()..start();

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();
    stopwatch.stop();

    expect(stopwatch.elapsed, lessThan(_screenBudget));
    expect(find.text('處理紀錄 0-0'), findsOneWidget);
    for (var index = 0; index < 5; index++) {
      await tester.drag(find.byType(ListView), const Offset(0, -700));
      await tester.pump();
    }
    expect(tester.takeException(), null);
  });
}

Future<void> _expectIndexed(
  AppDatabase database,
  String sql,
  List<Object> variables,
  String indexName,
) async {
  final plan = await database
      .customSelect(
        'EXPLAIN QUERY PLAN $sql',
        variables: [for (final value in variables) Variable(value)],
      )
      .get();
  final details = plan.map((row) => row.data.values.join(' ')).join('\n');
  expect(details, contains(indexName), reason: details);
}

Future<void> _seedLargeDataset(AppDatabase database) async {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day, 9);
  await database.batch((batch) {
    batch.insert(
      database.itemCategories,
      ItemCategoriesCompanion.insert(
        id: 'category-performance',
        systemCode: const Value('other'),
        displayName: '大量資料測試',
        status: 'active',
        createdAt: today,
        updatedAt: today,
      ),
    );
    for (var itemIndex = 0; itemIndex < _itemCount; itemIndex++) {
      final itemId = 'item-$itemIndex';
      batch.insert(
        database.items,
        ItemsCompanion.insert(
          id: itemId,
          name: '生活項目 $itemIndex',
          categoryId: 'category-performance',
          createdAt: today,
          updatedAt: today,
          status: 'active',
        ),
      );
      for (var factIndex = 0; factIndex < _factsPerItem; factIndex++) {
        final recordId = 'record-$itemIndex-$factIndex';
        batch.insert(
          database.tasks,
          TasksCompanion.insert(
            id: 'task-$itemIndex-$factIndex',
            itemId: itemId,
            sourceType: 'manual',
            title: '今日提醒 $itemIndex-$factIndex',
            dueDate: today,
            status: 'pending',
            createdAt: today,
            updatedAt: today,
          ),
        );
        batch.insert(
          database.maintenanceRecords,
          MaintenanceRecordsCompanion.insert(
            id: recordId,
            itemId: itemId,
            recordType: 'other',
            date: today.subtract(Duration(days: factIndex)),
            title: '處理紀錄 $itemIndex-$factIndex',
            createdAt: today,
          ),
        );
        for (var attachmentIndex = 0; attachmentIndex < 2; attachmentIndex++) {
          batch.insert(
            database.attachments,
            AttachmentsCompanion.insert(
              id: 'attachment-$itemIndex-$factIndex-$attachmentIndex',
              ownerType: 'maintenanceRecord',
              ownerId: recordId,
              kind: 'document',
              storageIdentifier:
                  'managed/performance-$itemIndex-$factIndex-$attachmentIndex',
              mimeType: const Value('application/octet-stream'),
              byteSize: const Value(1024),
              createdAt: today,
            ),
          );
        }
      }
    }
  });
}
