import 'dart:convert';

import '../models/item.dart';
import '../services/local_storage_service.dart';

class ItemLocalRepository {
  static const String _storageKey = 'items';

  ItemLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  Future<List<Item>> loadItems() async {
    final rawItems = await _storageService.readString(_storageKey);
    if (rawItems == null) {
      return <Item>[];
    }

    final decodedItems = jsonDecode(rawItems) as List<dynamic>;
    return decodedItems
        .map((item) => Item.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveItems(List<Item> items) async {
    final encodedItems = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedItems);
  }
}
