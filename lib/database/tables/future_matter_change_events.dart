import 'package:drift/drift.dart';

import 'future_matters.dart';

@DataClassName('FutureMatterChangeEventRow')
@TableIndex(
  name: 'future_matter_change_events_matter_idx',
  columns: {#futureMatterId},
)
class FutureMatterChangeEvents extends Table {
  TextColumn get id => text()();
  TextColumn get futureMatterId => text().references(
    FutureMatters,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();
  DateTimeColumn get occurredAt => dateTime()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
