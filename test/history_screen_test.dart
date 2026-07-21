import 'dart:async';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/repositories/history_projection_repository.dart';
import 'package:life_maintenance/repositories/item_read_repository.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/widgets/empty_history_state.dart';

void main() {
  testWidgets('history screen shows empty state without mock records', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(_historyApp(root));
    await tester.pumpAndSettle();

    expect(find.text('目前還沒有履歷紀錄。'), findsOneWidget);
    expect(find.text('建立冷氣濾網清洗提醒'), findsNothing);
    expect(find.text('建立機車胎壓檢查提醒'), findsNothing);
    expect(find.text('建立租屋合約到期提醒'), findsNothing);
  });

  testWidgets('history projection shows a formal maintenance record', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final createdAt = DateTime.utc(2026, 7, 10);
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
        name: '客廳冷氣',
        categoryId: 'category-1',
        status: 'active',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    await root.maintenanceRecordRepository.createSimpleRecord(
      MaintenanceRecord(
        id: 'record-1',
        itemId: 'item-1',
        recordType: RecordType.regularMaintenance,
        date: createdAt,
        title: '濾網清潔紀錄',
        workDescription: '完成濾網清洗與晾乾',
        result: '運轉正常',
        createdAt: createdAt,
      ),
    );

    await tester.pumpWidget(_historyApp(root));
    await tester.pumpAndSettle();

    expect(find.text('2026 年 7 月'), findsOneWidget);
    expect(find.text('濾網清潔紀錄'), findsOneWidget);
    expect(find.text('客廳冷氣'), findsOneWidget);
    expect(find.text('完成濾網清洗與晾乾'), findsOneWidget);
    expect(find.text('運轉正常'), findsOneWidget);

    await tester.tap(find.text('濾網清潔紀錄'));
    await tester.pumpAndSettle();
    expect(find.text('紀錄 ID'), findsNothing);
    expect(find.text('record-1'), findsNothing);
  });

  testWidgets('empty history state remains renderable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: EmptyHistoryState())),
    );

    expect(find.text('目前還沒有履歷紀錄。'), findsOneWidget);
  });

  testWidgets('history keeps loading distinct from an empty projection', (
    tester,
  ) async {
    final pendingItems = Completer<List<Item>>();
    final root = _HistoryTestRoot(
      database: AppDatabase(NativeDatabase.memory()),
      items: _DeferredItemRepository(pendingItems.future),
      history: const _StaticHistoryRepository(<String, HistoryProjection>{}),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(_historyApp(root));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('目前還沒有履歷紀錄。'), findsNothing);

    pendingItems.complete(const <Item>[]);
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('目前還沒有履歷紀錄。'), findsOneWidget);
  });

  testWidgets('history retries a failed read and restores the projection', (
    tester,
  ) async {
    final occurredAt = DateTime.utc(2026, 7, 20, 9);
    final item = Item(
      id: 'item-1',
      name: '家庭文件',
      category: ItemCategory.warrantyDocument,
      createdAt: occurredAt,
    );
    final projection = HistoryProjection(
      itemId: item.id,
      entries: [
        TaskHistoryEntry(
          HistoryTaskSnapshot(
            id: 'task-1',
            itemId: item.id,
            sourceType: 'manual',
            title: '護照換發提醒',
            dueDate: occurredAt,
            status: 'completed',
            completedAt: occurredAt,
            createdAt: occurredAt,
            updatedAt: occurredAt,
          ),
        ),
      ],
      itemAttachments: const [],
    );
    final history = _RetryHistoryRepository(projection);
    final root = _HistoryTestRoot(
      database: AppDatabase(NativeDatabase.memory()),
      items: _StaticItemRepository([item]),
      history: history,
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(_historyApp(root));
    await tester.pumpAndSettle();

    expect(find.text('暫時無法讀取史略。'), findsOneWidget);
    expect(find.text('護照換發提醒'), findsNothing);

    await tester.tap(find.text('重新讀取'));
    await tester.pumpAndSettle();

    expect(history.attempts, 2);
    expect(find.text('暫時無法讀取史略。'), findsNothing);
    expect(find.text('護照換發提醒'), findsOneWidget);
    expect(find.text('家庭文件'), findsOneWidget);
  });
}

Widget _historyApp(AppCompositionRoot root) => AppCompositionScope(
  root: root,
  child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
);

class _HistoryTestRoot extends AppCompositionRoot {
  _HistoryTestRoot({
    required super.database,
    required ItemReadRepository items,
    required HistoryProjectionRepository history,
  }) : _items = items,
       _history = history;

  final ItemReadRepository _items;
  final HistoryProjectionRepository _history;

  @override
  ItemReadRepository get itemReadRepository => _items;

  @override
  HistoryProjectionRepository get historyProjectionRepository => _history;
}

class _DeferredItemRepository implements ItemReadRepository {
  const _DeferredItemRepository(this.items);

  final Future<List<Item>> items;

  @override
  Future<List<Item>> loadItems() => items;
}

class _StaticItemRepository implements ItemReadRepository {
  const _StaticItemRepository(this.items);

  final List<Item> items;

  @override
  Future<List<Item>> loadItems() async => items;
}

class _StaticHistoryRepository implements HistoryProjectionRepository {
  const _StaticHistoryRepository(this.projections);

  final Map<String, HistoryProjection> projections;

  @override
  Future<HistoryProjection> projectForItem(String itemId) async =>
      projections[itemId] ??
      HistoryProjection(
        itemId: itemId,
        entries: const [],
        itemAttachments: const [],
      );
}

class _RetryHistoryRepository implements HistoryProjectionRepository {
  _RetryHistoryRepository(this.projection);

  final HistoryProjection projection;
  int attempts = 0;

  @override
  Future<HistoryProjection> projectForItem(String itemId) async {
    attempts += 1;
    if (attempts == 1) {
      throw StateError('simulated History read failure');
    }
    return projection;
  }
}
