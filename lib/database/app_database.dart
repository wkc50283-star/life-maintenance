import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/attachment.dart';
import '../models/maintenance_plan.dart';
import '../models/milestone.dart';
import '../models/work_case.dart';
import '../models/work_case_closure.dart';
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
          final existingSchema = await _existingSchemaState();
          if (existingSchema == _ExistingSchemaState.complete) {
            return;
          }
          if (existingSchema == _ExistingSchemaState.partial) {
            throw StateError(
              'Database creation found an incomplete existing formal schema.',
            );
          }
          await migrator.createAll();
        },
        onUpgrade: (migrator, from, to) async {
          if (from == 1 && to == 2) {
            await customStatement('PRAGMA foreign_keys = OFF');
            await transaction(() async {
              await _migrateV1ToV2(migrator);
              await _throwIfForeignKeyViolations();
            });
            return;
          }
          throw UnsupportedError(
            'Unsupported database migration: schema $from to $to.',
          );
        },
        beforeOpen: (details) async {
          await customStatement('PRAGMA foreign_keys = ON');
          final versionBefore = details.versionBefore;
          final versionNow = details.versionNow;
          if (versionBefore != null && versionBefore < versionNow) {
            await _throwIfForeignKeyViolations();
          }
        },
      );

  Future<_ExistingSchemaState> _existingSchemaState() async {
    final rows = await customSelect(
      "SELECT type, name FROM sqlite_master "
      "WHERE type IN ('table', 'index') AND name NOT LIKE 'sqlite_%'",
    ).get();
    final existingTables = <String>{};
    final existingIndexes = <String>{};
    for (final row in rows) {
      final type = row.read<String>('type');
      final name = row.read<String>('name');
      if (type == 'table') {
        existingTables.add(name);
      } else if (type == 'index') {
        existingIndexes.add(name);
      }
    }

    final requiredTables = allTables.map((table) => table.entityName).toSet();
    final requiredIndexes = allSchemaEntities
        .whereType<Index>()
        .map((index) => index.entityName)
        .toSet();
    final knownTables = existingTables.intersection(requiredTables);
    final knownIndexes = existingIndexes.intersection(requiredIndexes);
    if (knownTables.isEmpty && knownIndexes.isEmpty) {
      return _ExistingSchemaState.empty;
    }
    if (existingTables.containsAll(requiredTables) &&
        existingIndexes.containsAll(requiredIndexes)) {
      return _ExistingSchemaState.complete;
    }
    return _ExistingSchemaState.partial;
  }

  Future<void> _migrateV1ToV2(Migrator migrator) async {
    await customStatement(
      'ALTER TABLE work_case_updates RENAME TO legacy_work_case_updates_v1',
    );
    await customStatement(
      'ALTER TABLE work_cases RENAME TO legacy_work_cases_v1',
    );

    await customStatement(
      'DROP INDEX IF EXISTS work_case_updates_case_occurred_idx',
    );
    await customStatement('DROP INDEX IF EXISTS work_cases_item_status_idx');
    await customStatement('DROP INDEX IF EXISTS work_cases_source_idx');
    await customStatement('DROP INDEX IF EXISTS work_cases_updated_at_idx');

    await migrator.createAll();

    const legacyCategoryId = 'system-category-legacy-imported';
    const nowTimestamp = "strftime('%Y-%m-%dT%H:%M:%fZ', 'now')";

    await customStatement('''
      INSERT INTO item_categories (
        id, system_code, custom_name, display_name, sort_order,
        status, created_at, updated_at, archived_at
      ) VALUES (
        '$legacyCategoryId', 'legacyImported', NULL, '舊資料匯入', 999,
        'active', $nowTimestamp, $nowTimestamp, NULL
      )
    ''');

    await customStatement('''
      INSERT INTO items (
        id, name, category_id, created_at, updated_at,
        purchase_date, warranty_end_date, expected_life_years,
        location, note, status, archived_at
      )
      SELECT
        item_id,
        '舊資料項目 ' || item_id,
        '$legacyCategoryId',
        MIN(created_at),
        MAX(updated_at),
        NULL, NULL, NULL, NULL,
        '由 schema v1 案件資料自動建立；名稱可由使用者後續修正。',
        'active', NULL
      FROM legacy_work_cases_v1
      GROUP BY item_id
    ''');

    await customStatement('''
      INSERT INTO work_cases (
        schema_version, id, item_id, source_type, source_id, case_type,
        title, description, occurred_at, started_at, status,
        created_at, updated_at, closed_at, canceled_at,
        close_result, cancellation_reason
      )
      SELECT
        schema_version, id, item_id, source_type, source_id, case_type,
        title, description, occurred_at, started_at, status,
        created_at, updated_at, closed_at,
        CASE WHEN status = 'canceled' THEN closed_at ELSE NULL END,
        close_result, cancellation_reason
      FROM legacy_work_cases_v1
    ''');

    await customStatement('''
      INSERT INTO work_case_updates (
        schema_version, id, work_case_id, occurred_at, description,
        contact_or_vendor, result, cost, parts_or_items,
        photo_identifiers, waiting_reason, note, next_action, created_at
      )
      SELECT
        schema_version, id, work_case_id, occurred_at, description,
        contact_or_vendor, result, cost, parts_or_items,
        photo_identifiers, waiting_reason, note, next_action, created_at
      FROM legacy_work_case_updates_v1
    ''');

    await customStatement('DROP TABLE legacy_work_case_updates_v1');
    await customStatement('DROP TABLE legacy_work_cases_v1');
  }

  Future<void> _throwIfForeignKeyViolations() async {
    final violations = await customSelect('PRAGMA foreign_key_check').get();
    if (violations.isNotEmpty) {
      throw StateError(
        'Database migration produced '
        '${violations.length} foreign-key violations.',
      );
    }
  }
}

enum _ExistingSchemaState { empty, complete, partial }
