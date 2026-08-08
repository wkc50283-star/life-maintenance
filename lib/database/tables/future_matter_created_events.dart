import 'package:drift/drift.dart';

import 'future_matters.dart';

@DataClassName('FutureMatterCreatedEventRow')
@TableIndex(
  name: 'future_matter_created_events_matter_unique_idx',
  columns: {#futureMatterId},
  unique: true,
)
@TableIndex(
  name: 'future_matter_created_events_item_idx',
  columns: {#itemIdSnapshot},
)
class FutureMatterCreatedEvents extends Table {
  TextColumn get id => text()();
  TextColumn get futureMatterId => text().references(
    FutureMatters,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get titleSnapshot => text()();
  TextColumn get itemIdSnapshot => text().nullable()();
  TextColumn get timingModeSnapshot => text()();
  TextColumn get specifiedDateSnapshot => text().nullable()();
  IntColumn get specifiedMinuteOfDaySnapshot => integer().nullable()();
  IntColumn get recurringIntervalValueSnapshot => integer().nullable()();
  TextColumn get recurringIntervalUnitSnapshot => text().nullable()();
  TextColumn get recurringAnchorDateSnapshot => text().nullable()();
  IntColumn get recurringAnchorMinuteOfDaySnapshot => integer().nullable()();
  TextColumn get conditionTypeSnapshot => text().nullable()();
  TextColumn get conditionMaintenanceRecordIdSnapshot => text().nullable()();
  IntColumn get conditionDelayValueSnapshot => integer().nullable()();
  TextColumn get conditionDelayUnitSnapshot => text().nullable()();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title_snapshot) <> '')",
    "CHECK (timing_mode_snapshot IN ('later', 'specifiedDate', 'recurring', 'condition'))",
    'CHECK (specified_minute_of_day_snapshot IS NULL OR specified_minute_of_day_snapshot BETWEEN 0 AND 1439)',
    'CHECK (recurring_anchor_minute_of_day_snapshot IS NULL OR recurring_anchor_minute_of_day_snapshot BETWEEN 0 AND 1439)',
    'CHECK (recurring_anchor_minute_of_day_snapshot IS NULL OR recurring_anchor_date_snapshot IS NOT NULL)',
    "CHECK (specified_date_snapshot IS NULL OR (length(specified_date_snapshot) = 10 AND specified_date_snapshot GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(specified_date_snapshot, '+0 days') = specified_date_snapshot))",
    "CHECK (recurring_anchor_date_snapshot IS NULL OR (length(recurring_anchor_date_snapshot) = 10 AND recurring_anchor_date_snapshot GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(recurring_anchor_date_snapshot, '+0 days') = recurring_anchor_date_snapshot))",
    "CHECK (recurring_interval_unit_snapshot IS NULL OR recurring_interval_unit_snapshot IN ('minute', 'hour', 'day', 'week', 'month', 'year'))",
    "CHECK (condition_delay_unit_snapshot IS NULL OR condition_delay_unit_snapshot IN ('minute', 'hour', 'day', 'week', 'month', 'year'))",
    "CHECK (condition_type_snapshot IS NULL OR condition_type_snapshot = 'afterFormalCompletion')",
    'CHECK (recurring_interval_value_snapshot IS NULL OR recurring_interval_value_snapshot > 0)',
    'CHECK (condition_delay_value_snapshot IS NULL OR condition_delay_value_snapshot > 0)',
    "CHECK ((timing_mode_snapshot = 'later' AND specified_date_snapshot IS NULL AND specified_minute_of_day_snapshot IS NULL AND recurring_interval_value_snapshot IS NULL AND recurring_interval_unit_snapshot IS NULL AND recurring_anchor_date_snapshot IS NULL AND recurring_anchor_minute_of_day_snapshot IS NULL AND condition_type_snapshot IS NULL AND condition_maintenance_record_id_snapshot IS NULL AND condition_delay_value_snapshot IS NULL AND condition_delay_unit_snapshot IS NULL) OR (timing_mode_snapshot = 'specifiedDate' AND specified_date_snapshot IS NOT NULL AND recurring_interval_value_snapshot IS NULL AND recurring_interval_unit_snapshot IS NULL AND recurring_anchor_date_snapshot IS NULL AND recurring_anchor_minute_of_day_snapshot IS NULL AND condition_type_snapshot IS NULL AND condition_maintenance_record_id_snapshot IS NULL AND condition_delay_value_snapshot IS NULL AND condition_delay_unit_snapshot IS NULL) OR (timing_mode_snapshot = 'recurring' AND specified_date_snapshot IS NULL AND specified_minute_of_day_snapshot IS NULL AND recurring_interval_value_snapshot IS NOT NULL AND recurring_interval_unit_snapshot IS NOT NULL AND condition_type_snapshot IS NULL AND condition_maintenance_record_id_snapshot IS NULL AND condition_delay_value_snapshot IS NULL AND condition_delay_unit_snapshot IS NULL) OR (timing_mode_snapshot = 'condition' AND specified_date_snapshot IS NULL AND specified_minute_of_day_snapshot IS NULL AND recurring_interval_value_snapshot IS NULL AND recurring_interval_unit_snapshot IS NULL AND recurring_anchor_date_snapshot IS NULL AND recurring_anchor_minute_of_day_snapshot IS NULL AND condition_type_snapshot = 'afterFormalCompletion' AND condition_maintenance_record_id_snapshot IS NOT NULL AND condition_delay_value_snapshot IS NOT NULL AND condition_delay_unit_snapshot IS NOT NULL))",
  ];
}
