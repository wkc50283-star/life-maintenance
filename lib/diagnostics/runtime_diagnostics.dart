import 'package:flutter/foundation.dart';

final class RuntimeDiagnostics {
  const RuntimeDiagnostics._();

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
    FlutterError.reportError(
      FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        library: 'life_management_runtime',
        context: ErrorDescription('while running $stage'),
      ),
    );
  }
}
