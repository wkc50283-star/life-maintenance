import 'package:drift/drift.dart';

import 'item_categories.dart';

@DataClassName('ItemRow')
@TableIndex(
  name: 'items_category_status_idx',
  columns: {#categoryId, #status},
)
@TableIndex(
  name: 'items_created_at_idx',
  columns: {#createdAt},
)
class Items extends Table {
  TextColumn get id => text()();

  TextColumn get name => text()();

  TextColumn get categoryId => text().references(
    ItemCategories,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get purchaseDate => dateTime().nullable()();

  DateTimeColumn get warrantyEndDate => dateTime().nullable()();

  IntColumn get expectedLifeYears => integer().nullable()();

  TextColumn get location => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get status => text()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(name) <> '')",
    'CHECK (expected_life_years IS NULL OR expected_life_years > 0)',
  ];
}
