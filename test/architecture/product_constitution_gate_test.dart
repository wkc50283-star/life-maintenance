import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('formal UI stays free of pressure and performance language', () {
    final violations = <String>[];
    for (final file in _formalUiFiles()) {
      final source = file.readAsStringSync();
      for (final phrase in const [
        '完成率',
        '達成率',
        '連續打卡',
        'KPI',
        '績效',
        '評分',
        '今天要處理',
        '已逾期',
        '尚未達標',
        '已達標',
      ]) {
        if (source.contains(phrase)) {
          violations.add('${file.path}: $phrase');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('formal Task card cannot expose a direct completion action', () {
    final source = File('lib/widgets/task_card.dart').readAsStringSync();

    expect(source, isNot(contains('onComplete')));
    expect(source, isNot(contains("Text('完成')")));
  });
}

List<File> _formalUiFiles() => [
  ...Directory(
    'lib/app',
  ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
  ...Directory(
    'lib/screens',
  ).listSync().whereType<File>().where((file) => file.path.endsWith('.dart')),
  for (final path in const [
    'lib/widgets/today_hero.dart',
    'lib/widgets/task_card.dart',
    'lib/widgets/history_header.dart',
    'lib/widgets/empty_history_state.dart',
    'lib/widgets/settings_header.dart',
    'lib/widgets/demo_data_notice.dart',
  ])
    File(path),
];
