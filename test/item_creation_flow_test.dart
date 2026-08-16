import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/models/item_management_period.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/screens/formal_planning_screens.dart';

void main() {
  late AppDatabase database;
  late AppCompositionRoot root;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    root = AppCompositionRoot(database: database);
    await database.customSelect('SELECT 1').get();
  });

  tearDown(() => database.close());

  testWidgets('direct capture entries are honest and stay in the Add center', (
    tester,
  ) async {
    await _pumpApp(tester, root);

    expect(
      find.byKey(const ValueKey('overview-capture-photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('overview-capture-voice')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('overview-capture-text')), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overview-capture-photo')));
    await tester.pumpAndSettle();
    expect(find.text('拍照建立尚未啟用，先使用輸入建立。'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('overview-capture-voice')));
    await tester.pumpAndSettle();
    expect(find.text('語音建立尚未啟用，先使用輸入建立。'), findsOneWidget);

    await _openAdd(tester);
    expect(find.text('拍照'), findsNothing);
    expect(find.text('說一句'), findsNothing);
    expect(find.text('輸入'), findsNothing);
    expect(find.text('你現在想做什麼？'), findsOneWidget);
    expect(find.text('建立要長期管理的內容'), findsOneWidget);
    expect(find.text('安排未來要注意或處理的事情'), findsOneWidget);
    expect(find.text('記錄正在處理的事情'), findsOneWidget);
    expect(find.text('補記已完成的事情'), findsOneWidget);
    expect(find.text('分類'), findsNothing);
    expect(find.text('一般提醒'), findsNothing);
    expect(find.text('突發事項／工程'), findsNothing);
    expect(find.text('補登完成紀錄'), findsNothing);
    expect(await database.select(database.items).get(), isEmpty);
  });

  testWidgets(
    'text flow creates one Item and one created history with selected periods',
    (tester) async {
      await _pumpApp(tester, root);
      await _openTextForm(tester);

      expect(find.text('確認生活項目'), findsOneWidget);
      expect(find.text('放置位置'), findsNothing);
      expect(find.text('預計管理年限'), findsNothing);
      expect(find.text('備註'), findsNothing);
      expect(
        tester
            .widget<DropdownButtonFormField<String>>(
              find.byKey(const ValueKey('item-category')),
            )
            .initialValue,
        ItemSystemCategory.unclassifiedId,
      );

      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pump();
      expect(await database.select(database.items).get(), isEmpty);

      await tester.enterText(
        find.byKey(const ValueKey('item-name')),
        '  測試冷氣  ',
      );
      await tester.tap(find.byKey(const ValueKey('item-period-year')));
      await tester.tap(find.byKey(const ValueKey('item-period-month')));
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      expect(find.byType(ItemCreationSuccessScreen), findsOneWidget);
      expect(find.text('建立生活項目'), findsOneWidget);
      expect(find.text('測試冷氣'), findsOneWidget);
      expect(find.text('未分類'), findsOneWidget);
      expect(find.text('年、月'), findsOneWidget);

      final items = await database.select(database.items).get();
      expect(items, hasLength(1));
      expect(items.single.name, '測試冷氣');
      expect(items.single.categoryId, ItemSystemCategory.unclassifiedId);
      expect(
        await database.select(database.itemLifecycleEvents).get(),
        hasLength(1),
      );
      expect(
        (await root.itemCreationRuntime.listManagementPeriods(items.single.id)),
        {ItemManagementPeriod.year, ItemManagementPeriod.month},
      );
      expect(await database.select(database.tasks).get(), isEmpty);
      expect(await database.select(database.schedules).get(), isEmpty);
      expect(await database.select(database.generalReminders).get(), isEmpty);
      expect(await database.select(database.maintenancePlans).get(), isEmpty);
      expect(await database.select(database.milestones).get(), isEmpty);
      expect(await database.select(database.workCases).get(), isEmpty);

      await tester.tap(find.byKey(const ValueKey('item-creation-complete')));
      await tester.pumpAndSettle();
      expect(find.text('生活項目'), findsWidgets);
      expect(find.text('測試冷氣'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('primary-navigation')),
          matching: find.text('履歷'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('建立生活項目'), findsOneWidget);
      expect(find.text('生活項目履歷'), findsOneWidget);

      await tester.tap(
        find.descendant(
          of: find.byKey(const ValueKey('primary-navigation')),
          matching: find.text('生活項目'),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('測試冷氣'));
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('建立生活項目'),
        500,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('建立生活項目'), findsOneWidget);
      expect(find.textContaining('管理週期：年、月'), findsOneWidget);
    },
  );

  testWidgets('new category is selected precisely and periods may be skipped', (
    tester,
  ) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);
    await tester.enterText(find.byKey(const ValueKey('item-name')), '書房桌燈');

    await tester.tap(find.byKey(const ValueKey('create-item-category')));
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('category-name')), '照明設備');
    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final categories = await root.driftRepositories.itemCategories.listAll();
    final created = categories.singleWhere(
      (category) => category.displayName == '照明設備',
    );
    expect(
      tester
          .widget<DropdownButtonFormField<String>>(
            find.byKey(const ValueKey('item-category')),
          )
          .initialValue,
      created.id,
    );

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();
    final item = (await database.select(database.items).get()).single;
    expect(item.categoryId, created.id);
    expect(
      await root.itemCreationRuntime.listManagementPeriods(item.id),
      isEmpty,
    );
  });
}

Future<void> _pumpApp(WidgetTester tester, AppCompositionRoot root) async {
  await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
  await tester.pumpAndSettle();
}

Future<void> _openAdd(WidgetTester tester) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(const ValueKey('primary-navigation')),
      matching: find.text('新增'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _openTextForm(WidgetTester tester) async {
  await tester.tap(find.byKey(const ValueKey('overview-capture-text')));
  await tester.pumpAndSettle();
  expect(find.byType(ItemFormScreen), findsOneWidget);
}
