import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/attachment.dart';
import '../../models/future_matter.dart';
import '../../models/history_projection.dart';
import '../../models/item_custom_management_period.dart';
import '../../models/item_lifecycle_event.dart';
import '../../models/item_management_period.dart';
import '../../models/item_management_period_change_event.dart';
import '../../models/maintenance_record.dart';
import '../../models/milestone.dart';
import '../../models/milestone_enums.dart';
import '../../models/work_case.dart';
import '../../models/work_case_enums.dart';
import '../attachment_repository.dart';
import '../history_projection_repository.dart';
import '../repository_constraint_exception.dart';
import 'drift_maintenance_record_repository.dart';
import 'schema_v2_drift_mappers.dart';
import 'work_case_drift_mappers.dart';

class DriftHistoryProjectionRepository implements HistoryProjectionRepository {
  DriftHistoryProjectionRepository({
    required AppDatabase database,
    required AttachmentRepository attachments,
  }) : _database = database,
       _attachments = attachments;

  final AppDatabase _database;
  final AttachmentRepository _attachments;

  @override
  Future<HistoryProjection> projectForItem(String itemId) async {
    await _requireItem(itemId);
    final itemCreatedEntries = await _itemCreatedEntries(itemId);
    final itemManagementPeriodChangeEntries =
        await _itemManagementPeriodChangeEntries(itemId);
    final futureMatterCreatedEntries = await _futureMatterCreatedEntries(
      itemId: itemId,
    );
    final entries = <HistoryEntry>[];
    final consumedTaskIds = <String>{};
    final consumedMilestoneIds = <String>{};

    final caseQuery = _database.select(_database.workCases)
      ..where(
        (table) =>
            table.itemId.equals(itemId) &
            table.status.isIn([
              WorkCaseStatus.completed.name,
              WorkCaseStatus.canceled.name,
            ]),
      );
    for (final row in await caseQuery.get()) {
      final workCase = row.toModel();
      final updateQuery = _database.select(_database.workCaseUpdates)
        ..where((table) => table.workCaseId.equals(workCase.id))
        ..orderBy([
          (table) => OrderingTerm.asc(table.occurredAt),
          (table) => OrderingTerm.asc(table.createdAt),
        ]);
      final updates = (await updateQuery.get())
          .map((update) => update.toModel())
          .toList(growable: false);
      final closureQuery = _database.select(_database.workCaseClosures)
        ..where((table) => table.workCaseId.equals(workCase.id));
      final closure = (await closureQuery.getSingleOrNull())?.toModel();
      final relatedTasks = await _relatedTasks(workCase);
      consumedTaskIds.addAll(relatedTasks.map((task) => task.id));
      final milestone = await _caseMilestone(workCase);
      if (milestone != null) {
        consumedMilestoneIds.add(milestone.id);
      }

      final attachmentGroups = await Future.wait<List<Attachment>>([
        for (final update in updates)
          _attachments.listForOwner(
            AttachmentOwnerType.workCaseUpdate,
            update.id,
          ),
        if (closure != null)
          _attachments.listForOwner(
            AttachmentOwnerType.workCaseClosure,
            closure.id,
          ),
      ]);
      entries.add(
        WorkCaseHistoryEntry(
          workCase: workCase,
          updates: updates,
          closure: closure,
          relatedTasks: relatedTasks,
          milestone: milestone,
          attachments: attachmentGroups.expand((group) => group).toList(),
        ),
      );
    }

    final recordQuery = _database.select(_database.maintenanceRecords)
      ..where((table) => table.itemId.equals(itemId));
    for (final row in await recordQuery.get()) {
      final task = row.taskId == null ? null : await _task(row.taskId!);
      if (task != null) {
        _requireProjectionItem('Task', task.id, itemId, task.itemId);
        consumedTaskIds.add(task.id);
      }
      final milestone = task?.milestoneId == null
          ? null
          : await _milestone(task!.milestoneId!);
      if (milestone != null) {
        _requireProjectionItem(
          'Milestone',
          milestone.id,
          itemId,
          milestone.itemId,
        );
        consumedMilestoneIds.add(milestone.id);
      }
      entries.add(
        MaintenanceRecordHistoryEntry(
          record: _record(row),
          maintenancePlanId: row.maintenancePlanId,
          task: task,
          milestone: milestone,
          attachments: await _attachments.listForOwner(
            AttachmentOwnerType.maintenanceRecord,
            row.id,
          ),
        ),
      );
    }

    final taskQuery = _database.select(_database.tasks)
      ..where((table) => table.itemId.equals(itemId));
    for (final row in await taskQuery.get()) {
      final task = _taskSnapshot(row);
      if (task.isTerminal && !consumedTaskIds.contains(task.id)) {
        entries.add(TaskHistoryEntry(task));
      }
    }

    final milestoneQuery = _database.select(_database.milestones)
      ..where((table) => table.itemId.equals(itemId));
    for (final row in await milestoneQuery.get()) {
      final milestone = row.toModel();
      if (_isTerminalMilestone(milestone) &&
          !consumedMilestoneIds.contains(milestone.id)) {
        entries.add(
          MilestoneHistoryEntry(
            milestone: milestone,
            attachments: await _attachments.listForOwner(
              AttachmentOwnerType.milestone,
              milestone.id,
            ),
          ),
        );
      }
    }

    entries.sort((left, right) {
      final byDate = right.occurredAt.compareTo(left.occurredAt);
      return byDate != 0 ? byDate : left.sourceId.compareTo(right.sourceId);
    });
    return HistoryProjection(
      itemId: itemId,
      entries: entries,
      itemCreatedEntries: itemCreatedEntries,
      itemManagementPeriodChangeEntries: itemManagementPeriodChangeEntries,
      futureMatterCreatedEntries: futureMatterCreatedEntries,
      itemAttachments: await _attachments.listForOwner(
        AttachmentOwnerType.item,
        itemId,
      ),
    );
  }

