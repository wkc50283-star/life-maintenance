import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/ui_tokens.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/repositories/formal_planning_editor.dart';
import 'package:life_maintenance/widgets/add_entry_card.dart';

void main() {
  test('UI foundation exposes centralized visual and motion tokens', () {
    expect(UiColors.primary, const Color(0xFF173B63));
    expect(UiSpace.md, 16);
    expect(UiRadius.card, 16);
    expect(UiShadow.card, isNotEmpty);
    expect(UiMotion.standard, const Duration(milliseconds: 180));
    expect(UiMotion.standardCurve, Curves.easeOutCubic);
  });

  testWidgets(
    'empty Item form provides an operable path to create a category',
    (tester) async {
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();

      await _openNewItemForm(tester);

      expect(find.text('目前還沒有可使用的分類。'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-first-category')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('create-first-category')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-name')),
        '家中設備',
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      expect(find.text('家中設備'), findsOneWidget);
      expect(find.byKey(const ValueKey('item-category')), findsOneWidget);
    },
  );

  testWidgets(
    'small phone keyboard keeps save visible and form bottom reachable',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = const Size(320, 568);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);
      final editor = FormalPlanningEditor.from(root)!;
      final now = DateTime.utc(2026, 7, 22);
      await editor.saveCategory(
        EditableCategory(
          id: 'category-home',
          systemCode: 'home',
          displayName: '家中設備',
          sortOrder: 0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();
      await _openNewItemForm(tester);

      await _advanceItemForm(tester, name: '客廳冷氣');

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();

      final saveRect = tester.getRect(find.byKey(const ValueKey('save-form')));
      expect(saveRect.bottom, lessThanOrEqualTo(568 - 280));
      await tester.scrollUntilVisible(
        find.text('備註'),
        120,
        scrollable: find
            .descendant(
              of: find.byKey(const ValueKey('item-form-scroll')),
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('備註'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('Item form is safe at 200 percent text scaling', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 568);
    tester.platformDispatcher.textScaleFactorTestValue = 2;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    await _openNewItemForm(tester);

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('item-form-next')), findsOneWidget);
  });

  testWidgets('Item category selection changes the formal saved relation', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 22);
    for (final category in const [
      ('category-home', 'home', '家中設備'),
      ('category-vehicle', 'vehicle', '車輛'),
    ]) {
      await editor.saveCategory(
        EditableCategory(
          id: category.$1,
          systemCode: category.$2,
          displayName: category.$3,
          sortOrder: 0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await _openNewItemForm(tester);

    await tester.enterText(find.byKey(const ValueKey('item-name')), '家庭汽車');
    await tester.tap(find.byKey(const ValueKey('item-category')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('車輛').last);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('item-form-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final item = (await editor.loadItems()).single;
    expect(item.name, '家庭汽車');
    expect(item.categoryId, 'category-vehicle');
  });

  testWidgets('Item form respects phone SafeArea at formal device sizes', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetPadding);

    for (final size in const [Size(390, 844), Size(360, 800)]) {
      tester.view.physicalSize = size;
      tester.view.padding = const FakeViewPadding(
        left: 12,
        right: 12,
        bottom: 24,
      );
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();
      await _openNewItemForm(tester);

      final formRect = tester.getRect(
        find.byKey(const ValueKey('item-form-scroll')),
      );
      final saveRect = tester.getRect(
        find.byKey(const ValueKey('item-form-next')),
      );
      expect(formRect.left, greaterThanOrEqualTo(12), reason: '$size');
      expect(
        formRect.right,
        lessThanOrEqualTo(size.width - 12),
        reason: '$size',
      );
      expect(
        saveRect.bottom,
        lessThanOrEqualTo(size.height - 24),
        reason: '$size',
      );
      expect(tester.takeException(), isNull, reason: '$size');

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
      await root.database.close();
    }
  });
}

Future<void> _advanceItemForm(
  WidgetTester tester, {
  required String name,
}) async {
  await tester.enterText(find.byKey(const ValueKey('item-name')), name);
  await tester.tap(find.byKey(const ValueKey('item-form-next')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('save-form')), findsOneWidget);
}

Future<void> _openNewItemForm(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('primary-navigation')),
      matching: find.text('新增'),
    ),
  );
  await tester.pumpAndSettle();
  final itemEntry = find.widgetWithText(AddEntryCard, '生活項目');
  await tester.ensureVisible(itemEntry);
  await tester.pumpAndSettle();
  await tester.tap(itemEntry);
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-entry')));
  await tester.pumpAndSettle();
}
