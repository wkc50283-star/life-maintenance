import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
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
}

Widget _historyApp(AppCompositionRoot root) => AppCompositionScope(
  root: root,
  child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
);
