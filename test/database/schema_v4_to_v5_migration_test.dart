import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test('schema v4 upgrades to v6 without rewriting fixed data', () async {
    final directory = await Directory.systemTemp.createTemp(
      'life-management-schema-v4-v5-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final file = File('${directory.path}/fixture.sqlite');
    final now = DateTime.utc(2026, 8, 8);
    var database = AppDatabase(NativeDatabase(file));
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'existing-item',
            name: '既有生活項目',
            categoryId: 'system-category-unclassified',
            createdAt: now,
            updatedAt: now,
            status: 'active',
          ),
        );
    await database
        .into(database.itemManagementPeriods)
        .insert(
          ItemManagementPeriodsCompanion.insert(
            itemId: 'existing-item',
            period: 'month',
            createdAt: now,
          ),
        );
    await database.close();

    final raw = sqlite.sqlite3.open(file.path);
    raw.execute(
      'DROP TABLE item_management_period_change_event_custom_periods',
    );
    raw.execute('DROP TABLE item_management_period_change_event_periods');
    raw.execute('DROP TABLE item_management_period_change_events');
    raw.execute('DROP TRIGGER item_management_periods_no_custom_equivalent');
    raw.execute(
      'DROP TRIGGER item_lifecycle_event_periods_no_custom_equivalent',
    );
    raw.execute('DROP TABLE item_lifecycle_event_custom_periods');
    raw.execute('DROP TABLE item_custom_management_periods');
    raw.execute('PRAGMA user_version = 4');
    raw.close();

    database = AppDatabase(NativeDatabase(file));
    addTearDown(database.close);
    await database.customSelect('SELECT 1').get();

    expect(database.schemaVersion, 12);
    expect(await database.select(database.items).get(), hasLength(1));
    final fixed = await database.select(database.itemManagementPeriods).get();
    expect(fixed, hasLength(1));
    expect(fixed.single.period, 'month');
    expect(
      await database.select(database.itemCustomManagementPeriods).get(),
      isEmpty,
    );
    expect(
      await database.select(database.itemLifecycleEventCustomPeriods).get(),
      isEmpty,
    );
    expect(
      await database.customSelect('PRAGMA foreign_key_check').get(),
      isEmpty,
    );
  });
}
