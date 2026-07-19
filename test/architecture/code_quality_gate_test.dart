import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('production Dart has no unresolved quality markers', () {
    final violations = <String>[];
    for (final file in _dartFiles('lib')) {
      if (file.path.endsWith('app_database.g.dart')) continue;
      final source = file.readAsStringSync();
      for (final marker in const ['TODO', 'FIXME', 'HACK', 'DEBUG']) {
        if (source.contains(marker)) {
          violations.add('${_relative(file.path)}: $marker');
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('retired safe-read-only transition adapter stays removed', () {
    expect(
      File(
        'lib/repositories/drift/drift_safe_read_only_runtime.dart',
      ).existsSync(),
      isFalse,
    );
  });
}

List<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);

String _relative(String path) =>
    path.replaceFirst('${Directory.current.path}/', '');
