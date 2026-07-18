import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/work_case.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';
import 'tables/attachments.dart';
import 'tables/general_reminders.dart';
import 'tables/item_categories.dart';
import 'tables/items.dart';
import 'tables/maintenance_plan_steps.dart';
import 'tables/maintenance_plans.dart';
import 'tables/maintenance_records.dart';
import 'tables/milestones.dart';
import 'tables/schedules.dart';
import 'tables/tasks.dart';
import 'tables/work_case_closures.dart';
import 'tables/work_case_updates.dart';
import 'tables/work_cases.dart';
import 'type_converters.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  ItemCategories,
  Items,
  MaintenancePlans,
  MaintenancePlanSteps,
  GeneralReminders,
  Milestones,
  Schedules,
  Tasks,
  MaintenanceRecords,
  WorkCases,
  WorkCaseUpdates,
  WorkCaseClosures,
  Attachments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.executor);

  AppDatabase.defaults()
      : super(
          driftDatabase(
            name: 'life_maintenance',
            native: const DriftNativeOptions(shareAcrossIsolates: true),
            web: DriftWebOptions(
              sqlite3Wasm: Uri.parse('sqlite3.wasm'),
              driftWorker: Uri.parse('drift_worker.dart.js'),
            ),
          ),
        );

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          throw UnsupportedError(
            'Schema v1 to v2 migration is intentionally blocked until the dedicated migration PR is approved.',
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
        },
      );
}
