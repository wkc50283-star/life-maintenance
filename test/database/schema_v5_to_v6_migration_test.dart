import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;

void main() {
  test(
    'schema v5 adds change history without rewriting current periods',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-management-schema-v5-v6-',
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
      await database
          .into(database.itemCustomManagementPeriods)
          .insert(
            ItemCustomManagementPeriodsCompanion.insert(
              itemId: 'existing-item',
              intervalValue: 5,
              intervalUnit: 'month',
              canonicalFamily: 'calendarMonth',
              canonicalValue: 5,
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
      raw.execute('PRAGMA user_version = 5');
      raw.close();

      database = AppDatabase(NativeDatabase(file));
      addTearDown(database.close);
      await database.customSelect('SELECT 1').get();

      expect(database.schemaVersion, 6);
      expect(
        (await database.select(database.itemManagementPeriods).get())
            .single
            .period,
        'month',
      );
      expect(
        (await database.select(database.itemCustomManagementPeriods).get())
            .single
            .intervalValue,
        5,
      );
      expect(
        await database.select(database.itemManagementPeriodChangeEvents).get(),
        isEmpty,
      );
      expect(
        await database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
    },
  );
}
