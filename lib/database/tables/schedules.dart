import 'package:drift/drift.dart';

import '../legacy_type_converters.dart';
import 'items.dart';

@DataClassName('ScheduleRow')
@TableIndex(name: 'schedules_item_status_idx', columns: {#itemId, #status})
@TableIndex(name: 'schedules_next_due_idx', columns: {#nextDueDate})
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(
        Items,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get cardId => text()();
  TextColumn get cycleType => text().map(const CycleTypeSqlConverter())();
  IntColumn get interval => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get reminderTime => text().nullable()();
  TextColumn get status => text().map(const ScheduleStatusSqlConverter())();
  BoolColumn get strictPeriodMode => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
