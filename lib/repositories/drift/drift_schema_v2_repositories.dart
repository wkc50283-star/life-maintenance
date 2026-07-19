import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/attachment.dart';
import '../../models/maintenance_plan.dart';
import '../../models/maintenance_plan_enums.dart';
import '../../models/milestone.dart';
import '../../models/milestone_enums.dart';
import '../../models/work_case_closure.dart';
import '../../models/work_case_enums.dart';
import '../repository_constraint_exception.dart';
import 'drift_work_case_repository.dart';
import 'schema_v2_drift_mappers.dart';

class DriftSchemaV2Repositories {
  DriftSchemaV2Repositories(AppDatabase database)
    : itemCategories = DriftItemCategoryRepository(database),
      items = DriftItemRepository(database),
      maintenancePlans = DriftMaintenancePlanRepository(database),
      generalReminders = DriftGeneralReminderRepository(database),
      milestones = DriftMilestoneRepository(database),
      schedules = DriftScheduleRepository(database),
      tasks = DriftTaskRepository(database),
      maintenanceRecords = DriftMaintenanceRecordRepository(database),
      workCases = DriftWorkCaseRepository(database),
      workCaseClosures = DriftWorkCaseClosureRepository(database),
      attachments = DriftAttachmentRepository(database);

  final DriftItemCategoryRepository itemCategories;
  final DriftItemRepository items;
  final DriftMaintenancePlanRepository maintenancePlans;
  final DriftGeneralReminderRepository generalReminders;
  final DriftMilestoneRepository milestones;
  final DriftScheduleRepository schedules;
  final DriftTaskRepository tasks;
  final DriftMaintenanceRecordRepository maintenanceRecords;
  final DriftWorkCaseRepository workCases;
  final DriftWorkCaseClosureRepository workCaseClosures;
  final DriftAttachmentRepository attachments;
}

class DriftItemCategoryRepository {
  DriftItemCategoryRepository(this._database);

  final AppDatabase _database;

  Future<ItemCategoryRow?> findById(String id) async {
    final query = _database.select(_database.itemCategories)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<ItemCategoryRow>> listAll() {
    final query = _database.select(_database.itemCategories)
      ..orderBy([
        (table) => OrderingTerm.asc(table.sortOrder),
        (table) => OrderingTerm.asc(table.displayName),
      ]);
    return query.get();
  }

  Future<void> save(ItemCategoryRow category) async {
    if (!_hasText(category.systemCode) && !_hasText(category.customName)) {
      throw const RepositoryConstraintException(
        'ItemCategory requires a system code or custom name.',
      );
    }
    if (!_hasText(category.displayName)) {
      throw const RepositoryConstraintException(
        'ItemCategory displayName must not be empty.',
      );
    }
    final existing = await findById(category.id);
    if (existing?.status == 'archived' && existing != category) {
      throw const RepositoryConstraintException(
        'An archived ItemCategory is immutable.',
      );
    }
    if (_hasText(existing?.systemCode) &&
        existing!.systemCode != category.systemCode) {
      throw const RepositoryConstraintException(
        'An existing system category code cannot be redefined.',
      );
    }
    await _database
        .into(_database.itemCategories)
        .insertOnConflictUpdate(category.toCompanion(false));
  }

  Future<void> archive(String id, DateTime archivedAt) async {
    await _requireCategory(_database, id);
    await (_database.update(
      _database.itemCategories,
    )..where((table) => table.id.equals(id))).write(
      ItemCategoriesCompanion(
        status: const Value('archived'),
        archivedAt: Value(archivedAt),
        updatedAt: Value(archivedAt),
      ),
    );
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      await _requireCategory(_database, id);
      final itemQuery = _database.select(_database.items)
        ..where((table) => table.categoryId.equals(id))
        ..limit(1);
      if (await itemQuery.getSingleOrNull() != null) {
        throw const RepositoryConstraintException(
          'A category used by an Item can only be archived.',
        );
      }
      await (_database.delete(
        _database.itemCategories,
      )..where((table) => table.id.equals(id))).go();
    });
  }
}

class DriftItemRepository {
  DriftItemRepository(this._database);

  final AppDatabase _database;

