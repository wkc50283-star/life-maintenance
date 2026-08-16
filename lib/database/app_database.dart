import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../models/attachment.dart';
import '../models/maintenance_plan.dart';
import '../models/milestone.dart';
import '../models/item_system_category.dart';
import '../models/work_case.dart';
import '../models/work_case_closure.dart';
import '../models/work_case_enums.dart';
import '../models/work_case_update.dart';
import 'tables/attachments.dart';
import 'tables/future_matter_created_events.dart';
import 'tables/future_matter_change_event_snapshots.dart';
import 'tables/future_matter_change_events.dart';
import 'tables/future_matter_completed_events.dart';
import 'tables/future_matter_amendment_attachment_values.dart';
import 'tables/future_matter_amendment_events.dart';
import 'tables/future_matter_amendment_field_changes.dart';
import 'tables/future_matter_amendment_money_values.dart';
import 'tables/future_matter_amendment_related_people.dart';
import 'tables/future_matters.dart';
import 'tables/general_reminders.dart';
import 'tables/item_categories.dart';
import 'tables/item_custom_management_periods.dart';
import 'tables/item_lifecycle_event_custom_periods.dart';
import 'tables/item_lifecycle_event_periods.dart';
import 'tables/item_lifecycle_events.dart';
import 'tables/item_management_periods.dart';
import 'tables/item_management_period_change_event_custom_periods.dart';
import 'tables/item_management_period_change_event_periods.dart';
import 'tables/item_management_period_change_events.dart';
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

