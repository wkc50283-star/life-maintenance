import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:life_maintenance/main.dart';

void main() {
  testWidgets('LifeMaintenanceApp shows bottom navigation tabs', (
    tester,
  ) async {
    await tester.pumpWidget(const LifeMaintenanceApp());

    expect(find.text('今日'), findsWidgets);
    expect(find.text('物品'), findsOneWidget);
    expect(find.text('履歷'), findsOneWidget);
    expect(find.text('設定'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
  });
}
