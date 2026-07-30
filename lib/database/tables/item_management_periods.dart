import 'package:drift/drift.dart';

import 'items.dart';

@DataClassName('ItemManagementPeriodRow')
class ItemManagementPeriods extends Table {
  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.cascade,
  )();

  TextColumn get period => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {itemId, period};

  @override
  List<String> get customConstraints => [
    "CHECK (period IN ('year', 'halfYear', 'quarter', 'month', 'week', 'day'))",
  ];
}
