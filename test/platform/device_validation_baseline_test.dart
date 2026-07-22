import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';

void main() {
  test(
    'formal Drift data remains readable and survives a complete restart',
    () async {
      final directory = await Directory.systemTemp.createTemp(
        'life-device-baseline-',
      );
      final databaseFile = File('${directory.path}/life.sqlite');
      addTearDown(() async {
        if (await directory.exists()) {
          await directory.delete(recursive: true);
        }
      });

      final now = DateTime.utc(2026, 7, 20, 12);
      var root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase(databaseFile)),
      );
      await root.initialize();
      await root.driftRepositories.itemCategories.save(
        ItemCategoryRow(
          id: 'device-category',
          systemCode: 'home',
          displayName: '住家',
          sortOrder: 0,
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
      await root.driftRepositories.items.save(
        ItemRow(
          id: 'device-item',
          name: '真機驗收項目',
          categoryId: 'device-category',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );

      expect(
        (await root.driftRepositories.items.findById('device-item'))?.name,
        '真機驗收項目',
      );

      await root.database.close();
      root = AppCompositionRoot(
        database: AppDatabase(NativeDatabase(databaseFile)),
      );
      expect((await root.initialize()).usesDriftItemRead, isTrue);
      expect(
        (await root.driftRepositories.items.findById('device-item'))?.name,
        '真機驗收項目',
      );
      expect(
        await root.database.customSelect('PRAGMA foreign_key_check').get(),
        isEmpty,
      );
      expect(
        await root.database
            .customSelect('PRAGMA integrity_check')
            .get()
            .then((rows) => rows.single.data.values.single),
        'ok',
      );
      await root.database.close();
    },
  );

  test('patch upgrades preserve platform and database identity contracts', () {
    final pubspec = File('pubspec.yaml').readAsStringSync();
    expect(pubspec, contains('version: 0.5.40+41'));

    final android = File('android/app/build.gradle.kts').readAsStringSync();
    expect(android, contains('applicationId = "com.example.life_maintenance"'));

    final iosProject = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();
    expect(
      RegExp(
        r'PRODUCT_BUNDLE_IDENTIFIER = com\.example\.lifeMaintenance;',
      ).allMatches(iosProject),
      hasLength(3),
    );

    final databaseSource = File(
      'lib/database/app_database.dart',
    ).readAsStringSync();
    expect(databaseSource, contains('int get schemaVersion => 2;'));
  });

  test(
    'device checklist never substitutes simulator evidence for real devices',
    () {
      final baseline = File(
        'docs/control/43-device-validation-baseline.md',
      ).readAsStringSync();
      for (final requirement in const [
        '全新安裝與啟動',
        '背景與程序重啟',
        '原地版本升級',
        '失敗與回復',
        '未簽核',
        '不得用 simulator',
      ]) {
        expect(baseline, contains(requirement));
      }
      expect(baseline, isNot(contains('iOS 真機：通過')));
      expect(baseline, isNot(contains('Android 真機：通過')));
    },
  );
}
