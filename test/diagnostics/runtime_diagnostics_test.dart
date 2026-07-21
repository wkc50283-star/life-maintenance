import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/diagnostics/runtime_diagnostics.dart';

void main() {
  test('guard reports the exact runtime stage and rethrows', () async {
    String? capturedStage;
    Object? capturedError;
    StackTrace? capturedStack;
    RuntimeDiagnostics.testReporter = (stage, error, stackTrace) {
      capturedStage = stage;
      capturedError = error;
      capturedStack = stackTrace;
    };
    addTearDown(() => RuntimeDiagnostics.testReporter = null);

    await expectLater(
      RuntimeDiagnostics.guard<void>(
        'home_overview.items.load',
        () => throw StateError('diagnostic failure'),
      ),
      throwsStateError,
    );

    expect(capturedStage, 'home_overview.items.load');
    expect(capturedError, isA<StateError>());
    expect(capturedStack, isNotNull);
  });
}
