import 'package:drift/drift.dart';

import 'item_lifecycle_events.dart';

@DataClassName('ItemLifecycleEventCustomPeriodRow')
class ItemLifecycleEventCustomPeriods extends Table {
  TextColumn get eventId => text().references(
    ItemLifecycleEvents,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  IntColumn get intervalValue => integer()();

  TextColumn get intervalUnit => text()();

  TextColumn get canonicalFamily => text()();

  IntColumn get canonicalValue => integer()();

  @override
  Set<Column<Object>> get primaryKey => {
    eventId,
    canonicalFamily,
    canonicalValue,
  };

  @override
  List<String> get customConstraints => [
    'CHECK (interval_value > 0)',
    "CHECK (interval_unit IN ('day', 'week', 'month', 'quarter', 'halfYear', 'year'))",
    "CHECK (canonical_family IN ('day', 'calendarMonth'))",
    'CHECK (canonical_value > 0 AND canonical_value <= 9007199254740991)',
    "CHECK ((interval_unit = 'day' AND canonical_family = 'day' AND interval_value <= 9007199254740991 AND canonical_value = interval_value) OR (interval_unit = 'week' AND canonical_family = 'day' AND interval_value <= 1286742750677284 AND canonical_value = interval_value * 7) OR (interval_unit = 'month' AND canonical_family = 'calendarMonth' AND interval_value <= 9007199254740991 AND canonical_value = interval_value) OR (interval_unit = 'quarter' AND canonical_family = 'calendarMonth' AND interval_value <= 3002399751580330 AND canonical_value = interval_value * 3) OR (interval_unit = 'halfYear' AND canonical_family = 'calendarMonth' AND interval_value <= 1501199875790165 AND canonical_value = interval_value * 6) OR (interval_unit = 'year' AND canonical_family = 'calendarMonth' AND interval_value <= 750599937895082 AND canonical_value = interval_value * 12))",
  ];
}
