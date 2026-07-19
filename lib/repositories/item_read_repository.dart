import '../models/item.dart';

abstract interface class ItemReadRepository {
  Future<List<Item>> loadItems();
}
