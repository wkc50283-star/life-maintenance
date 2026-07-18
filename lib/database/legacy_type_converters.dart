import 'package:drift/drift.dart';

import '../models/enums.dart';

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

class TaskStatusSqlConverter extends TypeConverter<TaskStatus, String> {
  const TaskStatusSqlConverter();

  @override
  TaskStatus fromSql(String fromDb) => TaskStatus.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => TaskStatus.pending,
      );

  @override
  String toSql(TaskStatus value) => value.name;
}

class RecordTypeSqlConverter extends TypeConverter<RecordType, String> {
  const RecordTypeSqlConverter();

  @override
  RecordType fromSql(String fromDb) => RecordType.values.firstWhere(
        (value) => value.name == fromDb,
        orElse: () => RecordType.other,
      );

  @override
  String toSql(RecordType value) => value.name;
}
