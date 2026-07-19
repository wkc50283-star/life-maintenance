import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/repositories/item_local_repository.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';

void main() {
  final integrityService = LocalDataIntegrityService.instance;

  setUp(integrityService.resetForTesting);
  tearDown(integrityService.resetForTesting);

  test('keeps valid entries and reports an invalid recovery entry', () async {
    final storage = _FakeLocalStorageService();
    final originalRaw = jsonEncode([
      {
        'id': 'item-1',
        'name': '冷氣',
        'category': 'appliance',
        'createdAt': '2025-01-01T00:00:00.000',
        'status': 'active',
      },
      {'id': 2, 'name': '損壞資料'},
    ]);
    storage.values['items'] = originalRaw;
    final repository = ItemLocalRepository(storage);

    final items = await repository.loadItems();

    expect(items, hasLength(1));
    expect(items.single.name, '冷氣');
    expect(integrityService.hasIssues, isTrue);
    expect(integrityService.issues.single.invalidEntryCount, 1);

    expect(storage.values['items'], originalRaw);
  });

  test(
    'malformed top-level JSON is not treated as healthy empty data',
    () async {
      final storage = _FakeLocalStorageService();
      storage.values['items'] = '{not-json';
      final repository = ItemLocalRepository(storage);

      final items = await repository.loadItems();

      expect(items, isEmpty);
      expect(integrityService.hasIssues, isTrue);
      expect(integrityService.hasIssueForKey('items'), isTrue);
    },
  );

  test('a later fully valid read clears the issue for that data set', () async {
    final storage = _FakeLocalStorageService();
    final repository = ItemLocalRepository(storage);
    storage.values['items'] = '{not-json';
    await repository.loadItems();
    expect(integrityService.hasIssues, isTrue);

    storage.values['items'] = jsonEncode([
      {
        'id': 'item-1',
        'name': '冷氣',
        'category': 'appliance',
        'createdAt': '2025-01-01T00:00:00.000',
        'status': 'active',
      },
    ]);

    final items = await repository.loadItems();

    expect(items, hasLength(1));
    expect(integrityService.hasIssues, isFalse);

    expect(jsonDecode(storage.values['items']!) as List<dynamic>, hasLength(1));
  });
}

class _FakeLocalStorageService extends LocalStorageService {
  final Map<String, String> values = <String, String>{};

  @override
  Future<String?> readString(String key) async => values[key];
}
