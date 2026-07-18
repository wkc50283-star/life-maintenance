import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/services/local_storage_service.dart';

void main() {
  test(
    'constructs one database, Drift repository set, and runtime services',
    () async {
      final database = AppDatabase(NativeDatabase.memory());
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: LocalStorageService(),
      );

      expect(root.database, same(database));
      expect(root.driftRepositories.items, isNotNull);
      expect(root.driftRepositories.tasks, isNotNull);
      expect(root.driftRepositories.workCases, isNotNull);
      expect(root.driftRepositories.workCaseClosures, isNotNull);
      expect(root.itemRepository, isNotNull);
      expect(root.localDataBackupService, isNotNull);
      expect(root.maintenanceTaskService, isNotNull);
      await database.close();
    },
  );

  testWidgets('scope exposes the injected root', (tester) async {
    final root = AppCompositionRoot(
      database: AppDatabase(NativeDatabase.memory()),
      legacyStorage: LocalStorageService(),
    );
    late AppRuntimeDependencies resolved;

    await tester.pumpWidget(
      AppCompositionScope(
        root: root,
        child: Builder(
          builder: (context) {
            resolved = AppCompositionScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(resolved, same(root));
    await root.database.close();
  });
}
