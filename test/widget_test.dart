import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';

void main() {
  testWidgets('LifeMaintenanceApp shows the formal app shell', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(find.text('生活總覽'), findsWidgets);
    expect(find.text('生活項目'), findsOneWidget);
    expect(find.text('新增'), findsOneWidget);
    expect(find.text('史略'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('管理生活項目、提醒與處理紀錄'), findsOneWidget);
    expect(find.text('軍規邏輯，民用保養'), findsNothing);
    expect(find.text('v0.14.0'), findsNothing);
    expect(find.text('v0.9.0'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
    await root.database.close();
  });
}
