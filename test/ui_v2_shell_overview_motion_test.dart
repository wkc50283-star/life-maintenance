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
        const ['生活總覽', '生活項目', '新增', '履歷', '設定'],
      );
      expect(find.byKey(const ValueKey('overview-quick-add')), findsNothing);
      expect(
        find.byKey(const ValueKey('overview-capture-section')),
        findsNothing,
      );

      await tester.tap(find.text('新增'));
      await tester.pumpAndSettle();

      final textEntry = find.byKey(const ValueKey('overview-capture-text'));
      await Scrollable.ensureVisible(tester.element(textEntry), alignment: 0.5);
      await tester.pumpAndSettle();
      await tester.tap(textEntry);
      await tester.pumpAndSettle();

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
            .widgetList<UiMotionEntrance>(find.byType(UiMotionEntrance))
            .any((animation) => animation.duration == UiMotion.standard),
        isTrue,
      );
    },
  );

  testWidgets('quick capture toggles consistently across main destinations', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);

    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    final section = find.byKey(const ValueKey('overview-capture-section'));
    final navigation = find.byKey(const ValueKey('primary-navigation'));
    expect(section, findsNothing);

    for (final destination in const [
      ('生活總覽', 0),
      ('生活項目', 1),
      ('履歷', 3),
      ('設定', 4),
    ]) {
      await tester.tap(_navigationLabel(destination.$1));
      await tester.pumpAndSettle();
      expect(section, findsNothing);
      await tester.tap(_navigationLabel('新增'));
      await tester.pumpAndSettle();
      expect(section, findsOneWidget);
      expect(
        tester.widget<NavigationBar>(navigation).selectedIndex,
        destination.$2,
      );
      await tester.tap(_navigationLabel('新增'));
      await tester.pumpAndSettle();
      expect(section, findsNothing);
    }

    await tester.tap(_navigationLabel('履歷'));
    await tester.pumpAndSettle();
    await tester.tap(_navigationLabel('新增'));
    await tester.pumpAndSettle();
    expect(section, findsOneWidget);
    await tester.tap(_navigationLabel('設定'));
    await tester.pumpAndSettle();
    expect(section, findsNothing);

    await tester.tap(_navigationLabel('新增'));
    await tester.pumpAndSettle();
    final textButton = find.byKey(const ValueKey('overview-capture-text'));
    final voice = find.byKey(const ValueKey('overview-capture-voice'));
    final photo = find.byKey(const ValueKey('overview-capture-photo'));
    expect(tester.getCenter(voice).dx, lessThan(tester.getCenter(photo).dx));
    expect(
      tester.getCenter(photo).dx,
      lessThan(tester.getCenter(textButton).dx),
    );
    expect(find.text('語音'), findsOneWidget);
    expect(find.text('說一句'), findsNothing);
    expect(find.byKey(const ValueKey('overview-capture-more')), findsNothing);
    expect(find.text('開啟更多建立方式'), findsNothing);
    expect(
      tester.getRect(section).bottom,
      lessThanOrEqualTo(tester.getRect(navigation).top),
    );
  });

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
    expect(find.textContaining('安，國政'), findsOneWidget);
    expect(find.text('還沒有生活項目'), findsOneWidget);
    expect(find.text('今天發生了什麼？'), findsNothing);
    expect(find.text('記錄生活，AI 幫你整理'), findsNothing);
    await tester.tap(_navigationLabel('新增'));
    await tester.pumpAndSettle();
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('語音'), findsOneWidget);
    expect(find.text('說一句'), findsNothing);
    expect(find.text('手動建立'), findsOneWidget);
    expect(find.text('輸入'), findsNothing);
    expect(find.text('開啟更多建立方式'), findsNothing);
    final section = find.byKey(const ValueKey('overview-capture-section'));
    expect(tester.getSize(section).height, lessThan(220));
    expect(tester.takeException(), isNull);
  });
}

Finder _navigationLabel(String label) => find.descendant(
  of: find.byKey(const ValueKey('primary-navigation')),
  matching: find.text(label),
);
