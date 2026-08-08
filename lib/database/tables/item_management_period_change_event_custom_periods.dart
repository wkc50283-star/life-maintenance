import 'package:drift/drift.dart';

import 'item_management_period_change_events.dart';

@DataClassName('ItemManagementPeriodChangeEventCustomPeriodRow')
class ItemManagementPeriodChangeEventCustomPeriods extends Table {
  TextColumn get eventId => text().references(
    ItemManagementPeriodChangeEvents,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get snapshotSide => text()();
  IntColumn get intervalValue => integer()();
  TextColumn get intervalUnit => text()();
  TextColumn get canonicalFamily => text()();
  IntColumn get canonicalValue => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    eventId,
    snapshotSide,
    canonicalFamily,
    canonicalValue,
  };

  @override
  List<String> get customConstraints => [
    "CHECK (snapshot_side IN ('before', 'after'))",
    'CHECK (interval_value > 0)',
    "CHECK (interval_unit IN ('day', 'week', 'month', 'quarter', 'halfYear', 'year'))",
    "CHECK (canonical_family IN ('day', 'calendarMonth'))",
    'CHECK (canonical_value > 0 AND canonical_value <= 9007199254740991)',
    "CHECK ((interval_unit = 'day' AND canonical_family = 'day' AND interval_value <= 9007199254740991 AND canonical_value = interval_value) OR (interval_unit = 'week' AND canonical_family = 'day' AND interval_value <= 1286742750677284 AND canonical_value = interval_value * 7) OR (interval_unit = 'month' AND canonical_family = 'calendarMonth' AND interval_value <= 9007199254740991 AND canonical_value = interval_value) OR (interval_unit = 'quarter' AND canonical_family = 'calendarMonth' AND interval_value <= 3002399751580330 AND canonical_value = interval_value * 3) OR (interval_unit = 'halfYear' AND canonical_family = 'calendarMonth' AND interval_value <= 1501199875790165 AND canonical_value = interval_value * 6) OR (interval_unit = 'year' AND canonical_family = 'calendarMonth' AND interval_value <= 750599937895082 AND canonical_value = interval_value * 12))",
  ];
}
