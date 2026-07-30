import 'package:drift/drift.dart';

import 'items.dart';

@DataClassName('ItemLifecycleEventRow')
@TableIndex(
  name: 'item_lifecycle_events_item_type_unique_idx',
  columns: {#itemId, #eventType},
  unique: true,
)
class ItemLifecycleEvents extends Table {
  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get eventType => text()();

  TextColumn get itemNameSnapshot => text()();

  TextColumn get categoryIdSnapshot => text()();

  TextColumn get categorySystemCodeSnapshot => text().nullable()();

  TextColumn get categoryCustomNameSnapshot => text().nullable()();

  TextColumn get categoryDisplayNameSnapshot => text()();

  DateTimeColumn get occurredAt => dateTime()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (event_type = 'created')",
    "CHECK (trim(item_name_snapshot) <> '')",
    "CHECK (trim(category_id_snapshot) <> '')",
    "CHECK (trim(category_display_name_snapshot) <> '')",
  ];
}
