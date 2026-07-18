import 'package:drift/drift.dart';

import 'maintenance_plans.dart';

@DataClassName('MaintenancePlanStepRow')
@TableIndex(
  name: 'maintenance_plan_steps_plan_order_idx',
  columns: {#maintenancePlanId, #stepOrder},
  unique: true,
)
class MaintenancePlanSteps extends Table {
  TextColumn get id => text()();
  TextColumn get maintenancePlanId => text().references(
        MaintenancePlans,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.cascade,
      )();
  IntColumn get stepOrder => integer()();
  TextColumn get title => text()();
  TextColumn get description => text()();
  BoolColumn get isRequired => boolean().withDefault(const Constant(true))();
  BoolColumn get photoRequired =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get noteRequired =>
      boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
        'CHECK (step_order > 0)',
      ];
}
