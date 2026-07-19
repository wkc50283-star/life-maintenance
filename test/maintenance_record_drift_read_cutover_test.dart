import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:life_maintenance/services/legacy_drift_import_service.dart';
import 'package:life_maintenance/services/local_data_backup_service.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    LocalDataIntegrityService.instance.resetForTesting();
    SharedPreferences.resetStatic();
  });

  testWidgets('Items and History read a Drift-only MaintenanceRecord', (
    tester,
  ) async {
    final item = Item(
      id: 'item-1',
      name: '客廳冷氣',
      category: ItemCategory.appliance,
      createdAt: DateTime.utc(2026, 1, 2),
    );
    final rawItems = jsonEncode([item.toJson()]);
    SharedPreferences.setMockInitialValues({
      'items': rawItems,
      'maintenance_records': '[]',
    });
    final database = AppDatabase(NativeDatabase.memory());
    final storage = LocalStorageService();
    await LocalDataBackupService(storage).createPreMigrationBackups();
    await LegacyDriftImportService(
      database: database,
      source: SharedPreferencesLegacyImportSource(storage),
    ).execute(sourceWritesAreDisabled: true);
    final root = AppCompositionRoot(database: database);
    await root.initialize();
    final completedAt = DateTime.utc(2026, 7, 19, 12);
    await root.maintenanceRecordRepository.createSimpleRecord(
      MaintenanceRecord(
        id: 'drift-only-record',
        itemId: item.id,
        recordType: RecordType.regularMaintenance,
        date: completedAt,
        title: 'Drift 完成紀錄',
        workDescription: '只存在正式資料庫',
        createdAt: completedAt,
      ),
    );
    expect(await storage.readString('maintenance_records'), '[]');

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: HistoryScreen())),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Drift 完成紀錄'), findsOneWidget);

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: const MaterialApp(home: Scaffold(body: ItemsScreen())),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('客廳冷氣'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Drift 完成紀錄'),
      400,
      scrollable: find.byType(Scrollable),
    );
    expect(find.text('Drift 完成紀錄'), findsOneWidget);

    await database.close();
  });
}
