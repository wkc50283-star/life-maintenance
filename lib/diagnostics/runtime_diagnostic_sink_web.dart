import 'dart:js_interop';

@JS('console.error')
external void _consoleError(JSString message);

void emitRuntimeDiagnostic(String message) {
  _consoleError(message.toJS);
}
