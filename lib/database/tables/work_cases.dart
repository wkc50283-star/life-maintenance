import 'package:drift/drift.dart';

import '../../models/work_case.dart';
import '../type_converters.dart';
import 'items.dart';

@DataClassName('WorkCaseRow')
@TableIndex(name: 'work_cases_item_status_idx', columns: {#itemId, #status})
@TableIndex(name: 'work_cases_source_idx', columns: {#sourceType, #sourceId})
@TableIndex(name: 'work_cases_updated_at_idx', columns: {#updatedAt})
class WorkCases extends Table {
  IntColumn get schemaVersion => integer().withDefault(
    const Constant(WorkCase.currentSchemaVersion),
  )();

  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get sourceType =>
      text().map(const WorkCaseSourceTypeSqlConverter())();

  TextColumn get sourceId => text().nullable()();

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
    "CHECK ((source_type IN ('maintenanceTask', 'generalReminder', 'milestone') AND source_id IS NOT NULL AND trim(source_id) <> '') OR (source_type IN ('manual', 'unknown') AND source_id IS NULL))",
  ];
}
