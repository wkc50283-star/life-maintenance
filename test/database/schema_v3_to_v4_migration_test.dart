import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('schema v3 upgrades to v6 without changing existing Item data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'life-management-schema-v3-v4-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fixture.sqlite');
    final now = DateTime.utc(2026, 7, 30);
    var database = AppDatabase(NativeDatabase(file));
    await database
        .into(database.itemCategories)
        .insert(
          ItemCategoriesCompanion.insert(
            id: 'existing-category',
            systemCode: const Value('other'),
            displayName: '其他',
            status: 'active',
            createdAt: now,
            updatedAt: now,
          ),
        );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'existing-item',
            name: '既有生活項目',
            categoryId: 'existing-category',
            createdAt: now,
            updatedAt: now,
            status: 'active',
          ),
        );
    await database.close();

    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(
      'DROP TABLE item_management_period_change_event_custom_periods',
    );
    raw.execute('DROP TABLE item_management_period_change_event_periods');
    raw.execute('DROP TABLE item_management_period_change_events');
    raw.execute('DROP TABLE item_lifecycle_event_custom_periods');
    raw.execute('DROP TABLE item_custom_management_periods');
    raw.execute('DROP TABLE item_lifecycle_event_periods');
    raw.execute('DROP TABLE item_lifecycle_events');
    raw.execute('DROP TABLE item_management_periods');
    raw.execute(
      "DELETE FROM item_categories WHERE id = '${ItemSystemCategory.unclassifiedId}'",
    );
    raw.execute('PRAGMA user_version = 3');
    raw.close();

    database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    final existing = await (database.select(
      database.items,
    )..where((table) => table.id.equals('existing-item'))).getSingle();
    final unclassified =
        await (database.select(database.itemCategories)..where(
              (table) => table.id.equals(ItemSystemCategory.unclassifiedId),
            ))
            .getSingleOrNull();

    expect(database.schemaVersion, 7);
    expect(existing.categoryId, 'existing-category');
    expect(unclassified?.systemCode, ItemSystemCategory.unclassifiedCode);
    expect(
      await database.select(database.itemManagementPeriods).get(),
      isEmpty,
    );
    expect(await database.select(database.itemLifecycleEvents).get(), isEmpty);
    expect(
      await database.select(database.itemLifecycleEventPeriods).get(),
      isEmpty,
    );
    expect(
      await database.select(database.itemCustomManagementPeriods).get(),
      isEmpty,
    );
    expect(
      await database.select(database.itemLifecycleEventCustomPeriods).get(),
      isEmpty,
    );
  });
}
