import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/app/ui_tokens.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/repositories/formal_planning_editor.dart';
import 'package:life_maintenance/screens/formal_planning_screens.dart';
import 'package:life_maintenance/screens/item_detail_screen.dart';

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
    'Item form provides unclassified and an operable path to create a category',
    (tester) async {
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();

      await _openNewItemForm(tester);

      expect(find.text('未分類'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('create-item-category')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('create-item-category')));
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
    'Item form creates and selects the exact formal category without losing input',
    (tester) async {
      final root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase.memory()),
      );
      addTearDown(root.database.close);
      final editor = FormalPlanningEditor.from(root)!;
      final now = DateTime.utc(2026, 7, 27);
      await editor.saveCategory(
        EditableCategory(
          id: 'category-existing',
          systemCode: 'home',
          displayName: '既有分類',
          sortOrder: 0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
      await tester.pumpAndSettle();
      await _openNewItemForm(tester);

      expect(
        find.byKey(const ValueKey('create-item-category')),
        findsOneWidget,
      );
      await tester.enterText(find.byKey(const ValueKey('item-name')), '客廳沙發');
      await tester.tap(find.byKey(const ValueKey('create-item-category')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('category-name')),
        '家具用品',
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      final categories = await editor.loadCategories();
      final createdCategory = categories.singleWhere(
        (category) => category.displayName == '家具用品',
      );
      final categoryFieldState = tester.state<FormFieldState<String>>(
        find.byKey(const ValueKey('item-category')),
      );
      expect(categoryFieldState.value, createdCategory.id);
      expect(categoryFieldState.value, isNot('category-existing'));
      expect(find.text('家具用品'), findsOneWidget);
      expect(find.text('客廳沙發'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      final item = (await editor.loadItems()).single;
      expect(item.categoryId, createdCategory.id);
      expect(find.byType(ItemCreationSuccessScreen), findsOneWidget);
      expect(find.text('客廳沙發'), findsOneWidget);
    },
  );

  testWidgets('cancelling category creation preserves Item form selection', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 27);
    await editor.saveCategory(
      EditableCategory(
        id: 'category-existing',
        systemCode: 'home',
        displayName: '既有分類',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await _openNewItemForm(tester);
    await tester.enterText(find.byKey(const ValueKey('item-name')), '保留名稱');

    await tester.tap(find.byKey(const ValueKey('create-item-category')));
    await tester.pumpAndSettle();
    await tester.pageBack();
    await tester.pumpAndSettle();

    final categoryField = tester.widget<DropdownButtonFormField<String>>(
      find.byKey(const ValueKey('item-category')),
    );
    expect(categoryField.initialValue, 'system-category-unclassified');
    expect(find.text('保留名稱'), findsOneWidget);
    expect(await editor.loadCategories(), hasLength(1));
  });

  testWidgets('failed category save stays in Category form', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 27);
    await editor.saveCategory(
      EditableCategory(
        id: 'category-existing',
        systemCode: 'home',
        displayName: '既有分類',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await _openNewItemForm(tester);
    await tester.tap(find.byKey(const ValueKey('create-item-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-name')), '不應建立');
    await database.close();

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    expect(find.byType(CategoryFormScreen), findsOneWidget);
    expect(find.text('新增分類'), findsOneWidget);
    expect(find.text('不應建立'), findsOneWidget);
  });

  testWidgets('Category form keeps the management bool result contract', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    bool? changed;
    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: MaterialApp(
          home: Builder(
            builder: (context) => TextButton(
              onPressed: () async {
                changed = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(builder: (_) => const CategoryFormScreen()),
                );
              },
              child: const Text('開啟分類'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('開啟分類'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-name')), '管理分類');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    expect(changed, isTrue);
    expect(
      await FormalPlanningEditor.from(root)!.loadCategories(),
      hasLength(1),
    );
  });

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

      await tester.enterText(find.byKey(const ValueKey('item-name')), '客廳冷氣');

      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();

      final saveRect = tester.getRect(find.byKey(const ValueKey('save-form')));
      expect(saveRect.bottom, lessThanOrEqualTo(568 - 280));
      expect(find.text('管理週期（可複選）'), findsOneWidget);
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

    await tester.ensureVisible(
      find.byKey(const ValueKey('custom-period-value')),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byKey(const ValueKey('save-form')), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-period-unit')), findsOneWidget);
    expect(find.byKey(const ValueKey('add-custom-period')), findsOneWidget);
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
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final item = (await editor.loadItems()).single;
    expect(item.name, '家庭汽車');
    expect(item.categoryId, 'category-vehicle');
  });

  testWidgets('new Item save shows success and completes into Items', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 27);
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
    await editor.saveItem(
      EditableItem(
        id: 'item-existing',
        name: '既有汽車',
        categoryId: 'category-home',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await _openNewItemForm(tester);

    await _advanceItemForm(tester, name: '新建立冷氣');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final formalItems = await root.itemReadRepository.loadItems();
    final createdItem = formalItems.singleWhere((item) => item.name == '新建立冷氣');
    expect(find.byType(ItemCreationSuccessScreen), findsOneWidget);
    expect(find.text('建立生活項目'), findsOneWidget);
    expect(createdItem.id, isNot('item-existing'));
    expect(find.text('新建立冷氣'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('item-creation-complete')));
    await tester.pumpAndSettle();
    expect(find.text('新建立冷氣'), findsOneWidget);
  });

  testWidgets('failed Item save stays in the form', (tester) async {
    final database = AppDatabase(NativeDatabase.memory());
    final root = AppCompositionRoot(database: database);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 27);
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
    await _advanceItemForm(tester, name: '儲存失敗項目');
    await database.close();

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    expect(find.byType(ItemFormScreen), findsOneWidget);
    expect(find.byType(ItemDetailScreen), findsNothing);
  });

  testWidgets('existing Item edit keeps the changed result contract', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    final editor = FormalPlanningEditor.from(root)!;
    final now = DateTime.utc(2026, 7, 27);
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
    await editor.saveItem(
      EditableItem(
        id: 'item-edit',
        name: '編輯前項目',
        categoryId: 'category-home',
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('生活項目'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('編輯前項目'));
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('編輯生活項目'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byKey(const ValueKey('item-name')), '編輯後項目');
    await tester.tap(find.byKey(const ValueKey('item-form-next')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    expect(find.byType(ItemDetailScreen), findsNothing);
    expect(find.text('編輯後項目'), findsOneWidget);
    expect((await editor.loadItems()).single.name, '編輯後項目');
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
      final saveRect = tester.getRect(find.byKey(const ValueKey('save-form')));
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
  expect(find.byKey(const ValueKey('save-form')), findsOneWidget);
}

Future<void> _openNewItemForm(WidgetTester tester) async {
  final textEntry = find.byKey(const ValueKey('overview-capture-text'));
  await Scrollable.ensureVisible(tester.element(textEntry), alignment: 0.5);
  await tester.pumpAndSettle();
  await tester.tap(textEntry);
  await tester.pumpAndSettle();
  expect(find.text('確認生活項目'), findsOneWidget);
  expect(find.byKey(const ValueKey('item-name')), findsOneWidget);
  expect(find.text('生活項目是所有提醒、保養與階段重點的起點。'), findsNothing);
}
