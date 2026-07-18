import 'package:drift/drift.dart';

import '../../models/enums.dart';
import '../../models/maintenance_plan_enums.dart';
import '../core_type_converters.dart';
import 'items.dart';

@DataClassName('MaintenancePlanRow')
@TableIndex(
  name: 'maintenance_plans_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'maintenance_plans_template_idx',
  columns: {#templateCardId},
)
class MaintenancePlans extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(
        Items,
        #id,
        onUpdate: KeyAction.cascade,
        onDelete: KeyAction.restrict,
      )();
  TextColumn get templateCardId => text().nullable()();
  TextColumn get title => text()();
  TextColumn get planType =>
      text().map(const MaintenanceTypeSqlConverter())();
  TextColumn get description => text().nullable()();
  TextColumn get riskLevel => text().map(const RiskLevelSqlConverter())();
  IntColumn get estimatedMinutes => integer()();
  BoolColumn get requiredPhotos =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get requiredNote =>
      boolean().withDefault(const Constant(false))();
  TextColumn get safetyNotice => text().nullable()();
  TextColumn get status =>
      text().map(const MaintenancePlanStatusSqlConverter())();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => const [
        'CHECK (estimated_minutes >= 0)',
      ];
}
