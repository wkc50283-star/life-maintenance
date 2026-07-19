import 'dart:convert';
import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/app/app_composition_root.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/repositories/drift/drift_item_read_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schedule_runtime_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_task_runtime_repository.dart';
import 'package:life_maintenance/services/local_data_integrity_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    LocalDataIntegrityService.instance.resetForTesting();
    SharedPreferences.resetStatic();
  });

  test('formal lib code imports SharedPreferences through one abstraction', () {
    final imports = _dartFiles('lib')
        .where(
          (file) => file.readAsStringSync().contains(
            "package:shared_preferences/shared_preferences.dart",
          ),
        )
        .map((file) => _relative(file.path))
        .toSet();

    expect(imports, {'lib/services/local_storage_service.dart'});
  });

  test('screens and widgets never construct legacy persistence objects', () {
    const forbiddenConstructions = [
      'LocalStorageService(',
      'ItemLocalRepository(',
      'ScheduleLocalRepository(',
      'TaskLocalRepository(',
      'MaintenanceRecordLocalRepository(',
      'SharedPreferences.getInstance(',
    ];
    final violations = <String>[];
    for (final directory in const ['lib/screens', 'lib/widgets']) {
      for (final file in _dartFiles(directory)) {
        final source = file.readAsStringSync();
        for (final pattern in forbiddenConstructions) {
          if (source.contains(pattern)) {
            violations.add('${_relative(file.path)}: $pattern');
          }
        }
      }
    }

    expect(violations, isEmpty);
  });

  test('known legacy UI dependencies remain explicit retirement blockers', () {
    final references = <String>{};
    for (final directory in const ['lib/screens', 'lib/widgets']) {
      for (final file in _dartFiles(directory)) {
        final source = file.readAsStringSync();
        if (source.contains('MaintenanceRecordLocalRepository') ||
            source.contains('.maintenanceRecordRepository') ||
            source.contains('.itemRepository')) {
          references.add(_relative(file.path));
        }
      }
    }

    expect(references, {
      'lib/screens/history_screen.dart',
      'lib/screens/items_screen.dart',
      'lib/widgets/add_item_preview_sheet.dart',
      'lib/widgets/maintenance_record_preview_sheet.dart',
    });
  });

  test(
    'verified cutover makes Drift the only writer and survives cold start',
    () async {
      final item = Item(
        id: 'item-1',
        name: '客廳冷氣',
        category: ItemCategory.appliance,
        createdAt: DateTime.utc(2026, 1, 2),
      );
      final rawItems = jsonEncode([item.toJson()]);
      SharedPreferences.setMockInitialValues({'items': rawItems});
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );

      final initialized = await root.initialize();

      expect(initialized.mode, RuntimeDataMode.driftMaintenanceRecords);
      expect(root.itemReadRepository, isA<DriftItemReadRepository>());
      expect(root.scheduleRepository, isA<DriftScheduleRuntimeRepository>());
      expect(root.taskRepository, isA<DriftTaskRuntimeRepository>());
      expect(root.formalMaintenanceRecordRepository, isNotNull);
      expect(root.legacyWritesEnabled, isFalse);

      final legacyBefore = await _legacySnapshot(storage);
      await expectLater(
        root.itemRepository.saveItems(const []),
        throwsA(isA<LegacyStorageReadOnlyException>()),
      );
      await expectLater(
        root.maintenanceRecordRepository.saveRecords(const []),
        throwsA(isA<LegacyStorageReadOnlyException>()),
      );

      final completedAt = DateTime.utc(2026, 7, 19, 12);
      await root.formalMaintenanceRecordRepository!.createSimpleRecord(
        MaintenanceRecord(
          id: 'record-runtime',
          itemId: item.id,
          recordType: RecordType.regularMaintenance,
          date: completedAt,
          title: '完成簡單清潔',
          createdAt: completedAt,
        ),
      );
      expect(await _legacySnapshot(storage), legacyBefore);

      final restartedStorage = LocalStorageService();
      final restarted = AppCompositionRoot(
        database: database,
        legacyStorage: restartedStorage,
      );
      final restartResult = await restarted.initialize();

      expect(restartResult.mode, RuntimeDataMode.driftMaintenanceRecords);
      expect(restarted.legacyWritesEnabled, isFalse);
      expect(
        (await restarted.formalMaintenanceRecordRepository!.findById(
          'record-runtime',
        ))?.title,
        '完成簡單清潔',
      );
      expect(await _legacySnapshot(restartedStorage), legacyBefore);
      await database.close();
    },
  );

  test(
    'failed admission returns the complete legacy recovery runtime',
    () async {
      final item = Item(
        id: 'item-1',
        name: '家庭汽車',
        category: ItemCategory.vehicle,
        createdAt: DateTime.utc(2026, 2, 3),
      );
      final rawItems = jsonEncode([item.toJson()]);
      SharedPreferences.setMockInitialValues({
        'items': rawItems,
        'backup_v1_items': '[]',
      });
      final database = AppDatabase(NativeDatabase.memory());
      final storage = LocalStorageService();
      final root = AppCompositionRoot(
        database: database,
        legacyStorage: storage,
      );

      final initialized = await root.initialize();

      expect(initialized.mode, RuntimeDataMode.legacy);
      expect(root.legacyWritesEnabled, isTrue);
      expect(root.formalMaintenanceRecordRepository, isNull);
      expect(root.workCaseRuntime, isNull);
      expect(root.historyProjectionRepository, isNull);
      expect(await root.itemRepository.loadItems(), hasLength(1));
      expect(await database.select(database.items).get(), isEmpty);
      expect(await storage.readString('items'), rawItems);
      expect(await storage.readString('backup_v1_items'), '[]');
      await database.close();
    },
  );
}

List<File> _dartFiles(String path) => Directory(path)
    .listSync(recursive: true)
    .whereType<File>()
    .where((file) => file.path.endsWith('.dart'))
    .toList(growable: false);

String _relative(String path) =>
    path.replaceFirst('${Directory.current.path}/', '');

Future<Map<String, String?>> _legacySnapshot(
  LocalStorageService storage,
) async {
  const keys = [
    'items',
    'schedules',
    'tasks',
    'maintenance_records',
    'backup_v1_items',
    'backup_v1_schedules',
    'backup_v1_tasks',
    'backup_v1_maintenance_records',
  ];
  return {for (final key in keys) key: await storage.readString(key)};
}
