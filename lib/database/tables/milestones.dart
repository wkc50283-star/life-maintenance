import 'package:drift/drift.dart';

import '../../models/milestone.dart';
import 'items.dart';
import 'maintenance_plans.dart';
import 'work_cases.dart';

@DataClassName('MilestoneRow')
@TableIndex(
  name: 'milestones_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'milestones_trigger_idx',
  columns: {#triggerType, #triggerDate},
)
@TableIndex(
  name: 'milestones_source_plan_idx',
  columns: {#sourcePlanId},
)
class Milestones extends Table {
  IntColumn get schemaVersion => integer().withDefault(
    const Constant(Milestone.currentSchemaVersion),
  )();

  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  TextColumn get kind => text()();

  TextColumn get triggerType => text()();

  TextColumn get sourcePlanId => text().nullable().references(
    MaintenancePlans,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  RealColumn get thresholdValue => real().nullable()();

  TextColumn get thresholdUnit => text().nullable()();

  DateTimeColumn get triggerDate => dateTime().nullable()();

  TextColumn get dependencyMilestoneId => text().nullable().references(
    Milestones,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get lifeStageCode => text().nullable()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get reachedAt => dateTime().nullable()();

  DateTimeColumn get acknowledgedAt => dateTime().nullable()();

  DateTimeColumn get startedAt => dateTime().nullable()();

  DateTimeColumn get completedAt => dateTime().nullable()();

  DateTimeColumn get canceledAt => dateTime().nullable()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  TextColumn get workCaseId => text().nullable().references(
    WorkCases,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get cancellationReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title) <> '')",
    'CHECK (dependency_milestone_id IS NULL OR dependency_milestone_id <> id)',
    "CHECK (trigger_type NOT IN ('usageYears', 'mileage', 'usageValue', 'completionCount', 'anomalyCount') OR (threshold_value IS NOT NULL AND threshold_value > 0 AND threshold_unit IS NOT NULL AND trim(threshold_unit) <> ''))",
    "CHECK (trigger_type <> 'specificDate' OR trigger_date IS NOT NULL)",
    "CHECK (trigger_type <> 'dependencyCompleted' OR dependency_milestone_id IS NOT NULL)",
    "CHECK (trigger_type <> 'lifeStage' OR (life_stage_code IS NOT NULL AND trim(life_stage_code) <> ''))",
  ];
}