  Future<ItemRow?> findById(String id) async {
    final query = _database.select(_database.items)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<ItemRow>> listAll() {
    final query = _database.select(_database.items)
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    return query.get();
  }

  Future<void> save(ItemRow item) async {
    await _requireCategory(_database, item.categoryId);
    final existing = await findById(item.id);
    if (existing?.status == 'archived' && existing != item) {
      throw const RepositoryConstraintException(
        'An archived Item is immutable.',
      );
    }
    await _database
        .into(_database.items)
        .insertOnConflictUpdate(item.toCompanion(false));
  }

  Future<void> archive(String id, DateTime archivedAt) async {
    await _requireItem(_database, id);
    await (_database.update(
      _database.items,
    )..where((table) => table.id.equals(id))).write(
      ItemsCompanion(
        status: const Value('archived'),
        archivedAt: Value(archivedAt),
        updatedAt: Value(archivedAt),
      ),
    );
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      await _requireItem(_database, id);
      if (await _itemHasChildren(_database, id)) {
        throw const RepositoryConstraintException(
          'An Item with related life data can only be archived.',
        );
      }
      await (_database.delete(
        _database.items,
      )..where((table) => table.id.equals(id))).go();
    });
  }
}

class DriftMaintenancePlanRepository {
  DriftMaintenancePlanRepository(this._database);

  final AppDatabase _database;

  Future<MaintenancePlan?> findById(String id) async {
    final query = _database.select(_database.maintenancePlans)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return row.toModel(await _stepsForPlan(id));
  }

  Future<List<MaintenancePlan>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.maintenancePlans)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);
    final rows = await query.get();
    final plans = <MaintenancePlan>[];
    for (final row in rows) {
      plans.add(row.toModel(await _stepsForPlan(row.id)));
    }
    return plans;
  }

  Future<void> save(MaintenancePlan plan) async {
    await _validatePlan(plan);
    await _database.transaction(() async {
      final existing = await findById(plan.id);
      if (existing?.isArchived ?? false) {
        throw const RepositoryConstraintException(
          'An archived MaintenancePlan is immutable.',
        );
      }
      await _database
          .into(_database.maintenancePlans)
          .insertOnConflictUpdate(plan.toDriftCompanion());
      await (_database.delete(
        _database.maintenancePlanSteps,
      )..where((table) => table.maintenancePlanId.equals(plan.id))).go();
      for (final step in plan.steps) {
        await _database
            .into(_database.maintenancePlanSteps)
            .insert(step.toDriftCompanion(plan.id), mode: InsertMode.insert);
      }
    });
  }

  Future<void> archive(String id, DateTime archivedAt) async {
    final plan = await findById(id);
    if (plan == null) {
      throw RepositoryConstraintException(
        'MaintenancePlan $id does not exist.',
      );
    }
    await save(
      plan.copyWith(
        status: MaintenancePlanStatus.archived,
        archivedAt: archivedAt,
        updatedAt: archivedAt,
      ),
    );
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      if (await findById(id) == null) {
        throw RepositoryConstraintException(
          'MaintenancePlan $id does not exist.',
        );
      }
      if (await _planHasReferences(_database, id)) {
        throw const RepositoryConstraintException(
          'A referenced MaintenancePlan can only be archived.',
        );
      }
      await (_database.delete(
        _database.maintenancePlanSteps,
      )..where((table) => table.maintenancePlanId.equals(id))).go();
      await (_database.delete(
        _database.maintenancePlans,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<List<MaintenancePlanStepRow>> _stepsForPlan(String id) {
    final query = _database.select(_database.maintenancePlanSteps)
      ..where((table) => table.maintenancePlanId.equals(id))
      ..orderBy([(table) => OrderingTerm.asc(table.stepOrder)]);
    return query.get();
  }

  Future<void> _validatePlan(MaintenancePlan plan) async {
    await _requireItem(_database, plan.itemId);
    if (!_hasText(plan.title)) {
      throw const RepositoryConstraintException(
        'MaintenancePlan title must not be empty.',
      );
    }
    final ids = <String>{};
    final orders = <int>{};
    for (final step in plan.steps) {
      if (!ids.add(step.id) || !orders.add(step.order)) {
        throw const RepositoryConstraintException(
          'MaintenancePlan steps require unique ids and order values.',
        );
      }
    }
  }
}

class DriftGeneralReminderRepository {
  DriftGeneralReminderRepository(this._database);

  final AppDatabase _database;

  Future<GeneralReminderRow?> findById(String id) async {
    final query = _database.select(_database.generalReminders)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<GeneralReminderRow>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.generalReminders)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);
    return query.get();
  }

  Future<void> save(GeneralReminderRow reminder) async {
    await _requireItem(_database, reminder.itemId);
    final existing = await findById(reminder.id);
    if (existing?.status == 'archived' && existing != reminder) {
      throw const RepositoryConstraintException(
        'An archived GeneralReminder is immutable.',
      );
    }
    await _database
        .into(_database.generalReminders)
        .insertOnConflictUpdate(reminder.toCompanion(false));
  }

  Future<void> archive(String id, DateTime archivedAt) async {
    if (await findById(id) == null) {
      throw RepositoryConstraintException(
        'GeneralReminder $id does not exist.',
      );
    }
    await (_database.update(
      _database.generalReminders,
    )..where((table) => table.id.equals(id))).write(
      GeneralRemindersCompanion(
        status: const Value('archived'),
        archivedAt: Value(archivedAt),
        updatedAt: Value(archivedAt),
      ),
    );
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      if (await findById(id) == null) {
        throw RepositoryConstraintException(
          'GeneralReminder $id does not exist.',
        );
      }
      if (await _reminderHasReferences(_database, id)) {
        throw const RepositoryConstraintException(
          'A referenced GeneralReminder can only be archived.',
        );
      }
      await (_database.delete(
        _database.generalReminders,
      )..where((table) => table.id.equals(id))).go();
    });
  }
}

