import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/screens/quick_add_screen.dart';

void main() {
  testWidgets('first layer shows only the three direct entry methods', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuickAddScreen())),
    );

    expect(find.text('現在需要記住或處理什麼？'), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-entry-photo')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-entry-voice')), findsOneWidget);
    expect(find.byKey(const ValueKey('quick-entry-text')), findsOneWidget);

    expect(find.text('保養項目與步驟'), findsNothing);
    expect(find.text('一般提醒'), findsNothing);
    expect(find.text('階段性重點'), findsNothing);
    expect(find.text('提醒排程'), findsNothing);
    expect(find.text('突發事項／工程'), findsNothing);
  });

  testWidgets('advanced functions remain reachable behind more methods', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuickAddScreen())),
    );

    await tester.tap(find.byKey(const ValueKey('quick-entry-more-methods')));
    await tester.pumpAndSettle();

    expect(find.text('查看全部正式功能'), findsOneWidget);
    expect(
      find.text('開啟原有完整新增頁，選擇保養、提醒、排程、案件或完成紀錄。'),
      findsOneWidget,
    );
  });

  testWidgets('photo and voice explain that they are not enabled', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: QuickAddScreen())),
    );

    await tester.tap(find.byKey(const ValueKey('quick-entry-photo')));
    await tester.pump();
    expect(find.text('拍照建立尚未啟用，先使用輸入建立。'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('quick-entry-voice')));
    await tester.pump();
    expect(find.text('語音建立尚未啟用，先使用輸入建立。'), findsOneWidget);
  });
}
