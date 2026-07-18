import 'package:drift/drift.dart';

import 'general_reminders.dart';
import 'items.dart';
import 'maintenance_plans.dart';
import 'milestones.dart';
import 'schedules.dart';

@DataClassName('TaskRow')
@TableIndex(
  name: 'tasks_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'tasks_schedule_idx',
  columns: {#scheduleId},
)
@TableIndex(
  name: 'tasks_due_date_idx',
  columns: {#dueDate},
)
@TableIndex(
  name: 'tasks_schedule_due_unique_idx',
  columns: {#scheduleId, #dueDate},
  unique: true,
)
class Tasks extends Table {
  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get sourceType => text()();

  TextColumn get scheduleId => text().nullable().references(
    Schedules,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get maintenancePlanId => text().nullable().references(
    MaintenancePlans,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get generalReminderId => text().nullable().references(
    GeneralReminders,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get milestoneId => text().nullable().references(
    Milestones,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get legacyCardId => text().nullable()();

  TextColumn get title => text()();

  DateTimeColumn get dueDate => dateTime()();

  TextColumn get status => text()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get postponedAt => dateTime().nullable()();

  DateTimeColumn get canceledAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(item_id) <> '')",
    "CHECK (trim(title) <> '')",
    "CHECK ((source_type = 'scheduledMaintenance' AND schedule_id IS NOT NULL AND maintenance_plan_id IS NOT NULL AND general_reminder_id IS NULL AND milestone_id IS NULL) OR (source_type = 'scheduledReminder' AND schedule_id IS NOT NULL AND maintenance_plan_id IS NULL AND general_reminder_id IS NOT NULL AND milestone_id IS NULL) OR (source_type = 'milestone' AND maintenance_plan_id IS NULL AND general_reminder_id IS NULL AND milestone_id IS NOT NULL) OR (source_type = 'manual' AND schedule_id IS NULL AND maintenance_plan_id IS NULL AND general_reminder_id IS NULL AND milestone_id IS NULL) OR (source_type = 'unknown'))",
  ];
}
