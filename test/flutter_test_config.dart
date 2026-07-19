import 'dart:async';

import 'package:life_maintenance/app/app_composition_root.dart';

import 'support/test_runtime_dependencies.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppCompositionScope.testDependencies = TestRuntimeDependencies();
  await testMain();
}
