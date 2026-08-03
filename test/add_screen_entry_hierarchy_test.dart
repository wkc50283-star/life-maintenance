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

    expect(find.byKey(const ValueKey('overview-capture-photo')), findsNothing);
    expect(find.byKey(const ValueKey('overview-capture-voice')), findsNothing);
    expect(find.byKey(const ValueKey('overview-capture-text')), findsNothing);

    await tester.tap(find.text('新增'));
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

    await _openAddCenter(tester);

    expect(find.byKey(const ValueKey('item-create-by-photo')), findsNothing);
    expect(find.byKey(const ValueKey('item-create-by-voice')), findsNothing);
    expect(find.byKey(const ValueKey('item-create-by-text')), findsNothing);
    expect(find.text('拍照'), findsNothing);
    expect(find.text('說一句'), findsNothing);
    expect(find.text('輸入'), findsNothing);
  });

  testWidgets('advanced functions are immediately visible and operable', (
    tester,
  ) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
    );
    addTearDown(root.database.close);
    await tester.pumpWidget(LifeMaintenanceApp(compositionRoot: root));
    await tester.pumpAndSettle();
    await _openAddCenter(tester);

    expect(find.text('更多建立方式'), findsOneWidget);
    expect(find.text('分類'), findsOneWidget);
    expect(find.text('保養項目與步驟'), findsOneWidget);
    expect(find.text('一般提醒'), findsOneWidget);
    expect(find.text('階段性重點'), findsOneWidget);
    expect(find.text('提醒排程'), findsOneWidget);
    expect(find.text('突發事項／工程'), findsOneWidget);
    expect(find.text('補登完成紀錄'), findsOneWidget);

    await tester.tap(find.text('分類'));
    await tester.pumpAndSettle();
    expect(find.byType(CategoryManagementScreen), findsOneWidget);
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

    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('overview-capture-photo')));
    await tester.pump();
    expect(find.text('拍照建立尚未啟用，先使用輸入建立。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('overview-capture-voice')));
    await tester.pump();
    expect(find.text('語音建立尚未啟用，先使用輸入建立。'), findsOneWidget);
  });
}

Future<void> _openAddCenter(WidgetTester tester) async {
  if (find
      .byKey(const ValueKey('overview-capture-section'))
      .evaluate()
      .isEmpty) {
    await tester.tap(find.text('新增'));
    await tester.pumpAndSettle();
  }
  await tester.tap(find.byKey(const ValueKey('overview-capture-text')));
  await tester.pumpAndSettle();
  await tester.pageBack();
  await tester.pumpAndSettle();
}
