import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/enums.dart';
import 'package:life_maintenance/models/item.dart';
import 'package:life_maintenance/models/maintenance_record.dart';
import 'package:life_maintenance/models/schedule.dart';
import 'package:life_maintenance/models/task.dart';
import 'package:life_maintenance/services/legacy_relation_audit_service.dart';
import 'package:life_maintenance/services/local_storage_service.dart';

class _ReadOnlyStorage extends LocalStorageService {
  _ReadOnlyStorage(this.values);

  final Map<String, String> values;
  int saveCalls = 0;
  int removeCalls = 0;

  @override
  Future<String?> readString(String key) async => values[key];

  @override
  Future<void> saveString(String key, String value) async {
    saveCalls += 1;
    throw StateError('Legacy relation audit must remain read-only');
  }

  @override
  Future<void> remove(String key) async {
    removeCalls += 1;
    throw StateError('Legacy relation audit must remain read-only');
  }
}

void main() {
  final now = DateTime.utc(2026, 7, 18);

  Item item(String id) => Item(
    id: id,
    name: '生活項目 $id',
    category: ItemCategory.other,
    createdAt: now,
  );

  Schedule schedule({
    required String id,
    required String itemId,
  }) => Schedule(
    id: id,
    itemId: itemId,
    cardId: 'card-1',
    cycleType: CycleType.monthly,
    interval: 1,
    startDate: now,
    nextDueDate: now,
  );

  Task task({
    required String id,
    required String itemId,
    required String scheduleId,
  }) => Task(
    id: id,
    itemId: itemId,
    cardId: 'card-1',
    scheduleId: scheduleId,
    title: '待處理事項',
    dueDate: now,
  );

  MaintenanceRecord record({
    required String id,
    required String itemId,
    String? taskId,
  }) => MaintenanceRecord(
    id: id,
    itemId: itemId,
    taskId: taskId,
    recordType: RecordType.regularMaintenance,
    date: now,
    title: '完成紀錄',
    createdAt: now,
  );

  test('reports a fully valid legacy graph without writing', () async {
    final storage = _ReadOnlyStorage({
      'items': jsonEncode([item('item-1').toJson()]),
      'schedules': jsonEncode([
        schedule(id: 'schedule-1', itemId: 'item-1').toJson(),
      ]),
      'tasks': jsonEncode([
        task(
          id: 'task-1',
          itemId: 'item-1',
          scheduleId: 'schedule-1',
        ).toJson(),
      ]),
      'maintenance_records': jsonEncode([
        record(
          id: 'record-1',
          itemId: 'item-1',
          taskId: 'task-1',
        ).toJson(),
      ]),
    });

    final report = await LegacyRelationAuditService(storage).inspect();

    expect(report.isReadyForMigration, isTrue);
    expect(report.relationIssues, isEmpty);
    expect(report.datasets['items']!.validEntryCount, 1);
    expect(storage.saveCalls, 0);
    expect(storage.removeCalls, 0);
  });

  test('reports duplicate ids and malformed entries separately', () async {
    final duplicate = item('item-1').toJson();
    final storage = _ReadOnlyStorage({
      'items': jsonEncode([duplicate, duplicate, 'not-an-object']),
      'schedules': '[]',
      'tasks': '[]',
      'maintenance_records': '[]',
    });

    final report = await LegacyRelationAuditService(storage).inspect();
    final itemsAudit = report.datasets['items']!;

    expect(itemsAudit.rawEntryCount, 3);
    expect(itemsAudit.validEntryCount, 2);
    expect(itemsAudit.invalidEntryCount, 1);
    expect(itemsAudit.duplicateIds, {'item-1'});
    expect(report.allDatasetsStructurallyValid, isFalse);
  });

  test('reports dangling item, schedule, and task references', () async {
    final storage = _ReadOnlyStorage({
      'items': jsonEncode([item('item-1').toJson()]),
      'schedules': jsonEncode([
        schedule(id: 'schedule-1', itemId: 'missing-item').toJson(),
      ]),
      'tasks': jsonEncode([
        task(
          id: 'task-1',
          itemId: 'missing-item',
          scheduleId: 'missing-schedule',
        ).toJson(),
      ]),
      'maintenance_records': jsonEncode([
        record(
          id: 'record-1',
          itemId: 'missing-item',
          taskId: 'missing-task',
        ).toJson(),
      ]),
    });

    final report = await LegacyRelationAuditService(storage).inspect();

    expect(report.allDatasetsStructurallyValid, isTrue);
    expect(report.allRelationsValid, isFalse);
    expect(report.relationIssues, hasLength(5));
    expect(
      report.relationIssues.map((issue) => issue.fieldName),
      containsAll(<String>['itemId', 'scheduleId', 'taskId']),
    );
    expect(storage.saveCalls, 0);
    expect(storage.removeCalls, 0);
  });

  test('treats a non-list dataset as structurally invalid', () async {
    final storage = _ReadOnlyStorage({
      'items': '{"id":"item-1"}',
      'schedules': '[]',
      'tasks': '[]',
      'maintenance_records': '[]',
    });

    final report = await LegacyRelationAuditService(storage).inspect();

    expect(report.datasets['items']!.invalidEntryCount, 1);
    expect(report.datasets['items']!.validEntryCount, 0);
    expect(report.isReadyForMigration, isFalse);
  });
}
