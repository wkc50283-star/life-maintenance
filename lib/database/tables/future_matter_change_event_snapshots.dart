import 'package:drift/drift.dart';

import 'future_matter_change_events.dart';

@DataClassName('FutureMatterChangeEventSnapshotRow')
@TableIndex(
  name: 'future_matter_change_event_snapshots_item_idx',
  columns: {#itemId},
)
class FutureMatterChangeEventSnapshots extends Table {
  TextColumn get eventId => text().references(
    FutureMatterChangeEvents,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get snapshotSide => text()();
  TextColumn get title => text()();
  TextColumn get itemId => text().nullable()();
  TextColumn get timingMode => text()();
  TextColumn get specifiedDate => text().nullable()();
  IntColumn get specifiedMinuteOfDay => integer().nullable()();
  IntColumn get recurringIntervalValue => integer().nullable()();
  TextColumn get recurringIntervalUnit => text().nullable()();
  TextColumn get recurringAnchorDate => text().nullable()();
  IntColumn get recurringAnchorMinuteOfDay => integer().nullable()();
  TextColumn get conditionType => text().nullable()();
  TextColumn get conditionMaintenanceRecordId => text().nullable()();
  IntColumn get conditionDelayValue => integer().nullable()();
  TextColumn get conditionDelayUnit => text().nullable()();
  DateTimeColumn get futureMatterCreatedAt => dateTime()();
  DateTimeColumn get futureMatterUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, snapshotSide};

  @override
  List<String> get customConstraints => [
    "CHECK (snapshot_side IN ('before', 'after'))",
    "CHECK (trim(title) <> '')",
    "CHECK (timing_mode IN ('later', 'specifiedDate', 'recurring', 'condition'))",
    'CHECK (specified_minute_of_day IS NULL OR specified_minute_of_day BETWEEN 0 AND 1439)',
    'CHECK (recurring_anchor_minute_of_day IS NULL OR recurring_anchor_minute_of_day BETWEEN 0 AND 1439)',
    'CHECK (recurring_anchor_minute_of_day IS NULL OR recurring_anchor_date IS NOT NULL)',
    "CHECK (specified_date IS NULL OR (length(specified_date) = 10 AND specified_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(specified_date, '+0 days') = specified_date))",
    "CHECK (recurring_anchor_date IS NULL OR (length(recurring_anchor_date) = 10 AND recurring_anchor_date GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(recurring_anchor_date, '+0 days') = recurring_anchor_date))",
    "CHECK (recurring_interval_unit IS NULL OR recurring_interval_unit IN ('minute', 'hour', 'day', 'week', 'month', 'year'))",
    "CHECK (condition_delay_unit IS NULL OR condition_delay_unit IN ('minute', 'hour', 'day', 'week', 'month'))",
    "CHECK (condition_type IS NULL OR condition_type = 'afterFormalCompletion')",
    'CHECK (recurring_interval_value IS NULL OR recurring_interval_value > 0)',
    'CHECK (condition_delay_value IS NULL OR condition_delay_value > 0)',
    "CHECK ((timing_mode = 'later' AND specified_date IS NULL AND specified_minute_of_day IS NULL AND recurring_interval_value IS NULL AND recurring_interval_unit IS NULL AND recurring_anchor_date IS NULL AND recurring_anchor_minute_of_day IS NULL AND condition_type IS NULL AND condition_maintenance_record_id IS NULL AND condition_delay_value IS NULL AND condition_delay_unit IS NULL) OR (timing_mode = 'specifiedDate' AND specified_date IS NOT NULL AND recurring_interval_value IS NULL AND recurring_interval_unit IS NULL AND recurring_anchor_date IS NULL AND recurring_anchor_minute_of_day IS NULL AND condition_type IS NULL AND condition_maintenance_record_id IS NULL AND condition_delay_value IS NULL AND condition_delay_unit IS NULL) OR (timing_mode = 'recurring' AND specified_date IS NULL AND specified_minute_of_day IS NULL AND recurring_interval_value IS NOT NULL AND recurring_interval_unit IS NOT NULL AND condition_type IS NULL AND condition_maintenance_record_id IS NULL AND condition_delay_value IS NULL AND condition_delay_unit IS NULL) OR (timing_mode = 'condition' AND specified_date IS NULL AND specified_minute_of_day IS NULL AND recurring_interval_value IS NULL AND recurring_interval_unit IS NULL AND recurring_anchor_date IS NULL AND recurring_anchor_minute_of_day IS NULL AND condition_type = 'afterFormalCompletion' AND condition_maintenance_record_id IS NOT NULL AND condition_delay_value IS NOT NULL AND condition_delay_unit IS NOT NULL))",
  ];
}
