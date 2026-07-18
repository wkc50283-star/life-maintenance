import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/prototypes/life_management_visual_prototypes.dart';

void main() {
  testWidgets('home prototype exposes the approved information hierarchy', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeVisualPrototype()),
    );

    expect(find.text('今天的生活狀態'), findsOneWidget);
    expect(find.text('現在需要處理'), findsOneWidget);
    expect(find.text('浴室牆面持續滲水'), findsOneWidget);

    await _scrollToText(tester, '進行中的案件');
    await _scrollToText(tester, '階段性重點與大修');
    await _scrollToText(tester, '最近完成');
  });

  testWidgets('item detail prototype separates all formal data roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ItemDetailVisualPrototype()),
    );

    expect(find.text('我的機車'), findsOneWidget);
    await _scrollToText(tester, '需要注意');
    await _scrollToText(tester, '保養項目');
    await _scrollToText(tester, '提醒與排程');
    await _scrollToText(tester, '階段性重點與大修');
    await _scrollToText(tester, '進行中案件');
    await _scrollToText(tester, '史略');
    await _scrollToText(tester, '基本資料');
  });

  testWidgets('prototypes are review-only and expose no tappable actions', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: HomeVisualPrototype()),
    );

    expect(find.byType(FilledButton), findsNothing);
    expect(find.byType(OutlinedButton), findsNothing);
    expect(find.byType(TextButton), findsNothing);
    expect(find.byType(IconButton), findsNothing);
  });
}

Future<void> _scrollToText(WidgetTester tester, String text) async {
  final target = find.text(text);
  await tester.scrollUntilVisible(
    target,
    260,
    scrollable: find.byType(Scrollable).first,
  );
  expect(target, findsOneWidget);
}
