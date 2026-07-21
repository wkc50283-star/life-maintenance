import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

typedef RuntimeDiagnosticReporter =
    void Function(String stage, Object error, StackTrace stackTrace);

final class RuntimeDiagnostics {
  const RuntimeDiagnostics._();

  @visibleForTesting
  static RuntimeDiagnosticReporter? testReporter;

  static Future<T> guard<T>(
    String stage,
    Future<T> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      report(stage: stage, error: error, stackTrace: stackTrace);
      rethrow;
    }
  }

  static void report({
    required String stage,
    required Object error,
    required StackTrace stackTrace,
  }) {
    final reporter = testReporter;
    if (reporter != null) {
      reporter(stage, error, stackTrace);
      return;
    }
    developer.log(
      'stage=$stage errorType=${error.runtimeType}',
      name: 'life_management_runtime',
      error: error,
      stackTrace: stackTrace,
    );
  }
}