  @override
  Future<List<FutureMatterCreatedHistoryEntry>>
  projectGlobalFutureMatterCreatedEntries() => _futureMatterCreatedEntries();

  Future<List<FutureMatterCreatedHistoryEntry>> _futureMatterCreatedEntries({
    String? itemId,
  }) async {
    final query = _database.select(_database.futureMatterCreatedEvents);
    if (itemId != null) {
      query.where((table) => table.itemIdSnapshot.equals(itemId));
    }
    query.orderBy([
      (table) => OrderingTerm.desc(table.occurredAt),
      (table) => OrderingTerm.asc(table.id),
    ]);
    return [
      for (final row in await query.get())
        FutureMatterCreatedHistoryEntry(
          FutureMatterCreatedEvent(
            id: row.id,
            futureMatterId: row.futureMatterId,
            titleSnapshot: row.titleSnapshot,
            itemIdSnapshot: row.itemIdSnapshot,
            timingModeSnapshot: FutureMatterTimingMode.values.byName(
              row.timingModeSnapshot,
            ),
            specifiedDateSnapshot: row.specifiedDateSnapshot == null
                ? null
                : FutureMatterDate.parse(row.specifiedDateSnapshot!),
            specifiedMinuteOfDaySnapshot: row.specifiedMinuteOfDaySnapshot,
            recurringIntervalValueSnapshot: row.recurringIntervalValueSnapshot,
            recurringIntervalUnitSnapshot:
                row.recurringIntervalUnitSnapshot == null
                ? null
                : FutureMatterIntervalUnit.values.byName(
                    row.recurringIntervalUnitSnapshot!,
                  ),
            recurringAnchorDateSnapshot: row.recurringAnchorDateSnapshot == null
                ? null
                : FutureMatterDate.parse(row.recurringAnchorDateSnapshot!),
            recurringAnchorMinuteOfDaySnapshot:
                row.recurringAnchorMinuteOfDaySnapshot,
            conditionTypeSnapshot: row.conditionTypeSnapshot == null
                ? null
                : FutureMatterConditionType.values.byName(
                    row.conditionTypeSnapshot!,
                  ),
            conditionMaintenanceRecordIdSnapshot:
                row.conditionMaintenanceRecordIdSnapshot,
            conditionDelayValueSnapshot: row.conditionDelayValueSnapshot,
            conditionDelayUnitSnapshot: row.conditionDelayUnitSnapshot == null
                ? null
                : FutureMatterIntervalUnit.values.byName(
                    row.conditionDelayUnitSnapshot!,
                  ),
            occurredAt: row.occurredAt,
            createdAt: row.createdAt,
          ),
        ),
    ];
  }

