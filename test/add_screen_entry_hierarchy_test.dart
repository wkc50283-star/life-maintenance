import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/screens/add_screen.dart';

void main() {
  testWidgets('add screen shows one direct entry layer', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddScreen())),
    );

    expect(find.text('現在需要記住或處理什麼？'), findsOneWidget);
    expect(find.byKey(const ValueKey('item-create-by-photo')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-create-by-voice')), findsOneWidget);
    expect(find.byKey(const ValueKey('item-create-by-text')), findsOneWidget);
    expect(find.text('拍照'), findsOneWidget);
    expect(find.text('語音'), findsOneWidget);
    expect(find.text('輸入'), findsOneWidget);
  });

  testWidgets('advanced functions stay collapsed until requested', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddScreen())),
    );

    expect(find.text('新增提醒'), findsNothing);
    expect(find.text('補登完成紀錄'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('add-more-methods')));
    await tester.pumpAndSettle();

    expect(find.text('新增提醒'), findsOneWidget);
    expect(find.text('補登完成紀錄'), findsOneWidget);
  });

  testWidgets('photo and voice report unavailable honestly', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: AddScreen())),
    );

    await tester.tap(find.byKey(const ValueKey('item-create-by-photo')));
    await tester.pump();
    expect(find.text('拍照建立尚未啟用，先使用輸入建立。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('item-create-by-voice')));
    await tester.pump();
    expect(find.text('語音建立尚未啟用，先使用輸入建立。'), findsOneWidget);
  });
}
