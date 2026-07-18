import 'package:drift/drift.dart';

import '../../models/work_case.dart';
import '../type_converters.dart';
import 'items.dart';
import 'milestones.dart';
import 'tasks.dart';

@DataClassName('WorkCaseRow')
@TableIndex(name: 'work_cases_item_status_idx', columns: {#itemId, #status})
@TableIndex(name: 'work_cases_source_idx', columns: {#sourceType, #sourceId})
@TableIndex(name: 'work_cases_updated_at_idx', columns: {#updatedAt})
class WorkCases extends Table {
  IntColumn get schemaVersion => integer().withDefault(const Constant(WorkCase.currentSchemaVersion))();
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id, onDelete: KeyAction.restrict)();
  TextColumn get sourceType => text().map(const WorkCaseSourceTypeSqlConverter())();
  TextColumn get sourceId => text().nullable()();
  TextColumn get sourceTaskId => text().nullable().references(Tasks, #id, onDelete: KeyAction.restrict)();
  TextColumn get sourceMilestoneId => text().nullable().references(Milestones, #id, onDelete: KeyAction.restrict)();
  TextColumn get caseType => text().map(const WorkCaseTypeSqlConverter())();
  TextColumn get title => text()();
  TextColumn get description => text().nullable()();
  DateTimeColumn get occurredAt => dateTime().nullable()();
  DateTimeColumn get startedAt => dateTime().nullable()();
  TextColumn get status => text().map(const WorkCaseStatusSqlConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get closedAt => dateTime().nullable()();
  DateTimeColumn get canceledAt => dateTime().nullable()();
  TextColumn get closeResult => text().nullable()();
  TextColumn get cancellationReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title) <> '')",
    "CHECK ((source_type = 'maintenanceTask' AND source_task_id IS NOT NULL AND source_milestone_id IS NULL) OR (source_type = 'milestone' AND source_task_id IS NULL AND source_milestone_id IS NOT NULL) OR (source_type IN ('generalReminder', 'manual', 'unknown') AND source_task_id IS NULL AND source_milestone_id IS NULL))",
  ];
}
