import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/models/item_custom_management_period.dart';
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
      await _addCustomPeriod(
        tester,
        value: '3',
        unit: ItemManagementIntervalUnit.quarter,
      );
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.tap(find.byKey(const ValueKey('save-form')));
      await tester.pumpAndSettle();

      expect(find.byType(ItemCreationSuccessScreen), findsOneWidget);
      expect(find.text('建立生活項目'), findsOneWidget);
      expect(find.text('測試冷氣'), findsOneWidget);
      expect(find.text('未分類'), findsOneWidget);
      expect(find.text('年、月、每 3 季'), findsOneWidget);

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
      expect(
        await root.itemCreationRuntime.listCustomManagementPeriods(
          items.single.id,
        ),
        {
          ItemCustomManagementPeriod(
            intervalValue: 3,
            intervalUnit: ItemManagementIntervalUnit.quarter,
          ),
        },
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
      expect(find.text('管理週期：年、月、每 3 季'), findsOneWidget);

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
      expect(find.textContaining('管理週期：年、月、每 3 季'), findsOneWidget);
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

  testWidgets('custom periods support multiple rows and deletion', (
    tester,
  ) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);

    await _addCustomPeriod(
      tester,
      value: '2',
      unit: ItemManagementIntervalUnit.week,
    );
    await _addCustomPeriod(
      tester,
      value: '3',
      unit: ItemManagementIntervalUnit.quarter,
    );

    expect(find.text('每 2 週'), findsOneWidget);
    expect(find.text('每 3 季'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('remove-custom-period-0')));
    await tester.pump();
    expect(find.text('每 2 週'), findsNothing);
    expect(find.text('每 3 季'), findsOneWidget);
  });

  testWidgets('custom period requires a positive integer', (tester) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);

    await tester.enterText(
      find.byKey(const ValueKey('custom-period-value')),
      '0',
    );
    await tester.ensureVisible(find.byKey(const ValueKey('add-custom-period')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('add-custom-period')));
    await tester.pump();

    expect(find.text('N 必須是正整數。'), findsOneWidget);
    expect(find.byKey(const ValueKey('custom-period-0')), findsNothing);
  });

  testWidgets('unadded custom period input blocks submission clearly', (
    tester,
  ) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);
    await tester.enterText(find.byKey(const ValueKey('item-name')), '測試項目');
    await tester.enterText(
      find.byKey(const ValueKey('custom-period-value')),
      '2',
    );

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pump();

    expect(find.textContaining('請先新增目前輸入的自訂週期'), findsOneWidget);
    expect(await database.select(database.items).get(), isEmpty);
  });

  testWidgets('equivalent fixed and custom periods are rejected before save', (
    tester,
  ) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);
    await tester.enterText(find.byKey(const ValueKey('item-name')), '測試項目');
    await tester.tap(find.byKey(const ValueKey('item-period-week')));
    await _addCustomPeriod(
      tester,
      value: '7',
      unit: ItemManagementIntervalUnit.day,
    );

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pump();

    expect(find.textContaining('等價，請保留其中一筆'), findsOneWidget);
    expect(await database.select(database.items).get(), isEmpty);
  });

  testWidgets('custom N equals one is normalized by the runtime', (
    tester,
  ) async {
    await _pumpApp(tester, root);
    await _openTextForm(tester);
    await tester.enterText(find.byKey(const ValueKey('item-name')), '季度項目');
    await _addCustomPeriod(
      tester,
      value: '1',
      unit: ItemManagementIntervalUnit.quarter,
    );

    await tester.tap(find.byKey(const ValueKey('save-form')));
    await tester.pumpAndSettle();

    final item = (await database.select(database.items).get()).single;
    expect(await root.itemCreationRuntime.listManagementPeriods(item.id), {
      ItemManagementPeriod.quarter,
    });
    expect(
      await root.itemCreationRuntime.listCustomManagementPeriods(item.id),
      isEmpty,
    );
    expect(find.text('季'), findsOneWidget);
    expect(find.text('每 1 季'), findsNothing);
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

Future<void> _addCustomPeriod(
  WidgetTester tester, {
  required String value,
  required ItemManagementIntervalUnit unit,
}) async {
  await tester.enterText(
    find.byKey(const ValueKey('custom-period-value')),
    value,
  );
  await tester.ensureVisible(find.byKey(const ValueKey('custom-period-unit')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('custom-period-unit')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.text(_intervalUnitLabel(unit)).last,
    warnIfMissed: false,
  );
  await tester.pumpAndSettle();
  await tester.ensureVisible(find.byKey(const ValueKey('add-custom-period')));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('add-custom-period')));
  await tester.pump();
}

String _intervalUnitLabel(ItemManagementIntervalUnit unit) => switch (unit) {
  ItemManagementIntervalUnit.day => '天',
  ItemManagementIntervalUnit.week => '週',
  ItemManagementIntervalUnit.month => '月',
  ItemManagementIntervalUnit.quarter => '季',
  ItemManagementIntervalUnit.halfYear => '半年',
  ItemManagementIntervalUnit.year => '年',
};
