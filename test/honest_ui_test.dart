import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
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
    expect(find.text('版本資訊'), findsOneWidget);
    expect(find.text('v0.14.0'), findsOneWidget);
  });

  testWidgets('history detail hides internal identifiers', (tester) async {
    final item = Item(
      id: 'item-1',
      name: '冷氣',
      category: ItemCategory.appliance,
      createdAt: DateTime(2026, 7, 1),
    );
    final record = MaintenanceRecord(
      id: 'record-1',
      itemId: item.id,
      taskId: 'task-1',
      recordType: RecordType.repair,
      date: DateTime(2026, 7, 2),
      title: '冷氣維修',
      workDescription: '更換零件並測試',
      result: '正常運作',
      createdAt: DateTime(2026, 7, 2),
    );
    SharedPreferences.setMockInitialValues({
      'items': jsonEncode([item.toJson()]),
      'maintenance_records': jsonEncode([record.toJson()]),
      'schedules': '[]',
      'tasks': '[]',
    });

    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: HistoryScreen())),
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
