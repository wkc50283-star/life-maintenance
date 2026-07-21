import 'dart:developer' as developer;

void emitRuntimeDiagnostic(String message) {
  developer.log(message, name: 'life_management_runtime');
}
