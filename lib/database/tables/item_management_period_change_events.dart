import 'package:drift/drift.dart';

import 'items.dart';

@DataClassName('ItemManagementPeriodChangeEventRow')
class ItemManagementPeriodChangeEvents extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
