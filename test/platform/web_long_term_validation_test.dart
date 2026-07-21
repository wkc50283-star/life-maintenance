import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('web persistence identity and asset URLs remain stable', () {
    final databaseSource = File(
      'lib/database/app_database.dart',
    ).readAsStringSync();

    expect(databaseSource, contains("name: 'life_maintenance'"));
    expect(databaseSource, contains("Uri.parse('sqlite3.wasm')"));
    expect(databaseSource, contains("Uri.parse('drift_worker.dart.js')"));
    expect(databaseSource, isNot(contains("name: 'life_maintenance_v")));
  });

  test('Pages deploy disables the deprecated Flutter service worker', () {
    final workflow = File(
      '.github/workflows/deploy-pages.yml',
    ).readAsStringSync();

    expect(workflow, contains('flutter build web --release'));
    expect(workflow, contains('--base-href /life-maintenance/'));
    expect(workflow, contains('--pwa-strategy=none'));
    expect(workflow, contains('test ! -s build/web/flutter_service_worker.js'));
    expect(workflow, contains("grep -q 'serviceWorkerVersion: \"'"));
  });

  test('existing Pages origin retires only this app service worker first', () {
    final index = File('web/index.html').readAsStringSync();
    final retirement = File(
      'web/service_worker_retirement.js',
    ).readAsStringSync();

    expect(index, contains('service_worker_retirement.js'));
    expect(index, isNot(contains('flutter_bootstrap.js" async')));
    expect(retirement, contains('new URL(document.baseURI).href'));
    expect(retirement, contains('registration.scope === appScope'));
    expect(retirement, contains('registration.unregister()'));
    expect(retirement, contains('window.location.reload()'));
    expect(retirement, contains("bootstrap.src = 'flutter_bootstrap.js'"));
    expect(retirement, isNot(contains('indexedDB.deleteDatabase')));
    expect(retirement, isNot(contains('localStorage.clear')));
    expect(retirement, isNot(contains('sessionStorage.clear')));
  });

  test('web checklist does not overclaim browser lifecycle evidence', () {
    final baseline = File(
      'docs/control/44-web-long-term-validation.md',
    ).readAsStringSync();

    for (final requirement in const [
      '重新整理',
      '關閉所有該站分頁',
      '完全結束瀏覽器程序',
      '背景恢復',
      'Drift 持久化',
      'GitHub Pages',
      '不得用 unit test',
      'iPhone／Android 實體裝置不在本 PR 範圍',
    ]) {
      expect(baseline, contains(requirement));
    }
    expect(baseline, isNot(contains('瀏覽器程序重啟：通過')));
    expect(baseline, isNot(contains('iPhone 真機：通過')));
    expect(baseline, isNot(contains('Android 真機：通過')));
  });

  test('patch version matches the Web long-term validation baseline', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 0.5.36+37'));
  });
}
