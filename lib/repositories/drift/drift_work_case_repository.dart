import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/work_case.dart';
import '../../models/work_case_enums.dart';
import '../../models/work_case_update.dart';
import '../repository_constraint_exception.dart';
import '../work_case_repository.dart';
import 'work_case_drift_mappers.dart';

class DriftWorkCaseRepository implements WorkCaseRepository {
  DriftWorkCaseRepository(this._database);

  final AppDatabase _database;

  @override
  Future<WorkCase?> findCaseById(String id) async {
    final query = _database.select(_database.workCases)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toModel();
  }

  @override
  Future<List<WorkCase>> listCasesForItem(String itemId) async {
    final query = _database.select(_database.workCases)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  @override
  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId) async {
    final query = _database.select(_database.workCaseUpdates)
      ..where((table) => table.workCaseId.equals(workCaseId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  @override
  Future<void> saveCase(WorkCase workCase) async {
    if (workCase.isClosed) {
      throw const RepositoryConstraintException(
        'WorkCase completion or cancellation requires WorkCaseClosure.',
      );
    }
    await _database.transaction(() async {
      await _validateSource(workCase);
      final existing = await findCaseById(workCase.id);
      if (existing != null && existing.isClosed) {
        throw const RepositoryConstraintException(
          'A closed WorkCase is immutable.',
        );
      }
      await _database
          .into(_database.workCases)
          .insertOnConflictUpdate(workCase.toCompanion());
    });
  }

  @override
  Future<void> appendUpdate(WorkCaseUpdate update) async {
    await _database.transaction(() async {
      final workCase = await findCaseById(update.workCaseId);
      if (workCase == null) {
        throw RepositoryConstraintException(
          'WorkCase ${update.workCaseId} does not exist.',
        );
      }
      if (workCase.isClosed) {
        throw const RepositoryConstraintException(
          'Updates cannot be appended after formal case closure.',
        );
      }
      await _database
          .into(_database.workCaseUpdates)
          .insert(update.toCompanion(), mode: InsertMode.insert);
    });
  }

  @override
  Future<void> createCaseWithInitialUpdate(
    WorkCase workCase,
    WorkCaseUpdate initialUpdate,
  ) async {
    if (initialUpdate.workCaseId != workCase.id) {
      throw ArgumentError.value(
        initialUpdate.workCaseId,
        'initialUpdate.workCaseId',
        'Must match workCase.id',
      );
    }
    if (workCase.isClosed) {
      throw const RepositoryConstraintException(
        'WorkCase completion or cancellation requires WorkCaseClosure.',
      );
    }

    await _database.transaction(() async {
      await _validateSource(workCase);
      await _database
          .into(_database.workCases)
          .insert(workCase.toCompanion(), mode: InsertMode.insert);
      await _database
          .into(_database.workCaseUpdates)
          .insert(initialUpdate.toCompanion(), mode: InsertMode.insert);
    });
  }

  Future<void> _validateSource(WorkCase workCase) async {
    final itemQuery = _database.select(_database.items)
      ..where((table) => table.id.equals(workCase.itemId));
    if (await itemQuery.getSingleOrNull() == null) {
      throw RepositoryConstraintException(
        'Item ${workCase.itemId} does not exist.',
      );
    }

    switch (workCase.sourceType) {
      case WorkCaseSourceType.maintenanceTask:
        final taskQuery = _database.select(_database.tasks)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final task = await taskQuery.getSingleOrNull();
        _requireSourceItem(
          'Task',
          workCase.sourceId,
          workCase.itemId,
          task?.itemId,
        );
        if (task?.sourceType != 'scheduledMaintenance') {
          throw const RepositoryConstraintException(
            'A maintenance WorkCase must originate from a maintenance Task.',
          );
        }
      case WorkCaseSourceType.generalReminder:
        final reminderQuery = _database.select(_database.generalReminders)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final reminder = await reminderQuery.getSingleOrNull();
        _requireSourceItem(
          'GeneralReminder',
          workCase.sourceId,
          workCase.itemId,
          reminder?.itemId,
        );
      case WorkCaseSourceType.milestone:
        final milestoneQuery = _database.select(_database.milestones)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final milestone = await milestoneQuery.getSingleOrNull();
        _requireSourceItem(
          'Milestone',
          workCase.sourceId,
          workCase.itemId,
          milestone?.itemId,
        );
      case WorkCaseSourceType.manual:
        if (workCase.sourceId != null) {
          throw const RepositoryConstraintException(
            'A manual WorkCase must not have a source id.',
          );
        }
      case WorkCaseSourceType.unknown:
        if (await findCaseById(workCase.id) == null) {
          throw const RepositoryConstraintException(
            'Unknown WorkCase sources may be preserved but not created.',
          );
        }
    }
  }

  void _requireSourceItem(
    String role,
    String? id,
    String expectedItemId,
    String? actualItemId,
  ) {
    if (id == null || id.trim().isEmpty || actualItemId == null) {
      throw RepositoryConstraintException('$role ${id ?? ''} does not exist.');
    }
    if (actualItemId != expectedItemId) {
      throw RepositoryConstraintException(
        '$role $id belongs to a different Item.',
      );
    }
  }
}
