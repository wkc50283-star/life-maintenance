import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:life_maintenance/screens/settings_screen.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.resetStatic();
    SharedPreferences.setMockInitialValues({
      'items': '[]',
      'maintenance_records': '[]',
      'schedules': '[]',
      'tasks': '[]',
    });
    LocalDataIntegrityService.instance.resetForTesting();
  });

  testWidgets('items screen does not show inactive category filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ItemsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsNothing);
    expect(find.text('保固證件'), findsNothing);
  });

  testWidgets('history screen does not show inactive category filters', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('全部'), findsNothing);
    expect(find.text('到期提醒'), findsNothing);
  });

  testWidgets('settings only shows available information', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    expect(find.text('預設提醒時間'), findsNothing);
    expect(find.text('匯出資料'), findsNothing);
    expect(find.text('安全界線'), findsOneWidget);
    expect(find.text('版本資訊'), findsNothing);
    expect(find.text('v0.14.0'), findsNothing);
  });

  testWidgets('history detail hides internal identifiers', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final createdAt = DateTime.utc(2026, 7, 1);
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
        name: '冷氣',
        categoryId: 'category-1',
        status: 'active',
        createdAt: createdAt,
        updatedAt: createdAt,
      ),
    );
    final record = MaintenanceRecord(
      id: 'record-1',
      itemId: 'item-1',
      recordType: RecordType.repair,
      date: DateTime(2026, 7, 2),
      title: '冷氣維修',
      workDescription: '更換零件並測試',
      result: '正常運作',
      createdAt: DateTime(2026, 7, 2),
    );
    await root.maintenanceRecordRepository.createSimpleRecord(record);

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('冷氣維修').first);
    await tester.pumpAndSettle();

    expect(find.text('紀錄 ID'), findsNothing);
    expect(find.text('生活項目 ID'), findsNothing);
    expect(find.text('任務 ID'), findsNothing);
    expect(find.text('處理內容'), findsOneWidget);
  });
}
