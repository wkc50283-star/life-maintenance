import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/diagnostics/runtime_diagnostics.dart';

void main() {
  test('guard reports the exact runtime stage and rethrows', () async {
    final originalHandler = FlutterError.onError;
    FlutterErrorDetails? captured;
    FlutterError.onError = (details) => captured = details;
    addTearDown(() => FlutterError.onError = originalHandler);

    await expectLater(
      RuntimeDiagnostics.guard<void>(
        'home_overview.items.load',
        () => throw StateError('diagnostic failure'),
      ),
      throwsStateError,
    );

    expect(captured?.library, 'life_management_runtime');
    expect(
      captured?.context.toString(),
      'while running home_overview.items.load',
    );
    expect(captured?.exception, isA<StateError>());
    expect(captured?.stack, isNotNull);
  });
}