class DriftMilestoneRepository {
  DriftMilestoneRepository(this._database);

  final AppDatabase _database;

  Future<Milestone?> findById(String id) async {
    final query = _database.select(_database.milestones)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toModel();
  }

  Future<List<Milestone>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.milestones)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  Future<void> save(Milestone milestone) async {
    await _database.transaction(() async {
      await _validateMilestone(milestone);
      final existing = await findById(milestone.id);
      if (existing != null && existing.isClosed) {
        throw const RepositoryConstraintException(
          'A closed Milestone is immutable.',
        );
      }
      await _database
          .into(_database.milestones)
          .insertOnConflictUpdate(milestone.toDriftCompanion());
    });
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      final milestone = await findById(id);
      if (milestone == null) {
        throw RepositoryConstraintException('Milestone $id does not exist.');
      }
      if (milestone.status != MilestoneStatus.pending ||
          milestone.workCaseId != null ||
          await _milestoneHasReferences(_database, id)) {
        throw const RepositoryConstraintException(
          'Only an unstarted and unreferenced Milestone may be deleted.',
        );
      }
      await (_database.delete(
        _database.milestones,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<void> _validateMilestone(Milestone milestone) async {
    await _requireItem(_database, milestone.itemId);
    if (!milestone.hasCompleteTriggerDefinition) {
      throw const RepositoryConstraintException(
        'Milestone trigger definition is incomplete or unknown.',
      );
    }
    if (milestone.sourcePlanId case final sourcePlanId?) {
      await _requireSameItem(
        'MaintenancePlan',
        sourcePlanId,
        milestone.itemId,
        await _planItemId(_database, sourcePlanId),
      );
    }
    if (milestone.dependencyMilestoneId case final dependencyId?) {
      await _requireSameItem(
        'Milestone dependency',
        dependencyId,
        milestone.itemId,
        await _milestoneItemId(_database, dependencyId),
      );
    }
    if (milestone.workCaseId case final workCaseId?) {
      await _requireSameItem(
        'WorkCase',
        workCaseId,
        milestone.itemId,
        await _workCaseItemId(_database, workCaseId),
      );
    }
  }
}

class DriftScheduleRepository {
  DriftScheduleRepository(this._database);

  final AppDatabase _database;

  Future<ScheduleRow?> findById(String id) async {
    final query = _database.select(_database.schedules)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<ScheduleRow>> listAll() {
    final query = _database.select(_database.schedules)
      ..orderBy([(table) => OrderingTerm.asc(table.nextDueDate)]);
    return query.get();
  }

  Future<List<ScheduleRow>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.schedules)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.asc(table.nextDueDate)]);
    return query.get();
  }

  Future<void> save(ScheduleRow schedule) async {
    await _database.transaction(() async {
      final existing = await findById(schedule.id);
      if (existing?.status == 'ended' && existing != schedule) {
        throw const RepositoryConstraintException(
          'An ended Schedule is immutable.',
        );
      }
      await _validateSchedule(schedule);
      await _database
          .into(_database.schedules)
          .insertOnConflictUpdate(schedule.toCompanion(false));
    });
  }

  Future<void> end(String id, DateTime endedAt) async {
    if (await findById(id) == null) {
      throw RepositoryConstraintException('Schedule $id does not exist.');
    }
    await (_database.update(
      _database.schedules,
    )..where((table) => table.id.equals(id))).write(
      SchedulesCompanion(
        status: const Value('ended'),
        endedAt: Value(endedAt),
        updatedAt: Value(endedAt),
      ),
    );
  }

  Future<void> deleteUnused(String id) async {
    await _database.transaction(() async {
      if (await findById(id) == null) {
        throw RepositoryConstraintException('Schedule $id does not exist.');
      }
      if (await _scheduleHasReferences(_database, id)) {
        throw const RepositoryConstraintException(
          'A Schedule with Tasks or closure follow-up cannot be deleted.',
        );
      }
      await (_database.delete(
        _database.schedules,
      )..where((table) => table.id.equals(id))).go();
    });
  }

  Future<void> _validateSchedule(ScheduleRow schedule) async {
    await _requireItem(_database, schedule.itemId);
    switch (schedule.sourceType) {
      case 'maintenancePlan':
        await _requireSameItem(
          'MaintenancePlan',
          schedule.maintenancePlanId,
          schedule.itemId,
          await _planItemId(_database, schedule.maintenancePlanId),
        );
      case 'generalReminder':
        await _requireSameItem(
          'GeneralReminder',
          schedule.generalReminderId,
          schedule.itemId,
          await _reminderItemId(_database, schedule.generalReminderId),
        );
      case 'milestone':
        await _requireSameItem(
          'Milestone',
          schedule.milestoneId,
          schedule.itemId,
          await _milestoneItemId(_database, schedule.milestoneId),
        );
      case 'unknown':
        if (await findById(schedule.id) == null) {
          throw const RepositoryConstraintException(
            'Unknown Schedule sources may be preserved but not created.',
          );
        }
      default:
        throw RepositoryConstraintException(
          'Unsupported Schedule source ${schedule.sourceType}.',
        );
    }
  }
}