  Future<List<ItemCreatedHistoryEntry>> _itemCreatedEntries(
    String itemId,
  ) async {
    final query = _database.select(_database.itemLifecycleEvents)
      ..where(
        (table) =>
            table.itemId.equals(itemId) &
            table.eventType.equals(ItemLifecycleEventType.created.name),
      );
    final rows = await query.get();
    final entries = <ItemCreatedHistoryEntry>[];
    for (final row in rows) {
      final periodQuery = _database.select(_database.itemLifecycleEventPeriods)
        ..where((table) => table.eventId.equals(row.id));
      final periods = (await periodQuery.get())
          .map((period) => ItemManagementPeriod.values.byName(period.period))
          .toSet();
      final customPeriodQuery = _database.select(
        _database.itemLifecycleEventCustomPeriods,
      )..where((table) => table.eventId.equals(row.id));
      final customPeriods = (await customPeriodQuery.get())
          .map(
            (period) => ItemCustomManagementPeriod(
              intervalValue: period.intervalValue,
              intervalUnit: ItemManagementIntervalUnit.values.byName(
                period.intervalUnit,
              ),
            ),
          )
          .toSet();
      entries.add(
        ItemCreatedHistoryEntry(
          ItemLifecycleEvent(
            id: row.id,
            itemId: row.itemId,
            type: ItemLifecycleEventType.values.byName(row.eventType),
            itemNameSnapshot: row.itemNameSnapshot,
            categoryIdSnapshot: row.categoryIdSnapshot,
            categorySystemCodeSnapshot: row.categorySystemCodeSnapshot,
            categoryCustomNameSnapshot: row.categoryCustomNameSnapshot,
            categoryDisplayNameSnapshot: row.categoryDisplayNameSnapshot,
            occurredAt: row.occurredAt,
            createdAt: row.createdAt,
            managementPeriods: periods,
            customManagementPeriods: customPeriods,
          ),
        ),
      );
    }
    return entries;
  }

