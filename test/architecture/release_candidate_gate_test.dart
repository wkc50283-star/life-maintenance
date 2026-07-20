import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Pages deploys the formal production entrypoint only', () {
    final workflow = File(
      '.github/workflows/deploy-pages.yml',
    ).readAsStringSync();

    expect(
      workflow,
      contains('flutter build web --release --base-href /life-maintenance/'),
    );
    expect(workflow, isNot(contains('prototype_main.dart')));
    expect(workflow, contains('path: build/web'));
    expect(workflow, contains('drift_worker.dart.js'));
    expect(workflow, contains('sqlite3.wasm'));
    expect(workflow, contains('Prototype content must not be deployed'));
  });

  test('formal main owns the production root and five-destination shell', () {
    final mainSource = File('lib/main.dart').readAsStringSync();
    final shellSource = File('lib/app/app_shell.dart').readAsStringSync();

    expect(mainSource, contains('AppCompositionRoot.production()'));
    expect(mainSource, contains('AppShell('));
    expect(mainSource, isNot(contains('PrototypeReviewApp')));
    for (final destination in const ['生活總覽', '生活項目', '新增', '史略', '設定']) {
      expect(shellSource, contains(destination), reason: destination);
    }
  });
}
