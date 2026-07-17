import 'dart:convert';

import 'package:drift/drift.dart';

import '../models/work_case_enums.dart';

class WorkCaseSourceTypeSqlConverter
    extends TypeConverter<WorkCaseSourceType, String> {
  const WorkCaseSourceTypeSqlConverter();

  @override
  WorkCaseSourceType fromSql(String fromDb) {
    return WorkCaseSourceType.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => WorkCaseSourceType.unknown,
    );
  }

  @override
  String toSql(WorkCaseSourceType value) => value.name;
}

class WorkCaseTypeSqlConverter extends TypeConverter<WorkCaseType, String> {
  const WorkCaseTypeSqlConverter();

  @override
  WorkCaseType fromSql(String fromDb) {
    return WorkCaseType.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => WorkCaseType.other,
    );
  }

  @override
  String toSql(WorkCaseType value) => value.name;
}

class WorkCaseStatusSqlConverter
    extends TypeConverter<WorkCaseStatus, String> {
  const WorkCaseStatusSqlConverter();

  @override
  WorkCaseStatus fromSql(String fromDb) {
    return WorkCaseStatus.values.firstWhere(
      (value) => value.name == fromDb,
      orElse: () => WorkCaseStatus.notStarted,
    );
  }

  @override
  String toSql(WorkCaseStatus value) => value.name;
}

class StringListSqlConverter extends TypeConverter<List<String>, String> {
  const StringListSqlConverter();

  @override
  List<String> fromSql(String fromDb) {
    try {
      final decoded = jsonDecode(fromDb);
      if (decoded is! List) {
        return const <String>[];
      }

      return List<String>.unmodifiable(decoded.whereType<String>());
    } catch (_) {
      return const <String>[];
    }
  }

  @override
  String toSql(List<String> value) => jsonEncode(value);
}