  Future<List<ItemManagementPeriodChangeHistoryEntry>>
  _itemManagementPeriodChangeEntries(String itemId) async {
    final query = _database.select(_database.itemManagementPeriodChangeEvents)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.id),
      ]);
    final entries = <ItemManagementPeriodChangeHistoryEntry>[];
    for (final row in await query.get()) {
      entries.add(
        ItemManagementPeriodChangeHistoryEntry(
          ItemManagementPeriodChangeEvent(
            id: row.id,
            itemId: row.itemId,
            occurredAt: row.occurredAt,
            createdAt: row.createdAt,
            before: await _managementPeriodChangeSnapshot(row.id, 'before'),
            after: await _managementPeriodChangeSnapshot(row.id, 'after'),
          ),
        ),
      );
    }
    return entries;
  }

  Future<ItemManagementPeriodSnapshot> _managementPeriodChangeSnapshot(
    String eventId,
    String side,
  ) async {
    final fixedQuery =
        _database.select(_database.itemManagementPeriodChangeEventPeriods)
          ..where(
            (table) =>
                table.eventId.equals(eventId) & table.snapshotSide.equals(side),
          );
    final customQuery =
        _database.select(_database.itemManagementPeriodChangeEventCustomPeriods)
          ..where(
            (table) =>
                table.eventId.equals(eventId) & table.snapshotSide.equals(side),
          );
    return ItemManagementPeriodSnapshot(
      fixed: (await fixedQuery.get()).map(
        (row) => ItemManagementPeriod.values.byName(row.period),
      ),
      custom: (await customQuery.get()).map(
        (row) => ItemCustomManagementPeriod(
          intervalValue: row.intervalValue,
          intervalUnit: ItemManagementIntervalUnit.values.byName(
            row.intervalUnit,
          ),
        ),
      ),
    );
  }

  Future<List<HistoryTaskSnapshot>> _relatedTasks(WorkCase workCase) async {
    final query = _database.select(_database.tasks);
    switch (workCase.sourceType) {
      case WorkCaseSourceType.maintenanceTask:
        query.where((table) => table.id.equals(workCase.sourceId ?? ''));
      case WorkCaseSourceType.generalReminder:
        final sourceTaskId = workCase.sourceTaskId;
        if (sourceTaskId != null) {
          query.where((table) => table.id.equals(sourceTaskId));
        } else {
          query.where(
            (table) => table.generalReminderId.equals(workCase.sourceId ?? ''),
          );
        }
      case WorkCaseSourceType.milestone:
        query.where(
          (table) => table.milestoneId.equals(workCase.sourceId ?? ''),
        );
      case WorkCaseSourceType.manual:
      case WorkCaseSourceType.unknown:
        return const [];
    }
    final rows = await query.get();
    for (final row in rows) {
      _requireProjectionItem('Task', row.id, workCase.itemId, row.itemId);
    }
    return rows.map(_taskSnapshot).toList(growable: false);
  }

  Future<Milestone?> _caseMilestone(WorkCase workCase) async {
    if (workCase.sourceType != WorkCaseSourceType.milestone ||
        workCase.sourceId == null) {
      return null;
    }
    final milestone = await _milestone(workCase.sourceId!);
    if (milestone != null) {
      _requireProjectionItem(
        'Milestone',
        milestone.id,
        workCase.itemId,
        milestone.itemId,
      );
    }
    return milestone;
  }

  Future<HistoryTaskSnapshot?> _task(String id) async {
    final query = _database.select(_database.tasks)
      ..where((table) => table.id.equals(id));
    final row = await query.getSingleOrNull();
    return row == null ? null : _taskSnapshot(row);
  }

  Future<Milestone?> _milestone(String id) async {
    final query = _database.select(_database.milestones)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toModel();
  }

  HistoryTaskSnapshot _taskSnapshot(TaskRow row) => HistoryTaskSnapshot(
    id: row.id,
    itemId: row.itemId,
    sourceType: row.sourceType,
    scheduleId: row.scheduleId,
    maintenancePlanId: row.maintenancePlanId,
    generalReminderId: row.generalReminderId,
    milestoneId: row.milestoneId,
    title: row.title,
    dueDate: row.dueDate,
    status: row.status,
    completedAt: row.completedAt,
    postponedAt: row.postponedAt,
    canceledAt: row.canceledAt,
    createdAt: row.createdAt,
    updatedAt: row.updatedAt,
  );

  MaintenanceRecord _record(MaintenanceRecordRow row) =>
      row.toMaintenanceRecord();

  bool _isTerminalMilestone(Milestone milestone) =>
      milestone.status == MilestoneStatus.completed ||
      milestone.status == MilestoneStatus.canceled ||
      milestone.status == MilestoneStatus.archived;

  Future<void> _requireItem(String id) async {
    final query = _database.select(_database.items)
      ..where((table) => table.id.equals(id));
    if (await query.getSingleOrNull() == null) {
      throw RepositoryConstraintException('Item $id does not exist.');
    }
  }

  void _requireProjectionItem(
    String role,
    String id,
    String expectedItemId,
    String actualItemId,
  ) {
    if (actualItemId != expectedItemId) {
      throw RepositoryConstraintException(
        '$role $id belongs to a different Item.',
      );
    }
  }
}