class DriftTaskRepository {
  DriftTaskRepository(this._database);

  final AppDatabase _database;

  Future<TaskRow?> findById(String id) async {
    final query = _database.select(_database.tasks)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<TaskRow>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.tasks)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.asc(table.dueDate)]);
    return query.get();
  }

  Future<void> save(TaskRow task) async {
    await _database.transaction(() async {
      final existing = await findById(task.id);
      if (existing != null &&
          _isTerminalTaskStatus(existing.status) &&
          existing != task) {
        throw const RepositoryConstraintException(
          'A completed or canceled Task is immutable.',
        );
      }
      await _validateTask(task, isNew: existing == null);
      await _database
          .into(_database.tasks)
          .insertOnConflictUpdate(task.toCompanion(false));
    });
  }

  Future<void> _validateTask(TaskRow task, {required bool isNew}) async {
    await _requireItem(_database, task.itemId);
    switch (task.sourceType) {
      case 'scheduledMaintenance':
        final schedule = await _schedule(_database, task.scheduleId);
        await _requireSameItem(
          'Schedule',
          task.scheduleId,
          task.itemId,
          schedule?.itemId,
        );
        await _requireSameItem(
          'MaintenancePlan',
          task.maintenancePlanId,
          task.itemId,
          await _planItemId(_database, task.maintenancePlanId),
        );
        if (schedule?.sourceType != 'maintenancePlan' ||
            schedule?.maintenancePlanId != task.maintenancePlanId) {
          throw const RepositoryConstraintException(
            'Task and Schedule maintenance sources do not match.',
          );
        }
      case 'scheduledReminder':
        final schedule = await _schedule(_database, task.scheduleId);
        await _requireSameItem(
          'Schedule',
          task.scheduleId,
          task.itemId,
          schedule?.itemId,
        );
        await _requireSameItem(
          'GeneralReminder',
          task.generalReminderId,
          task.itemId,
          await _reminderItemId(_database, task.generalReminderId),
        );
        if (schedule?.sourceType != 'generalReminder' ||
            schedule?.generalReminderId != task.generalReminderId) {
          throw const RepositoryConstraintException(
            'Task and Schedule reminder sources do not match.',
          );
        }
      case 'milestone':
        await _requireSameItem(
          'Milestone',
          task.milestoneId,
          task.itemId,
          await _milestoneItemId(_database, task.milestoneId),
        );
        if (task.scheduleId != null) {
          final schedule = await _schedule(_database, task.scheduleId);
          if (schedule?.itemId != task.itemId ||
              schedule?.sourceType != 'milestone' ||
              schedule?.milestoneId != task.milestoneId) {
            throw const RepositoryConstraintException(
              'Task and Schedule milestone sources do not match.',
            );
          }
        }
      case 'manual':
        break;
      case 'unknown':
        if (isNew) {
          throw const RepositoryConstraintException(
            'Unknown Task sources may be preserved but not created.',
          );
        }
      default:
        throw RepositoryConstraintException(
          'Unsupported Task source ${task.sourceType}.',
        );
    }
  }
}