@DriftDatabase(
  tables: [
    ItemCategories,
    Items,
    ItemManagementPeriods,
    ItemCustomManagementPeriods,
    ItemLifecycleEvents,
    ItemLifecycleEventPeriods,
    ItemLifecycleEventCustomPeriods,
    ItemManagementPeriodChangeEvents,
    ItemManagementPeriodChangeEventPeriods,
    ItemManagementPeriodChangeEventCustomPeriods,
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
    FutureMatters,
    FutureMatterCreatedEvents,
    FutureMatterChangeEvents,
    FutureMatterChangeEventSnapshots,
    FutureMatterCompletedEvents,
    FutureMatterAmendmentEvents,
    FutureMatterAmendmentFieldChanges,
    FutureMatterAmendmentAttachmentValues,
    FutureMatterAmendmentRelatedPeople,
    FutureMatterAmendmentMoneyValues,
  ],
)
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
  int get schemaVersion => 11;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await _createAllIdempotently(migrator);
      await _createSchemaV4ImmutabilityTriggers();
      await _createSchemaV5ProtectionTriggers();
      await _createSchemaV6ProtectionTriggers();
      await _createSchemaV7ProtectionTriggers();
      await _createSchemaV8ProtectionTriggers();
      await _createSchemaV9ProtectionTriggers();
      await _createSchemaV10ProtectionTriggers();
      await _ensureUnclassifiedCategory();
    },
    onUpgrade: (migrator, from, to) async {
      if (from == 1 &&
          (to == 3 ||
              to == 4 ||
              to == 5 ||
              to == 6 ||
              to == 7 ||
              to == 8 ||
              to == 9 ||
              to == 10 ||
              to == 11)) {
        await customStatement('PRAGMA foreign_keys = OFF');
        await transaction(() async {
          await _migrateV1ToV2(migrator);
          if (to >= 4) {
            await _createSchemaV4ImmutabilityTriggers();
          }
          if (to >= 5) await _createSchemaV5ProtectionTriggers();
          if (to >= 6) await _createSchemaV6ProtectionTriggers();
          if (to >= 7) await _createSchemaV7ProtectionTriggers();
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _ensureUnclassifiedCategory();
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 2 &&
          (to == 3 ||
              to == 4 ||
              to == 5 ||
              to == 6 ||
              to == 7 ||
              to == 8 ||
              to == 9 ||
              to == 10 ||
              to == 11)) {
        await transaction(() async {
          await migrator.addColumn(workCases, workCases.sourceTaskId);
          await customStatement(
            'CREATE INDEX work_cases_source_task_idx '
            'ON work_cases (source_task_id)',
          );
          if (to >= 4) {
            await _createSchemaV4(migrator);
            await _createSchemaV4ImmutabilityTriggers();
            await _ensureUnclassifiedCategory();
          }
          if (to >= 5) {
            await _createSchemaV5(migrator);
            await _createSchemaV5ProtectionTriggers();
          }
          if (to >= 6) {
            await _createSchemaV6(migrator);
            await _createSchemaV6ProtectionTriggers();
          }
          if (to >= 7) {
            await _createSchemaV7(migrator);
            await _createSchemaV7ProtectionTriggers();
          }
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 3 &&
          (to == 4 ||
              to == 5 ||
              to == 6 ||
              to == 7 ||
              to == 8 ||
              to == 9 ||
              to == 10 ||
              to == 11)) {
        await transaction(() async {
          await _createSchemaV4(migrator);
          await _createSchemaV4ImmutabilityTriggers();
          if (to >= 5) {
            await _createSchemaV5(migrator);
            await _createSchemaV5ProtectionTriggers();
          }
          if (to >= 6) {
            await _createSchemaV6(migrator);
            await _createSchemaV6ProtectionTriggers();
          }
          if (to >= 7) {
            await _createSchemaV7(migrator);
            await _createSchemaV7ProtectionTriggers();
          }
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _ensureUnclassifiedCategory();
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 4 &&
          (to == 5 ||
              to == 6 ||
              to == 7 ||
              to == 8 ||
              to == 9 ||
              to == 10 ||
              to == 11)) {
        await transaction(() async {
          await _createSchemaV5(migrator);
          await _createSchemaV5ProtectionTriggers();
          if (to >= 6) {
            await _createSchemaV6(migrator);
            await _createSchemaV6ProtectionTriggers();
          }
          if (to >= 7) {
            await _createSchemaV7(migrator);
            await _createSchemaV7ProtectionTriggers();
          }
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 5 &&
          (to == 6 || to == 7 || to == 8 || to == 9 || to == 10 || to == 11)) {
        await transaction(() async {
          await _createSchemaV6(migrator);
          await _createSchemaV6ProtectionTriggers();
          if (to >= 7) {
            await _createSchemaV7(migrator);
            await _createSchemaV7ProtectionTriggers();
          }
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 6 &&
          (to == 7 || to == 8 || to == 9 || to == 10 || to == 11)) {
        await transaction(() async {
          await _createSchemaV7(migrator);
          await _createSchemaV7ProtectionTriggers();
          if (to >= 8) {
            await _createSchemaV8(migrator);
            await _createSchemaV8ProtectionTriggers();
          }
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 7 && (to == 8 || to == 9 || to == 10 || to == 11)) {
        await transaction(() async {
          await _createSchemaV8(migrator);
          await _createSchemaV8ProtectionTriggers();
          if (to >= 9) await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 8 && (to == 9 || to == 10 || to == 11)) {
        await transaction(() async {
          await _createSchemaV9(migrator);
          if (to >= 10) await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 9 && (to == 10 || to == 11)) {
        await transaction(() async {
          await _createSchemaV10(migrator);
          if (to == 11) await _createSchemaV11(migrator);
          await _throwIfForeignKeyViolations();
        });
        return;
      }
      if (from == 10 && to == 11) {
        await transaction(() async {
          await _createSchemaV11(migrator);
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

  Future<void> _createAllIdempotently(Migrator migrator) async {
    for (final table in allTables) {
      await migrator.createTable(table);
    }
    for (final index in allSchemaEntities.whereType<Index>()) {
      final statement = index.createStatementsByDialect[SqlDialect.sqlite];
      if (statement == null) {
        throw StateError('Missing SQLite definition for ${index.entityName}.');
      }
      final idempotentStatement = statement
          .replaceFirst(
            'CREATE UNIQUE INDEX ',
            'CREATE UNIQUE INDEX IF NOT EXISTS ',
          )
          .replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS ');
      if (idempotentStatement == statement) {
        throw StateError(
          'Unsupported SQLite index definition for ${index.entityName}.',
        );
      }
      await customStatement(idempotentStatement);
    }
  }

  Future<void> _createSchemaV4(Migrator migrator) async {
    await migrator.createTable(itemManagementPeriods);
    await migrator.createTable(itemLifecycleEvents);
    await migrator.createTable(itemLifecycleEventPeriods);
    final index = allSchemaEntities.whereType<Index>().singleWhere(
      (entity) =>
          entity.entityName == 'item_lifecycle_events_item_type_unique_idx',
    );
    final statement = index.createStatementsByDialect[SqlDialect.sqlite];
    if (statement == null) {
      throw StateError('Missing SQLite definition for ${index.entityName}.');
    }
    await customStatement(statement);
  }

  Future<void> _createSchemaV5(Migrator migrator) async {
    await migrator.createTable(itemCustomManagementPeriods);
    await migrator.createTable(itemLifecycleEventCustomPeriods);
  }

  Future<void> _createSchemaV6(Migrator migrator) async {
    await migrator.createTable(itemManagementPeriodChangeEvents);
    await migrator.createTable(itemManagementPeriodChangeEventPeriods);
    await migrator.createTable(itemManagementPeriodChangeEventCustomPeriods);
  }

  Future<void> _createSchemaV7(Migrator migrator) async {
    await migrator.createTable(futureMatters);
    await migrator.createTable(futureMatterCreatedEvents);
    for (final name in const [
      'future_matters_item_idx',
      'future_matters_timing_mode_idx',
      'future_matter_created_events_matter_unique_idx',
      'future_matter_created_events_item_idx',
    ]) {
      final index = allSchemaEntities.whereType<Index>().singleWhere(
        (entity) => entity.entityName == name,
      );
      final statement = index.createStatementsByDialect[SqlDialect.sqlite];
      if (statement == null) {
        throw StateError('Missing SQLite definition for ${index.entityName}.');
      }
      final idempotentStatement = statement
          .replaceFirst(
            'CREATE UNIQUE INDEX ',
            'CREATE UNIQUE INDEX IF NOT EXISTS ',
          )
          .replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS ');
      await customStatement(idempotentStatement);
    }
  }

  Future<void> _createSchemaV8(Migrator migrator) async {
    await migrator.createTable(futureMatterChangeEvents);
    await migrator.createTable(futureMatterChangeEventSnapshots);
    for (final name in const [
      'future_matter_change_events_matter_idx',
      'future_matter_change_event_snapshots_item_idx',
    ]) {
      final index = allSchemaEntities.whereType<Index>().singleWhere(
        (entity) => entity.entityName == name,
      );
      final statement = index.createStatementsByDialect[SqlDialect.sqlite];
      if (statement == null) {
        throw StateError('Missing SQLite definition for ${index.entityName}.');
      }
      await customStatement(
        statement.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
      );
    }
  }

  Future<void> _createSchemaV8ProtectionTriggers() async {
    for (final table in const [
      'future_matter_change_events',
      'future_matter_change_event_snapshots',
    ]) {
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_update
        BEFORE UPDATE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Future matter change history is immutable');
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_delete
        BEFORE DELETE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Future matter change history is immutable');
        END
      ''');
    }
  }

  Future<void> _createSchemaV9(Migrator migrator) async {
    final futureMatterColumns = await customSelect(
      "PRAGMA table_info('future_matters')",
    ).get();
    if (!futureMatterColumns.any(
      (row) => row.data['name'] == 'lifecycle_status',
    )) {
      await migrator.addColumn(futureMatters, futureMatters.lifecycleStatus);
    }
    final completedTable = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' "
      "AND name = 'future_matter_completed_events'",
    ).getSingleOrNull();
    if (completedTable == null) {
      await migrator.createTable(futureMatterCompletedEvents);
    }
    for (final name in const [
      'future_matter_completed_events_matter_unique_idx',
      'future_matter_completed_events_item_idx',
    ]) {
      final index = allSchemaEntities.whereType<Index>().singleWhere(
        (entity) => entity.entityName == name,
      );
      final statement = index.createStatementsByDialect[SqlDialect.sqlite];
      if (statement == null) {
        throw StateError('Missing SQLite definition for ${index.entityName}.');
      }
      await customStatement(
        statement
            .replaceFirst(
              'CREATE UNIQUE INDEX ',
              'CREATE UNIQUE INDEX IF NOT EXISTS ',
            )
            .replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
      );
    }
    await _createSchemaV9ProtectionTriggers();
  }

  Future<void> _createSchemaV9ProtectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matter_completed_events_no_update
      BEFORE UPDATE ON future_matter_completed_events
      BEGIN
        SELECT RAISE(ABORT, 'Future matter completion history is immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matter_completed_events_no_delete
      BEFORE DELETE ON future_matter_completed_events
      BEGIN
        SELECT RAISE(ABORT, 'Future matter completion history is immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matters_completed_no_update
      BEFORE UPDATE ON future_matters
      WHEN OLD.lifecycle_status = 'completed'
      BEGIN
        SELECT RAISE(ABORT, 'Completed future matters are immutable');
      END
    ''');
  }

  Future<void> _createSchemaV10(Migrator migrator) async {
    final columns = await customSelect(
      "PRAGMA table_info('future_matters')",
    ).get();
    final names = columns.map((row) => row.data['name']).toSet();
    if (!names.contains('created_source')) {
      await migrator.addColumn(futureMatters, futureMatters.createdSource);
      await migrator.addColumn(
        futureMatters,
        futureMatters.createdSourceReferenceKind,
      );
      await migrator.addColumn(
        futureMatters,
        futureMatters.createdSourceReferenceId,
      );
    }
    await migrator.createTable(futureMatterAmendmentEvents);
    await migrator.createTable(futureMatterAmendmentFieldChanges);
    await migrator.createTable(futureMatterAmendmentAttachmentValues);
    await migrator.createTable(futureMatterAmendmentRelatedPeople);
    await migrator.createTable(futureMatterAmendmentMoneyValues);
    for (final name in const [
      'future_matter_amendment_events_matter_order_idx',
      'future_matter_amendment_events_target_idx',
      'future_matter_amendment_events_source_reference_idx',
    ]) {
      final index = allSchemaEntities.whereType<Index>().singleWhere(
        (entity) => entity.entityName == name,
      );
      final statement = index.createStatementsByDialect[SqlDialect.sqlite];
      if (statement == null) {
        throw StateError('Missing SQLite definition for ${index.entityName}.');
      }
      await customStatement(
        statement.replaceFirst('CREATE INDEX ', 'CREATE INDEX IF NOT EXISTS '),
      );
    }
    await _createSchemaV10ProtectionTriggers();
  }

  Future<void> _createSchemaV11(Migrator migrator) async {
    final existing = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' AND name = 'work_cases'",
    ).get();
    if (existing.isEmpty) return;
    await migrator.alterTable(TableMigration(workCases));
  }

  Future<void> _createSchemaV10ProtectionTriggers() async {
    for (final table in const [
      'future_matter_amendment_events',
      'future_matter_amendment_field_changes',
      'future_matter_amendment_attachment_values',
      'future_matter_amendment_related_people',
      'future_matter_amendment_money_values',
    ]) {
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_update
        BEFORE UPDATE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Future matter amendment history is immutable');
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_delete
        BEFORE DELETE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Future matter amendment history is immutable');
        END
      ''');
    }
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matters_created_provenance_validate_insert
      BEFORE INSERT ON future_matters
      WHEN (NEW.created_source IS NOT NULL AND NEW.created_source NOT IN ('manual', 'ai', 'backfill', 'system'))
        OR ((NEW.created_source_reference_kind IS NULL) <> (NEW.created_source_reference_id IS NULL))
        OR (NEW.created_source_reference_kind IS NOT NULL AND NEW.created_source_reference_kind NOT IN ('futureMatterCreatedEvent', 'futureMatterChangeEvent', 'futureMatterCompletedEvent', 'futureMatterAmendmentEvent', 'maintenanceRecord'))
        OR (NEW.created_source_reference_id IS NOT NULL AND trim(NEW.created_source_reference_id) = '')
      BEGIN
        SELECT RAISE(ABORT, 'Invalid future matter created provenance');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matters_created_provenance_validate_update
      BEFORE UPDATE ON future_matters
      WHEN (NEW.created_source IS NOT NULL AND NEW.created_source NOT IN ('manual', 'ai', 'backfill', 'system'))
        OR ((NEW.created_source_reference_kind IS NULL) <> (NEW.created_source_reference_id IS NULL))
        OR (NEW.created_source_reference_kind IS NOT NULL AND NEW.created_source_reference_kind NOT IN ('futureMatterCreatedEvent', 'futureMatterChangeEvent', 'futureMatterCompletedEvent', 'futureMatterAmendmentEvent', 'maintenanceRecord'))
        OR (NEW.created_source_reference_id IS NOT NULL AND trim(NEW.created_source_reference_id) = '')
      BEGIN
        SELECT RAISE(ABORT, 'Invalid future matter created provenance');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matters_created_provenance_no_update
      BEFORE UPDATE OF created_source, created_source_reference_kind,
        created_source_reference_id ON future_matters
      WHEN OLD.created_source IS NOT NEW.created_source
        OR OLD.created_source_reference_kind IS NOT NEW.created_source_reference_kind
        OR OLD.created_source_reference_id IS NOT NEW.created_source_reference_id
      BEGIN
        SELECT RAISE(ABORT, 'Future matter created provenance is immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matter_amendment_field_changes_validate_insert
      BEFORE INSERT ON future_matter_amendment_field_changes
      WHEN (
        (SELECT event_type FROM future_matter_amendment_events WHERE id = NEW.event_id) = 'supplement'
        AND NOT (NEW.old_state = 'absent' AND NEW.new_state = 'value')
      ) OR (
        (SELECT event_type FROM future_matter_amendment_events WHERE id = NEW.event_id) = 'correction'
        AND NOT (NEW.old_state = 'value' AND NEW.new_state IN ('value', 'null'))
      ) OR (
        NEW.value_type IN ('futureMatterDate', 'text')
        AND ((NEW.old_state = 'value') <> (NEW.old_text_value IS NOT NULL)
          OR (NEW.new_state = 'value') <> (NEW.new_text_value IS NOT NULL))
      ) OR (
        NEW.value_type = 'minuteOfDay'
        AND ((NEW.old_state = 'value') <> (NEW.old_integer_value IS NOT NULL)
          OR (NEW.new_state = 'value') <> (NEW.new_integer_value IS NOT NULL))
      ) OR (
        NEW.value_type IN ('attachmentCollection', 'money', 'relatedPeopleCollection')
        AND (NEW.old_text_value IS NOT NULL OR NEW.new_text_value IS NOT NULL
          OR NEW.old_integer_value IS NOT NULL OR NEW.new_integer_value IS NOT NULL)
      )
      BEGIN
        SELECT RAISE(ABORT, 'Invalid future matter amendment field change');
      END
    ''');
  }

  Future<void> _createSchemaV7ProtectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matter_created_events_no_update
      BEFORE UPDATE ON future_matter_created_events
      BEGIN
        SELECT RAISE(ABORT, 'Future matter created history is immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS future_matter_created_events_no_delete
      BEFORE DELETE ON future_matter_created_events
      BEGIN
        SELECT RAISE(ABORT, 'Future matter created history is immutable');
      END
    ''');
  }

  Future<void> _createSchemaV6ProtectionTriggers() async {
    for (final table in const [
      'item_management_period_change_events',
      'item_management_period_change_event_periods',
      'item_management_period_change_event_custom_periods',
    ]) {
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_update
        BEFORE UPDATE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Management period change history is immutable');
        END
      ''');
      await customStatement('''
        CREATE TRIGGER IF NOT EXISTS ${table}_no_delete
        BEFORE DELETE ON $table
        BEGIN
          SELECT RAISE(ABORT, 'Management period change history is immutable');
        END
      ''');
    }
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_management_period_change_event_custom_periods_no_fixed_equivalent
      BEFORE INSERT ON item_management_period_change_event_custom_periods
      WHEN EXISTS (
        SELECT 1 FROM item_management_period_change_event_periods fixed
        WHERE fixed.event_id = NEW.event_id
          AND fixed.snapshot_side = NEW.snapshot_side
          AND (
            (NEW.canonical_family = 'day' AND NEW.canonical_value =
              CASE fixed.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (NEW.canonical_family = 'calendarMonth' AND NEW.canonical_value =
              CASE fixed.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent change snapshot period already exists');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_management_period_change_event_periods_no_custom_equivalent
      BEFORE INSERT ON item_management_period_change_event_periods
      WHEN EXISTS (
        SELECT 1 FROM item_management_period_change_event_custom_periods custom
        WHERE custom.event_id = NEW.event_id
          AND custom.snapshot_side = NEW.snapshot_side
          AND (
            (custom.canonical_family = 'day' AND custom.canonical_value =
              CASE NEW.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (custom.canonical_family = 'calendarMonth' AND custom.canonical_value =
              CASE NEW.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent change snapshot period already exists');
      END
    ''');
  }

  Future<void> _createSchemaV4ImmutabilityTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_events_no_update
      BEFORE UPDATE ON item_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle events are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_events_no_delete
      BEFORE DELETE ON item_lifecycle_events
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle events are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_periods_no_update
      BEFORE UPDATE ON item_lifecycle_event_periods
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle event periods are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_periods_no_delete
      BEFORE DELETE ON item_lifecycle_event_periods
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle event periods are immutable');
      END
    ''');
  }

  Future<void> _createSchemaV5ProtectionTriggers() async {
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_custom_management_periods_no_fixed_equivalent
      BEFORE INSERT ON item_custom_management_periods
      WHEN EXISTS (
        SELECT 1 FROM item_management_periods fixed
        WHERE fixed.item_id = NEW.item_id
          AND (
            (NEW.canonical_family = 'day' AND NEW.canonical_value =
              CASE fixed.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (NEW.canonical_family = 'calendarMonth' AND NEW.canonical_value =
              CASE fixed.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent management period already exists');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_management_periods_no_custom_equivalent
      BEFORE INSERT ON item_management_periods
      WHEN EXISTS (
        SELECT 1 FROM item_custom_management_periods custom
        WHERE custom.item_id = NEW.item_id
          AND (
            (custom.canonical_family = 'day' AND custom.canonical_value =
              CASE NEW.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (custom.canonical_family = 'calendarMonth' AND custom.canonical_value =
              CASE NEW.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent management period already exists');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_custom_periods_no_fixed_equivalent
      BEFORE INSERT ON item_lifecycle_event_custom_periods
      WHEN EXISTS (
        SELECT 1 FROM item_lifecycle_event_periods fixed
        WHERE fixed.event_id = NEW.event_id
          AND (
            (NEW.canonical_family = 'day' AND NEW.canonical_value =
              CASE fixed.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (NEW.canonical_family = 'calendarMonth' AND NEW.canonical_value =
              CASE fixed.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent lifecycle period already exists');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_periods_no_custom_equivalent
      BEFORE INSERT ON item_lifecycle_event_periods
      WHEN EXISTS (
        SELECT 1 FROM item_lifecycle_event_custom_periods custom
        WHERE custom.event_id = NEW.event_id
          AND (
            (custom.canonical_family = 'day' AND custom.canonical_value =
              CASE NEW.period WHEN 'day' THEN 1 WHEN 'week' THEN 7 ELSE -1 END)
            OR
            (custom.canonical_family = 'calendarMonth' AND custom.canonical_value =
              CASE NEW.period WHEN 'month' THEN 1 WHEN 'quarter' THEN 3
                WHEN 'halfYear' THEN 6 WHEN 'year' THEN 12 ELSE -1 END)
          )
      )
      BEGIN
        SELECT RAISE(ABORT, 'Equivalent lifecycle period already exists');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_custom_periods_no_update
      BEFORE UPDATE ON item_lifecycle_event_custom_periods
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle event custom periods are immutable');
      END
    ''');
    await customStatement('''
      CREATE TRIGGER IF NOT EXISTS item_lifecycle_event_custom_periods_no_delete
      BEFORE DELETE ON item_lifecycle_event_custom_periods
      BEGIN
        SELECT RAISE(ABORT, 'Item lifecycle event custom periods are immutable');
      END
    ''');
  }

  Future<void> _ensureUnclassifiedCategory() async {
    final categoryTable = await customSelect(
      "SELECT 1 FROM sqlite_master WHERE type = 'table' "
      "AND name = 'item_categories'",
    ).getSingleOrNull();
    if (categoryTable == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    await into(itemCategories).insert(
      ItemCategoriesCompanion.insert(
        id: ItemSystemCategory.unclassifiedId,
        systemCode: const Value(ItemSystemCategory.unclassifiedCode),
        displayName: ItemSystemCategory.unclassifiedDisplayName,
        sortOrder: const Value(-1000),
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
      mode: InsertMode.insertOrIgnore,
    );
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
