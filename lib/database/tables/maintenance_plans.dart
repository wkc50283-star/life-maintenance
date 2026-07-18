import 'package:drift/drift.dart';

import '../../models/maintenance_plan.dart';
import 'items.dart';

@DataClassName('MaintenancePlanRow')
@TableIndex(
  name: 'maintenance_plans_item_status_idx',
  columns: {#itemId, #status},
)
@TableIndex(
  name: 'maintenance_plans_updated_at_idx',
  columns: {#updatedAt},
)
class MaintenancePlans extends Table {
  IntColumn get schemaVersion => integer().withDefault(
    const Constant(MaintenancePlan.currentSchemaVersion),
  )();

  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get templateCardId => text().nullable()();

  TextColumn get title => text()();

  TextColumn get planType => text()();

  TextColumn get description => text().nullable()();

  TextColumn get riskLevel => text()();

  IntColumn get estimatedMinutes => integer().nullable()();

  BoolColumn get requiredPhotos => boolean().withDefault(const Constant(false))();

  BoolColumn get requiredNote => boolean().withDefault(const Constant(false))();

  TextColumn get safetyNotice => text().nullable()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title) <> '')",
    'CHECK (estimated_minutes IS NULL OR estimated_minutes > 0)',
  ];
}
