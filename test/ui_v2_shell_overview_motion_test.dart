import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_shell.dart';
import 'package:life_maintenance/app/ui_tokens.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/screens/add_screen.dart';
import 'package:life_maintenance/widgets/ui_v2_components.dart';

void main() {
  testWidgets(
    'Shell keeps five destinations and home quick add uses Add entry',
    (tester) async {
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);

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
      expect(find.byKey(const ValueKey('overview-quick-add')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('overview-quick-add')));
      await tester.pumpAndSettle();

      expect(navigation.selectedIndex, 0);
      expect(find.byType(AddScreen), findsOneWidget);
      expect(
        tester
            .widget<NavigationBar>(
              find.byKey(const ValueKey('primary-navigation')),
            )
            .selectedIndex,
        2,
      );
    },
  );

  testWidgets(
    'tab and overview entrance motion stay within first-stage timing',
    (tester) async {
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);

      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();

      final switcher = tester.widget<AnimatedSwitcher>(
        find.byKey(const ValueKey('shell-tab-transition')),
      );
      expect(switcher.duration, UiMotion.standard);
      expect(UiMotion.quick.inMilliseconds, inInclusiveRange(120, 300));
      expect(UiMotion.standard.inMilliseconds, inInclusiveRange(120, 300));
      expect(UiMotion.emphasized.inMilliseconds, inInclusiveRange(120, 300));
      expect(
        find.byKey(const ValueKey('overview-empty-items')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<UiMotionEntrance>(
              find.byKey(const ValueKey('overview-empty-items')),
            )
            .duration,
        UiMotion.standard,
      );
    },
  );

  testWidgets('reduce motion disables decorative shell and section animation', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(
      tester
          .widget<AnimatedSwitcher>(
            find.byKey(const ValueKey('shell-tab-transition')),
          )
          .duration,
      Duration.zero,
    );
    expect(
      UiMotion.durationOf(tester.element(find.byType(AppShell))),
      Duration.zero,
    );
    expect(
      tester
          .widgetList<AnimatedScale>(find.byType(AnimatedScale))
          .every((animation) => animation.duration == Duration.zero),
      isTrue,
    );
  });

  testWidgets('home v2 survives small screen and 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('生活總覽'), findsWidgets);
    expect(find.text('還沒有生活項目'), findsOneWidget);
    expect(find.text('拍一張、說一句或輸入名稱開始'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('overview-capture-text')),
      160,
      scrollable: find.descendant(
        of: find.byKey(const ValueKey('overview-scroll')),
        matching: find.byType(Scrollable),
      ),
    );
    expect(find.text('拍一張'), findsOneWidget);
    expect(find.text('說一句'), findsOneWidget);
    expect(find.text('輸入'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
