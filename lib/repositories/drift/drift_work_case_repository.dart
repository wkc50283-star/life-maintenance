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
  Future<List<WorkCase>> listAllCases() async {
    final query = _database.select(_database.workCases)
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return (await query.get()).map((row) => row.toModel()).toList();
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
    _validateOpenState(workCase);
    await _database.transaction(() async {
      await _validateSource(workCase);
      final existing = await findCaseById(workCase.id);
      if (existing != null && existing.isClosed) {
        throw const RepositoryConstraintException(
          'A closed WorkCase is immutable.',
        );
      }
      if (existing != null) {
        _validateIdentity(existing, workCase);
      }
      await _database
          .into(_database.workCases)
          .insertOnConflictUpdate(workCase.toCompanion());
    });
  }

  @override
  Future<void> appendUpdate(WorkCaseUpdate update) async {
    await _database.transaction(() async {
      await _requireOpenCase(update.workCaseId);
      _validateUpdate(update);
      await _database
          .into(_database.workCaseUpdates)
          .insert(update.toCompanion(), mode: InsertMode.insert);
    });
  }

  @override
  Future<void> updateStatus(
    String workCaseId,
    WorkCaseStatus status,
    DateTime updatedAt,
  ) async {
    await _database.transaction(() async {
      await _setOpenStatus(workCaseId, status, updatedAt);
    });
  }

  @override
  Future<void> appendUpdateAndSetStatus(
    WorkCaseUpdate update,
    WorkCaseStatus status,
    DateTime updatedAt,
  ) async {
    await _database.transaction(() async {
      await _requireOpenCase(update.workCaseId);
      _validateUpdate(update);
      await _database
          .into(_database.workCaseUpdates)
          .insert(update.toCompanion(), mode: InsertMode.insert);
      await _setOpenStatus(update.workCaseId, status, updatedAt);
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
    _validateOpenState(workCase);

    await _database.transaction(() async {
      await _validateSource(workCase);
      _validateUpdate(initialUpdate);
      await _database
          .into(_database.workCases)
          .insert(workCase.toCompanion(), mode: InsertMode.insert);
      await _database
          .into(_database.workCaseUpdates)
          .insert(initialUpdate.toCompanion(), mode: InsertMode.insert);
    });
  }

  Future<WorkCase> _requireOpenCase(String id) async {
    final workCase = await findCaseById(id);
    if (workCase == null) {
      throw RepositoryConstraintException('WorkCase $id does not exist.');
    }
    if (workCase.isClosed) {
      throw const RepositoryConstraintException(
        'A closed WorkCase is immutable.',
      );
    }
    return workCase;
  }

  Future<void> _setOpenStatus(
    String workCaseId,
    WorkCaseStatus status,
    DateTime updatedAt,
  ) async {
    final workCase = await _requireOpenCase(workCaseId);
    if (status == WorkCaseStatus.completed ||
        status == WorkCaseStatus.canceled) {
      throw const RepositoryConstraintException(
        'A terminal WorkCase status requires WorkCaseClosure.',
      );
    }
    if (updatedAt.isBefore(workCase.updatedAt)) {
      throw const RepositoryConstraintException(
        'A WorkCase status update cannot move updatedAt backwards.',
      );
    }
    await (_database.update(
      _database.workCases,
    )..where((table) => table.id.equals(workCaseId))).write(
      WorkCasesCompanion(status: Value(status), updatedAt: Value(updatedAt)),
    );
  }

  void _validateUpdate(WorkCaseUpdate update) {
    if (update.description.trim().isEmpty) {
      throw const RepositoryConstraintException(
        'A WorkCaseUpdate description is required.',
      );
    }
    if (update.cost case final cost? when cost < 0) {
      throw const RepositoryConstraintException(
        'A WorkCaseUpdate cost must not be negative.',
      );
    }
  }

  void _validateOpenState(WorkCase workCase) {
    if (workCase.isClosed ||
        workCase.closedAt != null ||
        workCase.canceledAt != null ||
        workCase.closeResult != null ||
        workCase.cancellationReason != null) {
      throw const RepositoryConstraintException(
        'WorkCase termination requires one formal WorkCaseClosure.',
      );
    }
  }

  void _validateIdentity(WorkCase existing, WorkCase updated) {
    if (existing.itemId != updated.itemId ||
        existing.caseType != updated.caseType ||
        existing.sourceType != updated.sourceType ||
        existing.sourceId != updated.sourceId ||
        existing.sourceTaskId != updated.sourceTaskId ||
        existing.createdAt != updated.createdAt) {
      throw const RepositoryConstraintException(
        'WorkCase Item, type, source, and creation identity are immutable.',
      );
    }
    if (updated.updatedAt.isBefore(existing.updatedAt)) {
      throw const RepositoryConstraintException(
        'A WorkCase update cannot move updatedAt backwards.',
      );
    }
  }

  Future<void> _validateSource(WorkCase workCase) async {
    if (workCase.sourceType != WorkCaseSourceType.manual &&
        workCase.caseType == null) {
      throw const RepositoryConstraintException(
        'A sourced WorkCase must have a case type.',
      );
    }
    final itemId = workCase.itemId;
    if (itemId != null) {
      final itemQuery = _database.select(_database.items)
        ..where((table) => table.id.equals(itemId));
      if (await itemQuery.getSingleOrNull() == null) {
        throw RepositoryConstraintException('Item $itemId does not exist.');
      }
    } else if (workCase.sourceType != WorkCaseSourceType.manual) {
      throw const RepositoryConstraintException(
        'A sourced WorkCase must belong to an Item.',
      );
    }

    await _validateSourceTask(workCase);

    switch (workCase.sourceType) {
      case WorkCaseSourceType.maintenanceTask:
        final sourceItemId = workCase.itemId!;
        final taskQuery = _database.select(_database.tasks)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final task = await taskQuery.getSingleOrNull();
        _requireSourceItem(
          'Task',
          workCase.sourceId,
          sourceItemId,
          task?.itemId,
        );
        if (task?.sourceType != 'scheduledMaintenance') {
          throw const RepositoryConstraintException(
            'A maintenance WorkCase must originate from a maintenance Task.',
          );
        }
      case WorkCaseSourceType.generalReminder:
        final sourceItemId = workCase.itemId!;
        final reminderQuery = _database.select(_database.generalReminders)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final reminder = await reminderQuery.getSingleOrNull();
        _requireSourceItem(
          'GeneralReminder',
          workCase.sourceId,
          sourceItemId,
          reminder?.itemId,
        );
      case WorkCaseSourceType.milestone:
        final sourceItemId = workCase.itemId!;
        final milestoneQuery = _database.select(_database.milestones)
          ..where((table) => table.id.equals(workCase.sourceId ?? ''));
        final milestone = await milestoneQuery.getSingleOrNull();
        _requireSourceItem(
          'Milestone',
          workCase.sourceId,
          sourceItemId,
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

  Future<void> _validateSourceTask(WorkCase workCase) async {
    final sourceTaskId = workCase.sourceTaskId;
    if (sourceTaskId == null) return;

    final taskQuery = _database.select(_database.tasks)
      ..where((table) => table.id.equals(sourceTaskId));
    final task = await taskQuery.getSingleOrNull();
    if (task == null ||
        workCase.itemId == null ||
        task.itemId != workCase.itemId) {
      throw RepositoryConstraintException(
        'Source Task $sourceTaskId does not exist for this Item.',
      );
    }

    final matches = switch (workCase.sourceType) {
      WorkCaseSourceType.maintenanceTask =>
        task.sourceType == 'scheduledMaintenance' &&
            workCase.sourceId == task.id,
      WorkCaseSourceType.generalReminder =>
        task.sourceType == 'scheduledReminder' &&
            workCase.sourceId == task.generalReminderId,
      WorkCaseSourceType.milestone =>
        task.sourceType == 'milestone' && workCase.sourceId == task.milestoneId,
      WorkCaseSourceType.manual || WorkCaseSourceType.unknown => false,
    };
    if (!matches) {
      throw const RepositoryConstraintException(
        'WorkCase source and source Task do not match.',
      );
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
