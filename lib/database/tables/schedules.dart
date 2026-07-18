import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/maintenance_plan_enums.dart';
import '../core_type_converters.dart';
import 'items.dart';
import 'maintenance_plans.dart';

@DataClassName('ScheduleRow')
@TableIndex(name: 'schedules_item_status_idx', columns: {#itemId, #status})
@TableIndex(
  name: 'schedules_plan_status_idx',
  columns: {#maintenancePlanId, #status},
)
@TableIndex(name: 'schedules_next_due_idx', columns: {#nextDueDate})
class Schedules extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(
        Items,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get sourceType =>
      text().map(const ScheduleSourceTypeSqlConverter())();
  TextColumn get maintenancePlanId => text().nullable().references(
        MaintenancePlans,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get legacyCardId => text().nullable()();
  TextColumn get cycleType => text().map(const CycleTypeSqlConverter())();
  IntColumn get interval => integer()();
  DateTimeColumn get startDate => dateTime()();
  DateTimeColumn get nextDueDate => dateTime()();
  TextColumn get title => text().nullable()();
  TextColumn get reminderTime => text().nullable()();
  TextColumn get status => text().map(const ScheduleStatusSqlConverter())();
  BoolColumn get strictPeriodMode =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
        'CHECK (interval > 0)',
        "CHECK ((source_type = 'maintenancePlan' AND maintenance_plan_id IS NOT NULL) OR (source_type != 'maintenancePlan' AND maintenance_plan_id IS NULL))",
      ];
}
