import 'dart:ui' show SemanticsAction;

import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/app_theme.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/screens/settings_screen.dart';

void main() {
  test('core foreground colors meet non-text and body-text contrast gates', () {
    final theme = AppTheme.light;

    expect(
      _contrast(theme.colorScheme.primary, Colors.white),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(const Color(0xFF687887), const Color(0xFFFFFFFC)),
      greaterThanOrEqualTo(4.5),
    );
    expect(
      _contrast(const Color(0xFF7C8995), const Color(0xFFFFFCF6)),
      greaterThanOrEqualTo(3),
    );
  });

  testWidgets('formal shell remains usable at 200 percent text scaling', (
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

    for (final label in const ['生活項目', '新增', '史略', '設定', '生活總覽']) {
      await tester.tap(find.text(label));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: label);
    }
  });

  testWidgets('primary navigation exposes 48dp targets', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    for (final label in const ['生活總覽', '生活項目', '新增', '史略', '設定']) {
      final target = find.descendant(
        of: find.byKey(const ValueKey('primary-navigation')),
        matching: find.text(label),
      );
      expect(tester.getSize(target).height, greaterThanOrEqualTo(14));
      final destination = find.ancestor(
        of: target,
        matching: find.byType(NavigationDestination),
      );
      expect(tester.getSize(destination).height, greaterThanOrEqualTo(48));
    }
  });

  testWidgets('settings action is announced as a focusable button', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    expect(find.byType(SettingsScreen), findsOneWidget);
    expect(find.bySemanticsLabel('開啟安全界線說明'), findsOneWidget);
    final action = tester.getSemantics(find.bySemanticsLabel('開啟安全界線說明'));
    expect(action.flagsCollection.isButton, isTrue);
    expect(action.getSemanticsData().hasAction(SemanticsAction.tap), isTrue);
    expect(
      tester.getSize(find.bySemanticsLabel('開啟安全界線說明')).height,
      greaterThanOrEqualTo(48),
    );
    semantics.dispose();
  });

  testWidgets('settings action supports keyboard focus and activation', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('設定'));
    await tester.pumpAndSettle();

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.text('安全分類規則'), findsOneWidget);
  });
}

double _contrast(Color first, Color second) {
  final lighter = first.computeLuminance() > second.computeLuminance()
      ? first.computeLuminance()
      : second.computeLuminance();
  final darker = first.computeLuminance() > second.computeLuminance()
      ? second.computeLuminance()
      : first.computeLuminance();
  return (lighter + 0.05) / (darker + 0.05);
}
