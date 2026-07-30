import 'package:drift/drift.dart';

import 'item_lifecycle_events.dart';

@DataClassName('ItemLifecycleEventPeriodRow')
class ItemLifecycleEventPeriods extends Table {
  TextColumn get eventId => text().references(
    ItemLifecycleEvents,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get period => text()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, period};

  @override
  List<String> get customConstraints => [
    "CHECK (period IN ('year', 'halfYear', 'quarter', 'month', 'week', 'day'))",
  ];
}