class DriftMaintenanceRecordRepository {
  DriftMaintenanceRecordRepository(this._database);

  final AppDatabase _database;

  Future<MaintenanceRecordRow?> findById(String id) async {
    final query = _database.select(_database.maintenanceRecords)
      ..where((table) => table.id.equals(id));
    return query.getSingleOrNull();
  }

  Future<List<MaintenanceRecordRow>> listForItem(String itemId) async {
    await _requireItem(_database, itemId);
    final query = _database.select(_database.maintenanceRecords)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([(table) => OrderingTerm.desc(table.date)]);
    return query.get();
  }

  Future<void> create(MaintenanceRecordRow record) async {
    await _database.transaction(() async {
      await _requireItem(_database, record.itemId);
      if (record.taskId case final taskId?) {
        await _requireSameItem(
          'Task',
          taskId,
          record.itemId,
          await _taskItemId(_database, taskId),
        );
      }
      if (record.maintenancePlanId case final planId?) {
        await _requireSameItem(
          'MaintenancePlan',
          planId,
          record.itemId,
          await _planItemId(_database, planId),
        );
      }
      await _database
          .into(_database.maintenanceRecords)
          .insert(record.toCompanion(false), mode: InsertMode.insert);
    });
  }
}

class DriftWorkCaseClosureRepository {
  DriftWorkCaseClosureRepository(this._database);

  final AppDatabase _database;

  Future<WorkCaseClosure?> findForCase(String workCaseId) async {
    final query = _database.select(_database.workCaseClosures)
      ..where((table) => table.workCaseId.equals(workCaseId));
    return (await query.getSingleOrNull())?.toModel();
  }

  Future<void> closeCase(WorkCaseClosure closure) async {
    await _finalizeCase(closure, status: WorkCaseStatus.completed);
  }

  Future<void> cancelCase(
    WorkCaseClosure closure, {
    required String cancellationReason,
  }) async {
    if (!_hasText(cancellationReason)) {
      throw const RepositoryConstraintException(
        'A canceled WorkCase requires a cancellation reason.',
      );
    }
    await _finalizeCase(
      closure,
      status: WorkCaseStatus.canceled,
      cancellationReason: cancellationReason,
    );
  }

