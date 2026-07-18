import 'work_case_enums.dart';

class WorkCase {
  const WorkCase({
    required this.id,
    required this.itemId,
    required this.sourceType,
    required this.caseType,
    required this.title,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
    this.sourceId,
    this.description,
    this.occurredAt,
    this.startedAt,
    this.closedAt,
    this.canceledAt,
    this.closeResult,
    this.cancellationReason,
  });

  static const int currentSchemaVersion = 1;
  static const Object _notProvided = Object();

  final int schemaVersion;
  final String id;
  final String itemId;
  final WorkCaseSourceType sourceType;
  final String? sourceId;
  final WorkCaseType caseType;
  final String title;
  final String? description;
  final DateTime? occurredAt;
  final DateTime? startedAt;
  final WorkCaseStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? closedAt;
  final DateTime? canceledAt;
  final String? closeResult;
  final String? cancellationReason;

  bool get isClosed =>
      status == WorkCaseStatus.completed || status == WorkCaseStatus.canceled;

  bool get isOpen => !isClosed;

  factory WorkCase.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);

    return WorkCase(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      sourceType: _readEnum(
        WorkCaseSourceType.values,
        json['sourceType'],
        WorkCaseSourceType.unknown,
      ),
      sourceId: _readNullableString(json['sourceId']),
      caseType: _readEnum(
        WorkCaseType.values,
        json['caseType'],
        WorkCaseType.other,
      ),
      title: json['title'] as String,
      description: _readNullableString(json['description']),
      occurredAt: _readNullableDate(json['occurredAt']),
      startedAt: _readNullableDate(json['startedAt']),
      status: _readEnum(
        WorkCaseStatus.values,
        json['status'],
        WorkCaseStatus.notStarted,
      ),
      createdAt: createdAt,
      updatedAt: _readNullableDate(json['updatedAt']) ?? createdAt,
      closedAt: _readNullableDate(json['closedAt']),
      canceledAt: _readNullableDate(json['canceledAt']),
      closeResult: _readNullableString(json['closeResult']),
      cancellationReason: _readNullableString(json['cancellationReason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'itemId': itemId,
      'sourceType': sourceType.name,
      'sourceId': sourceId,
      'caseType': caseType.name,
      'title': title,
      'description': description,
      'occurredAt': occurredAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'closedAt': closedAt?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'closeResult': closeResult,
      'cancellationReason': cancellationReason,
    };
  }

  WorkCase copyWith({
    int? schemaVersion,
    String? id,
    String? itemId,
    WorkCaseSourceType? sourceType,
    Object? sourceId = _notProvided,
    WorkCaseType? caseType,
    String? title,
    Object? description = _notProvided,
    Object? occurredAt = _notProvided,
    Object? startedAt = _notProvided,
    WorkCaseStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? closedAt = _notProvided,
    Object? canceledAt = _notProvided,
    Object? closeResult = _notProvided,
    Object? cancellationReason = _notProvided,
  }) {
    return WorkCase(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      sourceType: sourceType ?? this.sourceType,
      sourceId: identical(sourceId, _notProvided)
          ? this.sourceId
          : sourceId as String?,
      caseType: caseType ?? this.caseType,
      title: title ?? this.title,
      description: identical(description, _notProvided)
          ? this.description
          : description as String?,
      occurredAt: identical(occurredAt, _notProvided)
          ? this.occurredAt
          : occurredAt as DateTime?,
      startedAt: identical(startedAt, _notProvided)
          ? this.startedAt
          : startedAt as DateTime?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      closedAt: identical(closedAt, _notProvided)
          ? this.closedAt
          : closedAt as DateTime?,
      canceledAt: identical(canceledAt, _notProvided)
          ? this.canceledAt
          : canceledAt as DateTime?,
      closeResult: identical(closeResult, _notProvided)
          ? this.closeResult
          : closeResult as String?,
      cancellationReason: identical(cancellationReason, _notProvided)
          ? this.cancellationReason
          : cancellationReason as String?,
    );
  }
}

int _readSchemaVersion(Object? value) {
  if (value is int && value > 0) {
    return value;
  }
  if (value is num && value > 0) {
    return value.toInt();
  }
  return WorkCase.currentSchemaVersion;
}

T _readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return fallback;
}

String? _readNullableString(Object? value) {
  return value is String ? value : null;
}

DateTime? _readNullableDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
