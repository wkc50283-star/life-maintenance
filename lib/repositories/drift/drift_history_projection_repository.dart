import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/attachment.dart';
import '../../models/history_projection.dart';
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
      itemAttachments: await _attachments.listForOwner(
        AttachmentOwnerType.item,
        itemId,
      ),
    );
  }

  Future<List<HistoryTaskSnapshot>> _relatedTasks(WorkCase workCase) async {
    final query = _database.select(_database.tasks);
    switch (workCase.sourceType) {
      case WorkCaseSourceType.maintenanceTask:
        query.where((table) => table.id.equals(workCase.sourceId ?? ''));
      case WorkCaseSourceType.generalReminder:
        query.where(
          (table) => table.generalReminderId.equals(workCase.sourceId ?? ''),
        );
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