  Future<void> _finalizeCase(
    WorkCaseClosure closure, {
    required WorkCaseStatus status,
    String? cancellationReason,
  }) async {
    await _database.transaction(() async {
      final caseQuery = _database.select(_database.workCases)
        ..where((table) => table.id.equals(closure.workCaseId));
      final workCase = await caseQuery.getSingleOrNull();
      if (workCase == null) {
        throw RepositoryConstraintException(
          'WorkCase ${closure.workCaseId} does not exist.',
        );
      }
      if (workCase.status == WorkCaseStatus.completed ||
          workCase.status == WorkCaseStatus.canceled ||
          await findForCase(workCase.id) != null) {
        throw const RepositoryConstraintException(
          'A WorkCase can have only one formal closure.',
        );
      }
      if (closure.followUpType == WorkCaseFollowUpType.unknown) {
        throw const RepositoryConstraintException(
          'Unknown closure follow-up cannot be created.',
        );
      }
      if (closure.nextScheduleId case final scheduleId?) {
        await _requireSameItem(
          'Follow-up Schedule',
          scheduleId,
          workCase.itemId,
          (await _schedule(_database, scheduleId))?.itemId,
        );
      }
      if (closure.nextReminderTaskId case final taskId?) {
        await _requireSameItem(
          'Follow-up Task',
          taskId,
          workCase.itemId,
          await _taskItemId(_database, taskId),
        );
      }
      await _database
          .into(_database.workCaseClosures)
          .insert(closure.toDriftCompanion(), mode: InsertMode.insert);
      await (_database.update(
        _database.workCases,
      )..where((table) => table.id.equals(workCase.id))).write(
        WorkCasesCompanion(
          status: Value(status),
          closedAt: Value(closure.completedAt),
          canceledAt: Value(
            status == WorkCaseStatus.canceled ? closure.completedAt : null,
          ),
          cancellationReason: Value(cancellationReason),
          updatedAt: Value(closure.updatedAt),
        ),
      );
    });
  }
}

class DriftAttachmentRepository {
  DriftAttachmentRepository(this._database);

  final AppDatabase _database;

  Future<Attachment?> findById(String id) async {
    final query = _database.select(_database.attachments)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toModel();
  }

  Future<List<Attachment>> listForOwner(
    AttachmentOwnerType ownerType,
    String ownerId,
  ) async {
    final query = _database.select(_database.attachments)
      ..where(
        (table) =>
            table.ownerType.equals(ownerType.name) &
            table.ownerId.equals(ownerId),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.createdAt)]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  Future<void> create(Attachment attachment) async {
    await _database.transaction(() async {
      if (attachment.ownerType == AttachmentOwnerType.unknown) {
        throw const RepositoryConstraintException(
          'Unknown Attachment owners cannot be created.',
        );
      }
      if (!_hasText(attachment.storageIdentifier) ||
          !_hasText(attachment.mimeType)) {
        throw const RepositoryConstraintException(
          'Attachment identifier and MIME type are required.',
        );
      }
      if (attachment.state != AttachmentState.available ||
          attachment.missingAt != null ||
          attachment.deletedAt != null) {
        throw const RepositoryConstraintException(
          'A new Attachment must start in the available state.',
        );
      }
      await _requireAttachmentOwner(_database, attachment);
      await _database
          .into(_database.attachments)
          .insert(attachment.toDriftCompanion(), mode: InsertMode.insert);
    });
  }

  Future<void> verify(String id, DateTime verifiedAt) async {
    final attachment = await _requireAttachment(id);
    if (attachment.isDeleted) {
      throw const RepositoryConstraintException(
        'A deleted Attachment cannot be verified.',
      );
    }
    await (_database.update(_database.attachments)
          ..where((table) => table.id.equals(id)))
        .write(AttachmentsCompanion(verifiedAt: Value(verifiedAt)));
  }

  Future<void> markMissing(String id, DateTime missingAt) async {
    final attachment = await _requireAttachment(id);
    if (attachment.isDeleted) {
      throw const RepositoryConstraintException(
        'A deleted Attachment cannot become missing.',
      );
    }
    await (_database.update(
      _database.attachments,
    )..where((table) => table.id.equals(id))).write(
      AttachmentsCompanion(
        state: const Value('missing'),
        missingAt: Value(missingAt),
      ),
    );
  }

  Future<void> markDeleted(String id, DateTime deletedAt) async {
    await _requireAttachment(id);
    await (_database.update(
      _database.attachments,
    )..where((table) => table.id.equals(id))).write(
      AttachmentsCompanion(
        state: const Value('deleted'),
        deletedAt: Value(deletedAt),
      ),
    );
  }

