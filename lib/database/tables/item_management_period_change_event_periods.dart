import 'package:drift/drift.dart';

import 'item_management_period_change_events.dart';

@DataClassName('ItemManagementPeriodChangeEventPeriodRow')
class ItemManagementPeriodChangeEventPeriods extends Table {
  TextColumn get eventId => text().references(
    ItemManagementPeriodChangeEvents,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get snapshotSide => text()();
  TextColumn get period => text()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, snapshotSide, period};

  @override
  List<String> get customConstraints => [
    "CHECK (snapshot_side IN ('before', 'after'))",
    "CHECK (period IN ('year', 'halfYear', 'quarter', 'month', 'week', 'day'))",
  ];
}
