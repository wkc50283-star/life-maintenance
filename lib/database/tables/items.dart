import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../core_type_converters.dart';

@DataClassName('ItemRow')
@TableIndex(name: 'items_category_status_idx', columns: {#category, #status})
@TableIndex(name: 'items_created_at_idx', columns: {#createdAt})
class Items extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text().map(const ItemCategorySqlConverter())();
  TextColumn get photoPath => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get purchaseDate => dateTime().nullable()();
  DateTimeColumn get warrantyEndDate => dateTime().nullable()();
  IntColumn get expectedLifeYears => integer().nullable()();
  TextColumn get location => text().nullable()();
  TextColumn get note => text().nullable()();
  TextColumn get status => text().map(const ItemStatusSqlConverter())();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
        'CHECK (expected_life_years IS NULL OR expected_life_years > 0)',
      ];
}