  Future<Attachment> _requireAttachment(String id) async {
    final attachment = await findById(id);
    if (attachment == null) {
      throw RepositoryConstraintException('Attachment $id does not exist.');
    }
    return attachment;
  }
}

Future<void> _requireCategory(AppDatabase database, String id) async {
  final query = database.select(database.itemCategories)
    ..where((table) => table.id.equals(id));
  if (await query.getSingleOrNull() == null) {
    throw RepositoryConstraintException('ItemCategory $id does not exist.');
  }
}

Future<void> _requireItem(AppDatabase database, String id) async {
  final query = database.select(database.items)
    ..where((table) => table.id.equals(id));
  if (await query.getSingleOrNull() == null) {
    throw RepositoryConstraintException('Item $id does not exist.');
  }
}

Future<void> _requireSameItem(
  String role,
  String? id,
  String expectedItemId,
  String? actualItemId,
) async {
  if (!_hasText(id) || actualItemId == null) {
    throw RepositoryConstraintException('$role ${id ?? ''} does not exist.');
  }
  if (actualItemId != expectedItemId) {
    throw RepositoryConstraintException(
      '$role $id belongs to a different Item.',
    );
  }
}

Future<String?> _planItemId(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.maintenancePlans)
    ..where((table) => table.id.equals(id!));
  return (await query.getSingleOrNull())?.itemId;
}

Future<String?> _reminderItemId(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.generalReminders)
    ..where((table) => table.id.equals(id!));
  return (await query.getSingleOrNull())?.itemId;
}

Future<String?> _milestoneItemId(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.milestones)
    ..where((table) => table.id.equals(id!));
  return (await query.getSingleOrNull())?.itemId;
}

Future<String?> _taskItemId(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.tasks)
    ..where((table) => table.id.equals(id!));
  return (await query.getSingleOrNull())?.itemId;
}

Future<String?> _workCaseItemId(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.workCases)
    ..where((table) => table.id.equals(id!));
  return (await query.getSingleOrNull())?.itemId;
}

Future<ScheduleRow?> _schedule(AppDatabase database, String? id) async {
  if (!_hasText(id)) return null;
  final query = database.select(database.schedules)
    ..where((table) => table.id.equals(id!));
  return query.getSingleOrNull();
}

Future<bool> _itemHasChildren(AppDatabase database, String itemId) async {
  final plan = database.select(database.maintenancePlans)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final reminder = database.select(database.generalReminders)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final milestone = database.select(database.milestones)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final schedule = database.select(database.schedules)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final task = database.select(database.tasks)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final record = database.select(database.maintenanceRecords)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final workCase = database.select(database.workCases)
    ..where((table) => table.itemId.equals(itemId))
    ..limit(1);
  final attachment = database.select(database.attachments)
    ..where(
      (table) => table.ownerType.equals('item') & table.ownerId.equals(itemId),
    )
    ..limit(1);
  return await plan.getSingleOrNull() != null ||
      await reminder.getSingleOrNull() != null ||
      await milestone.getSingleOrNull() != null ||
      await schedule.getSingleOrNull() != null ||
      await task.getSingleOrNull() != null ||
      await record.getSingleOrNull() != null ||
      await workCase.getSingleOrNull() != null ||
      await attachment.getSingleOrNull() != null;
}

Future<bool> _planHasReferences(AppDatabase database, String id) async {
  final schedule = database.select(database.schedules)
    ..where((table) => table.maintenancePlanId.equals(id))
    ..limit(1);
  final task = database.select(database.tasks)
    ..where((table) => table.maintenancePlanId.equals(id))
    ..limit(1);
  final record = database.select(database.maintenanceRecords)
    ..where((table) => table.maintenancePlanId.equals(id))
    ..limit(1);
  final milestone = database.select(database.milestones)
    ..where((table) => table.sourcePlanId.equals(id))
    ..limit(1);
  return await schedule.getSingleOrNull() != null ||
      await task.getSingleOrNull() != null ||
      await record.getSingleOrNull() != null ||
      await milestone.getSingleOrNull() != null;
}

