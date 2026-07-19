import 'dart:convert';

import '../models/item.dart';
import '../services/local_data_integrity_service.dart';
import '../services/local_storage_service.dart';
import 'item_read_repository.dart';

class ItemLocalRepository implements ItemReadRepository {
  static const String _storageKey = 'items';

  ItemLocalRepository(this._storageService);

  final LocalStorageService _storageService;

  @override
  Future<List<Item>> loadItems() async {
    final rawItems = await _storageService.readString(_storageKey);
    if (rawItems == null) {
      LocalDataIntegrityService.instance.clearIssue(_storageKey);
      return <Item>[];
    }

    return LocalDataIntegrityService.instance.decodeList<Item>(
      storageKey: _storageKey,
      rawValue: rawItems,
      decodeEntry: Item.fromJson,
    );
  }

  Future<void> saveItems(List<Item> items) async {
    LocalDataIntegrityService.instance.ensureWritesAllowed();
    final encodedItems = jsonEncode(
      items.map((item) => item.toJson()).toList(),
    );
    await _storageService.saveString(_storageKey, encodedItems);
  }
}
