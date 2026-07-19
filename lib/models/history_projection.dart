import 'attachment.dart';
import 'maintenance_record.dart';
import 'milestone.dart';
import 'work_case.dart';
import 'work_case_closure.dart';
import 'work_case_update.dart';

/// Read-only history assembled from the formal Schema v2 facts.
///
/// This model has no persistence contract. Every value can be rebuilt from
/// WorkCase, WorkCaseUpdate, WorkCaseClosure, MaintenanceRecord, Task,
/// Milestone, and Attachment rows.
class HistoryProjection {
  HistoryProjection({
    required this.itemId,
    required List<HistoryEntry> entries,
    required List<Attachment> itemAttachments,
  }) : entries = List<HistoryEntry>.unmodifiable(entries),
       itemAttachments = List<Attachment>.unmodifiable(itemAttachments);

  final String itemId;
  final List<HistoryEntry> entries;
  final List<Attachment> itemAttachments;
}

sealed class HistoryEntry {
  const HistoryEntry({required this.occurredAt, required this.sourceId});

  final DateTime occurredAt;
  final String sourceId;
}

class WorkCaseHistoryEntry extends HistoryEntry {
  WorkCaseHistoryEntry({
    required this.workCase,
    required List<WorkCaseUpdate> updates,
    required List<HistoryTaskSnapshot> relatedTasks,
    required List<Attachment> attachments,
    this.closure,
    this.milestone,
  }) : updates = List<WorkCaseUpdate>.unmodifiable(updates),
       relatedTasks = List<HistoryTaskSnapshot>.unmodifiable(relatedTasks),
       attachments = List<Attachment>.unmodifiable(attachments),
       super(
         occurredAt:
             closure?.completedAt ??
             workCase.closedAt ??
             workCase.canceledAt ??
             workCase.updatedAt,
         sourceId: workCase.id,
       );

  final WorkCase workCase;
  final List<WorkCaseUpdate> updates;
  final WorkCaseClosure? closure;
  final List<HistoryTaskSnapshot> relatedTasks;
  final Milestone? milestone;
  final List<Attachment> attachments;

  bool get hasFormalClosure => closure != null;
}

class MaintenanceRecordHistoryEntry extends HistoryEntry {
  MaintenanceRecordHistoryEntry({
    required this.record,
    required List<Attachment> attachments,
    this.maintenancePlanId,
    this.task,
    this.milestone,
  }) : attachments = List<Attachment>.unmodifiable(attachments),
       super(occurredAt: record.date, sourceId: record.id);

  final MaintenanceRecord record;
  final String? maintenancePlanId;
  final HistoryTaskSnapshot? task;
  final Milestone? milestone;
  final List<Attachment> attachments;
}

class TaskHistoryEntry extends HistoryEntry {
  TaskHistoryEntry(this.task)
    : super(occurredAt: task.terminalAt, sourceId: task.id);

  final HistoryTaskSnapshot task;
}

class MilestoneHistoryEntry extends HistoryEntry {
  MilestoneHistoryEntry({
    required this.milestone,
    required List<Attachment> attachments,
  }) : attachments = List<Attachment>.unmodifiable(attachments),
       super(
         occurredAt:
             milestone.completedAt ??
             milestone.canceledAt ??
             milestone.archivedAt ??
             milestone.updatedAt,
         sourceId: milestone.id,
       );

  final Milestone milestone;
  final List<Attachment> attachments;
}

/// Formal Task fields needed by History without changing Task into a case.
class HistoryTaskSnapshot {
  const HistoryTaskSnapshot({
    required this.id,
    required this.itemId,
    required this.sourceType,
    required this.title,
    required this.dueDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.scheduleId,
    this.maintenancePlanId,
    this.generalReminderId,
    this.milestoneId,
    this.completedAt,
    this.postponedAt,
    this.canceledAt,
  });

  final String id;
  final String itemId;
  final String sourceType;
  final String? scheduleId;
  final String? maintenancePlanId;
  final String? generalReminderId;
  final String? milestoneId;
  final String title;
  final DateTime dueDate;
  final String status;
  final DateTime? completedAt;
  final DateTime? postponedAt;
  final DateTime? canceledAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isTerminal => status == 'completed' || status == 'canceled';

  DateTime get terminalAt => completedAt ?? canceledAt ?? updatedAt;
}