Future<bool> _reminderHasReferences(AppDatabase database, String id) async {
  final schedule = database.select(database.schedules)
    ..where((table) => table.generalReminderId.equals(id))
    ..limit(1);
  final task = database.select(database.tasks)
    ..where((table) => table.generalReminderId.equals(id))
    ..limit(1);
  final workCase = database.select(database.workCases)
    ..where(
      (table) =>
          table.sourceType.equals(WorkCaseSourceType.generalReminder.name) &
          table.sourceId.equals(id),
    )
    ..limit(1);
  return await schedule.getSingleOrNull() != null ||
      await task.getSingleOrNull() != null ||
      await workCase.getSingleOrNull() != null;
}

Future<bool> _milestoneHasReferences(AppDatabase database, String id) async {
  final dependent = database.select(database.milestones)
    ..where((table) => table.dependencyMilestoneId.equals(id))
    ..limit(1);
  final schedule = database.select(database.schedules)
    ..where((table) => table.milestoneId.equals(id))
    ..limit(1);
  final task = database.select(database.tasks)
    ..where((table) => table.milestoneId.equals(id))
    ..limit(1);
  final workCase = database.select(database.workCases)
    ..where(
      (table) =>
          table.sourceType.equals(WorkCaseSourceType.milestone.name) &
          table.sourceId.equals(id),
    )
    ..limit(1);
  final attachment = database.select(database.attachments)
    ..where(
      (table) =>
          table.ownerType.equals(AttachmentOwnerType.milestone.name) &
          table.ownerId.equals(id),
    )
    ..limit(1);
  return await dependent.getSingleOrNull() != null ||
      await schedule.getSingleOrNull() != null ||
      await task.getSingleOrNull() != null ||
      await workCase.getSingleOrNull() != null ||
      await attachment.getSingleOrNull() != null;
}

Future<bool> _scheduleHasReferences(AppDatabase database, String id) async {
  final task = database.select(database.tasks)
    ..where((table) => table.scheduleId.equals(id))
    ..limit(1);
  final closure = database.select(database.workCaseClosures)
    ..where((table) => table.nextScheduleId.equals(id))
    ..limit(1);
  return await task.getSingleOrNull() != null ||
      await closure.getSingleOrNull() != null;
}

Future<void> _requireAttachmentOwner(
  AppDatabase database,
  Attachment attachment,
) async {
  final exists = switch (attachment.ownerType) {
    AttachmentOwnerType.item => await _itemExists(database, attachment.ownerId),
    AttachmentOwnerType.maintenanceRecord => await _recordExists(
      database,
      attachment.ownerId,
    ),
    AttachmentOwnerType.workCaseUpdate => await _updateExists(
      database,
      attachment.ownerId,
    ),
    AttachmentOwnerType.workCaseClosure => await _closureExists(
      database,
      attachment.ownerId,
    ),
    AttachmentOwnerType.milestone => await _milestoneExists(
      database,
      attachment.ownerId,
    ),
    AttachmentOwnerType.unknown => false,
  };
  if (!exists) {
    throw RepositoryConstraintException(
      'Attachment owner ${attachment.ownerType.name}/${attachment.ownerId} '
      'does not exist.',
    );
  }
}

Future<bool> _itemExists(AppDatabase database, String id) async {
  final query = database.select(database.items)
    ..where((table) => table.id.equals(id));
  return await query.getSingleOrNull() != null;
}

Future<bool> _recordExists(AppDatabase database, String id) async {
  final query = database.select(database.maintenanceRecords)
    ..where((table) => table.id.equals(id));
  return await query.getSingleOrNull() != null;
}

Future<bool> _updateExists(AppDatabase database, String id) async {
  final query = database.select(database.workCaseUpdates)
    ..where((table) => table.id.equals(id));
  return await query.getSingleOrNull() != null;
}

Future<bool> _closureExists(AppDatabase database, String id) async {
  final query = database.select(database.workCaseClosures)
    ..where((table) => table.id.equals(id));
  return await query.getSingleOrNull() != null;
}

Future<bool> _milestoneExists(AppDatabase database, String id) async {
  final query = database.select(database.milestones)
    ..where((table) => table.id.equals(id));
  return await query.getSingleOrNull() != null;
}

bool _isTerminalTaskStatus(String status) =>
    status == 'completed' || status == 'canceled';

bool _hasText(String? value) => value != null && value.trim().isNotEmpty;
