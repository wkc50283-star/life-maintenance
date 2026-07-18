import 'package:drift/drift.dart';

import 'items.dart';
import 'maintenance_plans.dart';
import 'tasks.dart';

@DataClassName('MaintenanceRecordRow')
@TableIndex(name: 'maintenance_records_item_date_idx', columns: {#itemId, #date})
@TableIndex(name: 'maintenance_records_task_idx', columns: {#taskId})
class MaintenanceRecords extends Table {
  TextColumn get id => text()();
  TextColumn get itemId => text().references(Items, #id, onDelete: KeyAction.restrict)();
  TextColumn get taskId => text().nullable().references(Tasks, #id, onDelete: KeyAction.restrict)();
  TextColumn get maintenancePlanId => text().nullable().references(MaintenancePlans, #id, onDelete: KeyAction.restrict)();
  TextColumn get recordType => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get title => text()();
  TextColumn get issueDescription => text().nullable()();
  TextColumn get workDescription => text().nullable()();
  TextColumn get partsChanged => text().nullable()();
  IntColumn get cost => integer().nullable()();
  TextColumn get vendorName => text().nullable()();
  DateTimeColumn get warrantyUntil => dateTime().nullable()();
  TextColumn get result => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title) <> '')",
    'CHECK (cost IS NULL OR cost >= 0)',
  ];
}
