import 'package:drift/drift.dart';

import 'general_reminders.dart';
import 'items.dart';
import 'maintenance_plans.dart';
import 'milestones.dart';

@DataClassName('ScheduleRow')
@TableIndex(
  name: 'schedules_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'schedules_source_idx',
  columns: {#sourceType, #maintenancePlanId, #generalReminderId, #milestoneId},
)
@TableIndex(
  name: 'schedules_next_due_idx',
  columns: {#nextDueDate},
)
class Schedules extends Table {
  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get sourceType => text()();

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

  TextColumn get cycleType => text()();

  IntColumn get interval => integer()();

  DateTimeColumn get startDate => dateTime()();

  DateTimeColumn get nextDueDate => dateTime()();

  TextColumn get reminderTime => text().nullable()();

  TextColumn get status => text()();

  TextColumn get anchorPolicy => text().withDefault(
    const Constant('fixedCalendarPeriod'),
  )();

  DateTimeColumn get userDefinedNextDate => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get endedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(item_id) <> '')",
    "CHECK (trim(source_type) <> '')",
    'CHECK (interval > 0)',
    "CHECK ((source_type = 'maintenancePlan' AND maintenance_plan_id IS NOT NULL AND general_reminder_id IS NULL AND milestone_id IS NULL) OR (source_type = 'generalReminder' AND maintenance_plan_id IS NULL AND general_reminder_id IS NOT NULL AND milestone_id IS NULL) OR (source_type = 'milestone' AND maintenance_plan_id IS NULL AND general_reminder_id IS NULL AND milestone_id IS NOT NULL) OR (source_type = 'unknown' AND maintenance_plan_id IS NULL AND general_reminder_id IS NULL AND milestone_id IS NULL))",
    "CHECK (anchor_policy IN ('fixedCalendarPeriod', 'completionBased', 'userDefined'))",
    "CHECK (anchor_policy <> 'userDefined' OR user_defined_next_date IS NOT NULL)",
    "CHECK (cycle_type <> 'custom' OR anchor_policy = 'userDefined')",
  ];
}
