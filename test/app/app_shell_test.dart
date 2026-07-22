import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_shell.dart';
import 'package:life_maintenance/app/ui_tokens.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/repositories/item_read_repository.dart';
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
    expect(Theme.of(shellContext).scaffoldBackgroundColor, UiColors.canvas);
    expect(Theme.of(shellContext).colorScheme.primary, UiColors.primary);
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

  testWidgets('small phone and large text render every shell page safely', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    tester.platformDispatcher.textScaleFactorTestValue = 1.3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    for (final label in const ['生活項目', '新增', '史略', '設定', '生活總覽']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
    await root.database.close();
  });

  testWidgets('runtime initialization failure has an honest retry state', (
    tester,
  ) async {
    final root = _RetryableInitializationRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(find.text('暫時無法開啟生活資料。'), findsOneWidget);
    await tester.tap(find.text('重新開啟'));
    await tester.pumpAndSettle();
    expect(find.byType(TodayScreen), findsOneWidget);
    await root.database.close();
  });

  testWidgets('overview and History expose read failure states', (
    tester,
  ) async {
    final root = _ReadFailureRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    expect(find.text('暫時無法讀取生活總覽。'), findsOneWidget);

    await tester.tap(find.text('史略'));
    await tester.pumpAndSettle();
    expect(find.text('暫時無法讀取史略。'), findsOneWidget);
    await root.database.close();
  });
}

class _RetryableInitializationRoot extends AppCompositionRoot {
  _RetryableInitializationRoot({required super.database});

  int attempts = 0;

  @override
  Future<RuntimeInitializationResult> initialize() async {
    attempts += 1;
    if (attempts == 1) throw StateError('test initialization failure');
    return super.initialize();
  }
}

class _ReadFailureRoot extends AppCompositionRoot {
  _ReadFailureRoot({required super.database});

  final ItemReadRepository _failingItems = _FailingItemReadRepository();

  @override
  ItemReadRepository get itemReadRepository => _failingItems;
}

class _FailingItemReadRepository implements ItemReadRepository {
  @override
  Future<List<Item>> loadItems() => Future.error(StateError('read failed'));
}
