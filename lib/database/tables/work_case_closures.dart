import 'package:drift/drift.dart';

import '../../models/work_case_closure.dart';
import 'schedules.dart';
import 'tasks.dart';
import 'work_cases.dart';

@DataClassName('WorkCaseClosureRow')
@TableIndex(name: 'work_case_closures_case_unique_idx', columns: {#workCaseId}, unique: true)
@TableIndex(name: 'work_case_closures_completed_idx', columns: {#completedAt})
class WorkCaseClosures extends Table {
  IntColumn get schemaVersion => integer().withDefault(const Constant(WorkCaseClosure.currentSchemaVersion))();
  TextColumn get id => text()();
  TextColumn get workCaseId => text().references(WorkCases, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get completedAt => dateTime()();
  TextColumn get finalResult => text()();
  TextColumn get completionSummary => text()();
  IntColumn get totalCost => integer().withDefault(const Constant(0))();
  TextColumn get followUpNotes => text().nullable()();
  TextColumn get followUpType => text().withDefault(const Constant('none'))();
  TextColumn get nextScheduleId => text().nullable().references(Schedules, #id, onDelete: KeyAction.restrict)();
  TextColumn get nextReminderTaskId => text().nullable().references(Tasks, #id, onDelete: KeyAction.restrict)();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(final_result) <> '')",
    "CHECK (trim(completion_summary) <> '')",
    'CHECK (total_cost >= 0)',
    "CHECK ((follow_up_type = 'none' AND next_schedule_id IS NULL AND next_reminder_task_id IS NULL) OR (follow_up_type = 'schedule' AND next_schedule_id IS NOT NULL AND next_reminder_task_id IS NULL) OR (follow_up_type = 'reminder' AND next_schedule_id IS NULL AND next_reminder_task_id IS NOT NULL) OR (follow_up_type = 'scheduleAndReminder' AND next_schedule_id IS NOT NULL AND next_reminder_task_id IS NOT NULL) OR (follow_up_type IN ('manual', 'unknown') AND next_schedule_id IS NULL AND next_reminder_task_id IS NULL))",
  ];
}
