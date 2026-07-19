import 'dart:convert';

import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/maintenance_record.dart';
import '../../models/work_case_enums.dart';
import '../maintenance_record_repository.dart';
import '../repository_constraint_exception.dart';

/// Schema v2 Runtime repository for simple completion facts.
class DriftMaintenanceRecordRuntimeRepository
    implements MaintenanceRecordRepository {
  DriftMaintenanceRecordRuntimeRepository(this._database);

  final AppDatabase _database;

  @override
  Future<MaintenanceRecord?> findById(String id) async {
    final query = _database.select(_database.maintenanceRecords)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toMaintenanceRecord();
  }

  @override
  Future<List<MaintenanceRecord>> listForItem(String itemId) async {
    await _requireItem(itemId);
    final query = _database.select(_database.maintenanceRecords)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.desc(table.date)]);
    return (await query.get())
        .map((row) => row.toMaintenanceRecord())
        .toList(growable: false);
  }

  @override
  Future<void> createSimpleRecord(MaintenanceRecord record) async {
    if (record.taskId != null) {
      throw const RepositoryConstraintException(
        'A manual simple record cannot reference a Task.',
      );
    }
    await _database.transaction(() async {
      await _validateRecord(record);
      await _insert(record);
    });
  }

  @override
  Future<void> completeSimpleTask(MaintenanceRecord record) async {
    final taskId = record.taskId;
    if (taskId == null) {
      throw const RepositoryConstraintException(
        'A Task completion record requires a Task.',
      );
    }
    await _database.transaction(() async {
      await _validateRecord(record);
      final taskQuery = _database.select(_database.tasks)
        ..where((table) => table.id.equals(taskId));
      final task = await taskQuery.getSingleOrNull();
      if (task == null) {
        throw RepositoryConstraintException('Task $taskId does not exist.');
      }
      if (task.itemId != record.itemId) {
        throw const RepositoryConstraintException(
          'Task and MaintenanceRecord must belong to the same Item.',
        );
      }
      if (task.status == TaskStatus.completed.name ||
          task.status == TaskStatus.canceled.name) {
        throw const RepositoryConstraintException(
          'A terminal Task cannot create another completion record.',
        );
      }
      final duplicateQuery = _database.select(_database.maintenanceRecords)
        ..where((table) => table.taskId.equals(taskId));
      if (await duplicateQuery.getSingleOrNull() != null) {
        throw const RepositoryConstraintException(
          'A Task can create at most one MaintenanceRecord.',
        );
      }
      if (await _hasCaseFor(task)) {
        throw const RepositoryConstraintException(
          'A Task with a WorkCase must be concluded by WorkCaseClosure.',
        );
      }

      await _insert(record);
      await (_database.update(
        _database.tasks,
      )..where((table) => table.id.equals(taskId))).write(
        TasksCompanion(
          status: Value(TaskStatus.completed.name),
          completedAt: Value(record.date),
          postponedAt: const Value(null),
          updatedAt: Value(record.createdAt),
        ),
      );
    });
  }

  Future<void> _validateRecord(MaintenanceRecord record) async {
    await _requireItem(record.itemId);
    if (record.title.trim().isEmpty) {
      throw const RepositoryConstraintException(
        'MaintenanceRecord requires a title.',
      );
    }
    if (record.cost case final cost? when cost < 0) {
      throw const RepositoryConstraintException(
        'MaintenanceRecord cost cannot be negative.',
      );
    }
    if (record.photos.isNotEmpty) {
      throw const RepositoryConstraintException(
        'New attachments must use the Attachment Runtime.',
      );
    }
    if (record.maintenancePlanId case final planId?) {
      final query = _database.select(_database.maintenancePlans)
        ..where((table) => table.id.equals(planId));
      final plan = await query.getSingleOrNull();
      if (plan == null || plan.itemId != record.itemId) {
        throw const RepositoryConstraintException(
          'MaintenancePlan and MaintenanceRecord must belong to the same Item.',
        );
      }
    }
  }

  Future<bool> _hasCaseFor(TaskRow task) async {
    final taskCaseQuery = _database.select(_database.workCases)
      ..where(
        (table) =>
            table.sourceType.equals(WorkCaseSourceType.maintenanceTask.name) &
            table.sourceId.equals(task.id),
      );
    if (await taskCaseQuery.getSingleOrNull() != null) return true;

    final (type, id) = switch (task.sourceType) {
      'scheduledMaintenance' => (null, null),
      'scheduledReminder' => (
        WorkCaseSourceType.generalReminder,
        task.generalReminderId,
      ),
      'milestone' => (WorkCaseSourceType.milestone, task.milestoneId),
      _ => (null, null),
    };
    if (type == null || id == null) return false;
    final query = _database.select(_database.workCases)
      ..where(
        (table) =>
            table.sourceType.equals(type.name) & table.sourceId.equals(id),
      );
    return await query.getSingleOrNull() != null;
  }

  Future<void> _requireItem(String itemId) async {
    final query = _database.select(_database.items)
      ..where((table) => table.id.equals(itemId));
    if (await query.getSingleOrNull() == null) {
      throw RepositoryConstraintException('Item $itemId does not exist.');
    }
  }

  Future<void> _insert(MaintenanceRecord record) => _database
      .into(_database.maintenanceRecords)
      .insert(record.toDriftCompanion(), mode: InsertMode.insert);
}

extension MaintenanceRecordRowRuntimeMapping on MaintenanceRecordRow {
  MaintenanceRecord toMaintenanceRecord() => MaintenanceRecord(
    id: id,
    itemId: itemId,
    taskId: taskId,
    maintenancePlanId: maintenancePlanId,
    recordType: RecordType.values.firstWhere(
      (value) => value.name == recordType,
      orElse: () => RecordType.other,
    ),
    date: date,
    title: title,
    issueDescription: issueDescription,
    workDescription: workDescription,
    partsChanged: _decodeParts(partsChanged),
    cost: cost,
    vendorName: vendorName,
    warrantyUntil: warrantyUntil,
    result: result,
    note: note,
    createdAt: createdAt,
  );
}

extension MaintenanceRecordRuntimeMapping on MaintenanceRecord {
  MaintenanceRecordsCompanion toDriftCompanion() =>
      MaintenanceRecordsCompanion.insert(
        id: id,
        itemId: itemId,
        taskId: Value(taskId),
        maintenancePlanId: Value(maintenancePlanId),
        recordType: recordType.name,
        date: date,
        title: title,
        issueDescription: Value(issueDescription),
        workDescription: Value(workDescription),
        partsChanged: Value(
          partsChanged.isEmpty ? null : jsonEncode(partsChanged),
        ),
        cost: Value(cost),
        vendorName: Value(vendorName),
        warrantyUntil: Value(warrantyUntil),
        result: Value(result),
        note: Value(note),
        createdAt: createdAt,
      );
}

List<String> _decodeParts(String? value) {
  if (value == null) return const [];
  try {
    final decoded = jsonDecode(value);
    return decoded is List
        ? decoded.whereType<String>().toList(growable: false)
        : const [];
  } on FormatException {
    return const [];
  }
}
