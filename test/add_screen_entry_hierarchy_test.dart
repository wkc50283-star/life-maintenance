import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/main.dart';
import 'package:life_maintenance/screens/formal_planning_screens.dart';

void main() {
  testWidgets('quick capture exists only on the overview', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('overview-capture-photo')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('overview-capture-voice')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('overview-capture-text')), findsOneWidget);

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('item-create-by-photo')), findsNothing);
    expect(find.byKey(const ValueKey('item-create-by-voice')), findsNothing);
    expect(find.byKey(const ValueKey('item-create-by-text')), findsNothing);
    expect(find.text('拍照'), findsNothing);
    expect(find.text('說一句'), findsNothing);
    expect(find.text('輸入'), findsNothing);
  });

  testWidgets('manual creation shows only four approved life purposes', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();

    expect(find.text('你現在想做什麼？'), findsOneWidget);
    expect(find.text('建立要長期管理的內容'), findsOneWidget);
    expect(find.text('安排未來要注意或處理的事情'), findsOneWidget);
    expect(find.text('記錄正在處理的事情'), findsOneWidget);
    expect(find.text('補記已完成的事情'), findsOneWidget);
    for (final legacyLabel in [
      '更多建立方式',
      '分類',
      '保養項目與步驟',
      '一般提醒',
      '階段性重點',
      '提醒排程',
      '突發事項／工程',
      '補登完成紀錄',
    ]) {
      expect(find.text(legacyLabel), findsNothing);
    }
  });

  testWidgets('four purposes route correctly and returning writes no data', (
    tester,
  ) async {
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
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    final before = await _formalWriteCount(root.database);

    await _tapPurpose(tester, 'manual-create-purpose-item');
    expect(find.byType(ItemFormScreen), findsOneWidget);
    await tester.pageBack();
    await tester.pumpAndSettle();

    for (final route in const {
      'manual-create-purpose-future-matter':
          'manual-create-future-matter-route',
      'manual-create-purpose-work-case': 'manual-create-work-case-route',
      'manual-create-purpose-completed': 'manual-create-completed-route',
    }.entries) {
      await _tapPurpose(tester, route.key);
      expect(find.byKey(ValueKey(route.value)), findsOneWidget);
      expect(find.textContaining('尚在準備中'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    expect(await _formalWriteCount(root.database), before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('home photo and voice report unavailable honestly', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('overview-capture-photo')));
    await tester.pump();
    expect(find.text('拍照建立尚未啟用，先使用輸入建立。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overview-capture-voice')));
    await tester.pump();
    expect(find.text('語音建立尚未啟用，先使用輸入建立。'), findsOneWidget);
  });
}

Future<void> _tapPurpose(WidgetTester tester, String key) async {
  final finder = find.byKey(ValueKey(key));
  await tester.scrollUntilVisible(
    finder,
    120,
    scrollable: find.byType(Scrollable).last,
  );
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<int> _formalWriteCount(AppDatabase database) async {
  final row = await database.customSelect('''
    SELECT
      (SELECT count(*) FROM items) +
      (SELECT count(*) FROM future_matters) +
      (SELECT count(*) FROM work_cases) +
      (SELECT count(*) FROM maintenance_records) +
      (SELECT count(*) FROM item_lifecycle_events) +
      (SELECT count(*) FROM future_matter_created_events) AS total
  ''').getSingle();
  return row.read<int>('total');
}
