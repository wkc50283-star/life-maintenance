import 'package:drift/drift.dart';

import '../../models/work_case_update.dart';
import '../type_converters.dart';
import 'work_cases.dart';

@DataClassName('WorkCaseUpdateRow')
@TableIndex(
  name: 'work_case_updates_case_occurred_idx',
  columns: {#workCaseId, #occurredAt},
)
class WorkCaseUpdates extends Table {
  IntColumn get schemaVersion => integer().withDefault(
    const Constant(WorkCaseUpdate.currentSchemaVersion),
  )();

  TextColumn get id => text()();

  TextColumn get workCaseId => text().references(
    WorkCases,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  DateTimeColumn get occurredAt => dateTime()();

  TextColumn get description => text()();

  TextColumn get contactOrVendor => text().nullable()();

  TextColumn get result => text().nullable()();

  IntColumn get cost => integer().nullable()();

  TextColumn get partsOrItems => text()
      .map(const StringListSqlConverter())
      .withDefault(const Constant('[]'))();

  TextColumn get photoIdentifiers => text()
      .map(const StringListSqlConverter())
      .withDefault(const Constant('[]'))();

  TextColumn get waitingReason => text().nullable()();

  TextColumn get note => text().nullable()();

  TextColumn get nextAction => text().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
