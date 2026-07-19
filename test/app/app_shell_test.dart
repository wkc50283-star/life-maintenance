import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_shell.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/screens/add_screen.dart';
import 'package:life_maintenance/screens/history_screen.dart';
import 'package:life_maintenance/screens/items_screen.dart';
import 'package:life_maintenance/screens/settings_screen.dart';
import 'package:life_maintenance/screens/today_screen.dart';

void main() {
  testWidgets('uses one composition root and the shared application theme', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    final shellContext = tester.element(find.byType(AppShell));
    final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));

    expect(AppCompositionScope.of(shellContext), same(root));
    expect(materialApp.title, '生活管理');
    expect(Theme.of(shellContext).useMaterial3, isTrue);
    expect(
      Theme.of(shellContext).scaffoldBackgroundColor,
      const Color(0xFFF7F3EA),
    );
    expect(Theme.of(shellContext).colorScheme.primary, const Color(0xFF5D7893));
    await root.database.close();
  });

  testWidgets('exposes the five formal destinations without parallel routes', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    final navigation = tester.widget<NavigationBar>(
      find.byKey(const ValueKey('primary-navigation')),
    );
    expect(
      navigation.destinations.cast<NavigationDestination>().map(
        (destination) => destination.label,
      ),
      const ['生活總覽', '生活項目', '新增', '史略', '設定'],
    );
    expect(find.byType(TodayScreen), findsOneWidget);

    await tester.tap(find.text('生活項目'));
    await tester.pumpAndSettle();
    expect(find.byType(ItemsScreen), findsOneWidget);

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    expect(find.byType(AddScreen), findsOneWidget);

    await tester.tap(find.text('史略'));
    await tester.pumpAndSettle();
    expect(find.byType(HistoryScreen), findsOneWidget);

    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();
    expect(find.byType(SettingsScreen), findsOneWidget);
    await root.database.close();
  });
}
