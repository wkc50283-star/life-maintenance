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
    expect(find.text('進行中的案件'), findsOneWidget);
    expect(find.text('階段性重點與大修'), findsOneWidget);
    expect(find.text('最近完成'), findsOneWidget);
    expect(find.text('浴室牆面持續滲水'), findsOneWidget);
  });

  testWidgets('item detail prototype separates all formal data roles', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: ItemDetailVisualPrototype()),
    );

    expect(find.text('我的機車'), findsOneWidget);
    expect(find.text('需要注意'), findsOneWidget);
    expect(find.text('保養項目'), findsOneWidget);
    expect(find.text('提醒與排程'), findsOneWidget);
    expect(find.text('階段性重點與大修'), findsOneWidget);
    expect(find.text('進行中案件'), findsOneWidget);
    expect(find.text('史略'), findsOneWidget);
    expect(find.text('基本資料'), findsOneWidget);
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
