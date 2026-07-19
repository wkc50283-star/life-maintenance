import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/item.dart';
import '../item_read_repository.dart';
import 'drift_schema_v2_repositories.dart';

class DriftItemReadRepository implements ItemReadRepository {
  const DriftItemReadRepository(this._repositories);

  final DriftSchemaV2Repositories _repositories;

  @override
  Future<List<Item>> loadItems() async {
    final categories = await _repositories.itemCategories.listAll();
    final categoriesById = <String, ItemCategoryRow>{
      for (final category in categories) category.id: category,
    };
    final rows = await _repositories.items.listAll();
    return [
      for (final row in rows)
        _toDomain(row, _requireCategory(categoriesById, row.categoryId)),
    ];
  }

  ItemCategoryRow _requireCategory(
    Map<String, ItemCategoryRow> categories,
    String categoryId,
  ) {
    final category = categories[categoryId];
    if (category == null) {
      throw StateError('Item category $categoryId does not exist.');
    }
    return category;
  }

  Item _toDomain(ItemRow row, ItemCategoryRow category) => Item(
    id: row.id,
    name: row.name,
    category: _legacyCategory(category),
    createdAt: row.createdAt,
    purchaseDate: row.purchaseDate,
    warrantyEndDate: row.warrantyEndDate,
    expectedLifeYears: row.expectedLifeYears,
    location: row.location,
    note: row.note,
    status: ItemStatus.values.byName(row.status),
  );

  ItemCategory _legacyCategory(ItemCategoryRow category) {
    if (category.id.startsWith('legacy-category-')) {
      final legacyName = category.id.substring('legacy-category-'.length);
      return ItemCategory.values.byName(legacyName);
    }
    return switch (category.systemCode) {
      'homeAndAppliance' => ItemCategory.appliance,
      'vehicleAndTransport' => ItemCategory.vehicle,
      'houseAndRepair' => ItemCategory.house,
      'documentAndContract' => ItemCategory.warrantyDocument,
      _ => ItemCategory.other,
    };
  }
}
