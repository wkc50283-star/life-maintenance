import 'dart:async';

import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/services/local_storage_service.dart';

Future<void> testExecutable(FutureOr<void> Function() testMain) async {
  AppCompositionScope.testDependencies = LegacyRuntimeDependencies(
    LocalStorageService(),
  );
  await testMain();
}
