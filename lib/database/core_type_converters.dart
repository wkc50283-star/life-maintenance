import 'package:drift/drift.dart';

import '../models/enums.dart';
import '../models/maintenance_plan_enums.dart';

class ItemCategorySqlConverter extends TypeConverter<ItemCategory, String> {
  const ItemCategorySqlConverter();

  @override
  ItemCategory fromSql(String fromDb) => ItemCategory.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => ItemCategory.other,
      );

  @override
  String toSql(ItemCategory value) => value.name;
}

class ItemStatusSqlConverter extends TypeConverter<ItemStatus, String> {
  const ItemStatusSqlConverter();

  @override
  ItemStatus fromSql(String fromDb) => ItemStatus.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => ItemStatus.active,
      );

  @override
  String toSql(ItemStatus value) => value.name;
}

class MaintenanceTypeSqlConverter
    extends TypeConverter<MaintenanceType, String> {
  const MaintenanceTypeSqlConverter();

  @override
  MaintenanceType fromSql(String fromDb) => MaintenanceType.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => MaintenanceType.inspection,
      );

  @override
  String toSql(MaintenanceType value) => value.name;
}

class RiskLevelSqlConverter extends TypeConverter<RiskLevel, String> {
  const RiskLevelSqlConverter();

  @override
  RiskLevel fromSql(String fromDb) => RiskLevel.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => RiskLevel.unknown,
      );

  @override
  String toSql(RiskLevel value) => value.name;
}

class MaintenancePlanStatusSqlConverter
    extends TypeConverter<MaintenancePlanStatus, String> {
  const MaintenancePlanStatusSqlConverter();

  @override
  MaintenancePlanStatus fromSql(String fromDb) =>
      MaintenancePlanStatus.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => MaintenancePlanStatus.active,
      );

  @override
  String toSql(MaintenancePlanStatus value) => value.name;
}

class ScheduleSourceTypeSqlConverter
    extends TypeConverter<ScheduleSourceType, String> {
  const ScheduleSourceTypeSqlConverter();

  @override
  ScheduleSourceType fromSql(String fromDb) =>
      ScheduleSourceType.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => ScheduleSourceType.unknown,
      );

  @override
  String toSql(ScheduleSourceType value) => value.name;
}

class CycleTypeSqlConverter extends TypeConverter<CycleType, String> {
  const CycleTypeSqlConverter();

  @override
  CycleType fromSql(String fromDb) => CycleType.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => CycleType.custom,
      );

  @override
  String toSql(CycleType value) => value.name;
}

class ScheduleStatusSqlConverter
    extends TypeConverter<ScheduleStatus, String> {
  const ScheduleStatusSqlConverter();

  @override
  ScheduleStatus fromSql(String fromDb) => ScheduleStatus.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => ScheduleStatus.active,
      );

  @override
  String toSql(ScheduleStatus value) => value.name;
}
