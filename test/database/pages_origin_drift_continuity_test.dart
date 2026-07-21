import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';

void main() {
  test(
    'adopts a complete existing schema whose version metadata was lost',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-maintenance-pages-origin-',
      );
      final file = File('${directory.path}/existing.sqlite');
      addTearDown(() => directory.delete(recursive: true));

      final original = AppDatabase(NativeDatabase(file));
      await original
          .into(original.itemCategories)
          .insert(
            ItemCategoriesCompanion.insert(
              id: 'category-existing',
              systemCode: const Value('home'),
            displayName: '住家',
            sortOrder: const Value(0),
            status: 'active',
            createdAt: DateTime.utc(2026, 7, 21),
              updatedAt: DateTime.utc(2026, 7, 21),
            ),
          );
      await original
          .into(original.items)
          .insert(
            ItemsCompanion.insert(
              id: 'item-existing',
              name: '既有生活項目',
            categoryId: 'category-existing',
            status: 'active',
            createdAt: DateTime.utc(2026, 7, 21),
              updatedAt: DateTime.utc(2026, 7, 21),
            ),
          );
      await original.close();

      final metadataReset = NativeDatabase(file);
      await metadataReset.ensureOpen(_DatabaseUser());
      await metadataReset.runCustom('PRAGMA user_version = 0');
      await metadataReset.close();

      final reopened = AppDatabase(NativeDatabase(file));
      addTearDown(reopened.close);

      final items = await reopened.select(reopened.items).get();
      expect(items.single.id, 'item-existing');
      expect(items.single.name, '既有生活項目');
      final version = await reopened.customSelect('PRAGMA user_version').get();
      expect(version.single.read<int>('user_version'), 2);
    },
  );
}

class _DatabaseUser implements QueryExecutorUser {
  @override
  int get schemaVersion => 0;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}
