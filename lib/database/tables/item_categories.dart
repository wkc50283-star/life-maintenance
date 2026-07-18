import 'package:drift/drift.dart';

@DataClassName('ItemCategoryRow')
@TableIndex(
  name: 'item_categories_system_code_status_idx',
  columns: {#systemCode, #status},
)
@TableIndex(
  name: 'item_categories_display_name_idx',
  columns: {#displayName},
)
class ItemCategories extends Table {
  TextColumn get id => text()();

  TextColumn get systemCode => text().nullable()();

  TextColumn get customName => text().nullable()();

  TextColumn get displayName => text()();

  IntColumn get sortOrder => integer().withDefault(const Constant(0))();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (system_code IS NOT NULL OR trim(custom_name) <> '')",
    "CHECK (custom_name IS NULL OR trim(custom_name) <> '')",
    "CHECK (trim(display_name) <> '')",
  ];
}
