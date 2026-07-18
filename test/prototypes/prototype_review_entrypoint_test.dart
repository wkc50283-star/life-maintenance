import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/prototype_main.dart';

void main() {
  testWidgets('review shell switches between approved prototypes', (tester) async {
    await tester.pumpWidget(const PrototypeReviewApp());

    expect(find.text('首頁樣板'), findsOneWidget);
    expect(find.text('項目詳情'), findsOneWidget);
    expect(find.text('今天的生活狀態'), findsOneWidget);

    await tester.tap(find.text('項目詳情'));
    await tester.pumpAndSettle();

    expect(find.text('我的機車'), findsOneWidget);
    expect(find.text('新增'), findsNothing);
    expect(find.text('設定'), findsNothing);
  });
}
