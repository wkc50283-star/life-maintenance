import 'package:drift/drift.dart';

import '../../models/work_case.dart';
import '../../models/work_case_enums.dart';
import '../type_converters.dart';

@DataClassName('WorkCaseRow')
@TableIndex(
  name: 'work_cases_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'work_cases_source_idx',
  columns: {#sourceType, #sourceId},
)
@TableIndex(
  name: 'work_cases_updated_at_idx',
  columns: {#updatedAt},
)
class WorkCases extends Table {
  IntColumn get schemaVersion => integer().withDefault(
    const Constant(WorkCase.currentSchemaVersion),
  )();

  TextColumn get id => text()();

  TextColumn get itemId => text()();

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

  TextColumn get closeResult => text().nullable()();

  TextColumn get cancellationReason => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
