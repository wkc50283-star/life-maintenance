import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:life_maintenance/main.dart';

void main() {
  testWidgets('LifeMaintenanceApp shows bottom navigation tabs', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});

    await tester.pumpWidget(const LifeMaintenanceApp());
    await tester.pumpAndSettle();

    expect(find.text('今日'), findsWidgets);
    expect(find.text('我的項目'), findsWidgets);
    expect(find.text('履歷'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.text('管理生活項目、提醒與處理紀錄'), findsOneWidget);
    expect(find.text('軍規邏輯，民用保養'), findsNothing);
    expect(find.text('v0.14.0'), findsNothing);
    expect(find.text('v0.9.0'), findsNothing);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
