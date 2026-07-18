import 'milestone_enums.dart';

class Milestone {
  const Milestone({
    required this.id,
    required this.itemId,
    required this.title,
    required this.kind,
    required this.triggerType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
    this.description,
    this.sourcePlanId,
    this.thresholdValue,
    this.thresholdUnit,
    this.triggerDate,
    this.dependencyMilestoneId,
    this.lifeStageCode,
    this.reachedAt,
    this.acknowledgedAt,
    this.startedAt,
    this.completedAt,
    this.canceledAt,
    this.archivedAt,
    this.workCaseId,
    this.cancellationReason,
  });

  static const int currentSchemaVersion = 1;
  static const Object _notProvided = Object();

  final int schemaVersion;
  final String id;
  final String itemId;
  final String title;
  final String? description;
  final MilestoneKind kind;
  final MilestoneTriggerType triggerType;
  final String? sourcePlanId;
  final double? thresholdValue;
  final String? thresholdUnit;
  final DateTime? triggerDate;
  final String? dependencyMilestoneId;
  final String? lifeStageCode;
  final MilestoneStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? reachedAt;
  final DateTime? acknowledgedAt;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final DateTime? canceledAt;
  final DateTime? archivedAt;
  final String? workCaseId;
  final String? cancellationReason;

  bool get isReached =>
      reachedAt != null ||
      status == MilestoneStatus.reached ||
      status == MilestoneStatus.acknowledged ||
      status == MilestoneStatus.inProgress ||
      status == MilestoneStatus.completed;

  bool get isClosed =>
      status == MilestoneStatus.completed ||
      status == MilestoneStatus.canceled ||
      status == MilestoneStatus.archived;

  bool get hasCompleteTriggerDefinition {
    switch (triggerType) {
      case MilestoneTriggerType.usageYears:
      case MilestoneTriggerType.mileage:
      case MilestoneTriggerType.usageValue:
      case MilestoneTriggerType.completionCount:
      case MilestoneTriggerType.anomalyCount:
        return thresholdValue != null &&
            thresholdValue! > 0 &&
            thresholdUnit != null &&
            thresholdUnit!.trim().isNotEmpty;
      case MilestoneTriggerType.specificDate:
        return triggerDate != null;
      case MilestoneTriggerType.dependencyCompleted:
        return dependencyMilestoneId != null &&
            dependencyMilestoneId!.trim().isNotEmpty;
      case MilestoneTriggerType.lifeStage:
        return lifeStageCode != null && lifeStageCode!.trim().isNotEmpty;
      case MilestoneTriggerType.manual:
        return true;
      case MilestoneTriggerType.unknown:
        return false;
    }
  }

  factory Milestone.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);

    return Milestone(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      description: _readNullableString(json['description']),
      kind: _readEnum(
        MilestoneKind.values,
        json['kind'],
        MilestoneKind.custom,
      ),
      triggerType: _readEnum(
        MilestoneTriggerType.values,
        json['triggerType'],
        MilestoneTriggerType.unknown,
      ),
      sourcePlanId: _readNullableString(json['sourcePlanId']),
      thresholdValue: _readNullableDouble(json['thresholdValue']),
      thresholdUnit: _readNullableString(json['thresholdUnit']),
      triggerDate: _readNullableDate(json['triggerDate']),
      dependencyMilestoneId: _readNullableString(
        json['dependencyMilestoneId'],
      ),
      lifeStageCode: _readNullableString(json['lifeStageCode']),
      status: _readEnum(
        MilestoneStatus.values,
        json['status'],
        MilestoneStatus.pending,
      ),
      createdAt: createdAt,
      updatedAt: _readNullableDate(json['updatedAt']) ?? createdAt,
      reachedAt: _readNullableDate(json['reachedAt']),
      acknowledgedAt: _readNullableDate(json['acknowledgedAt']),
      startedAt: _readNullableDate(json['startedAt']),
      completedAt: _readNullableDate(json['completedAt']),
      canceledAt: _readNullableDate(json['canceledAt']),
      archivedAt: _readNullableDate(json['archivedAt']),
      workCaseId: _readNullableString(json['workCaseId']),
      cancellationReason: _readNullableString(json['cancellationReason']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'itemId': itemId,
      'title': title,
      'description': description,
      'kind': kind.name,
      'triggerType': triggerType.name,
      'sourcePlanId': sourcePlanId,
      'thresholdValue': thresholdValue,
      'thresholdUnit': thresholdUnit,
      'triggerDate': triggerDate?.toIso8601String(),
      'dependencyMilestoneId': dependencyMilestoneId,
      'lifeStageCode': lifeStageCode,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'reachedAt': reachedAt?.toIso8601String(),
      'acknowledgedAt': acknowledgedAt?.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'canceledAt': canceledAt?.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'workCaseId': workCaseId,
      'cancellationReason': cancellationReason,
    };
  }

  Milestone copyWith({
    int? schemaVersion,
    String? id,
    String? itemId,
    String? title,
    Object? description = _notProvided,
    MilestoneKind? kind,
    MilestoneTriggerType? triggerType,
    Object? sourcePlanId = _notProvided,
    Object? thresholdValue = _notProvided,
    Object? thresholdUnit = _notProvided,
    Object? triggerDate = _notProvided,
    Object? dependencyMilestoneId = _notProvided,
    Object? lifeStageCode = _notProvided,
    MilestoneStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? reachedAt = _notProvided,
    Object? acknowledgedAt = _notProvided,
    Object? startedAt = _notProvided,
    Object? completedAt = _notProvided,
    Object? canceledAt = _notProvided,
    Object? archivedAt = _notProvided,
    Object? workCaseId = _notProvided,
    Object? cancellationReason = _notProvided,
  }) {
    return Milestone(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      description: identical(description, _notProvided)
          ? this.description
          : description as String?,
      kind: kind ?? this.kind,
      triggerType: triggerType ?? this.triggerType,
      sourcePlanId: identical(sourcePlanId, _notProvided)
          ? this.sourcePlanId
          : sourcePlanId as String?,
      thresholdValue: identical(thresholdValue, _notProvided)
          ? this.thresholdValue
          : thresholdValue as double?,
      thresholdUnit: identical(thresholdUnit, _notProvided)
          ? this.thresholdUnit
          : thresholdUnit as String?,
      triggerDate: identical(triggerDate, _notProvided)
          ? this.triggerDate
          : triggerDate as DateTime?,
      dependencyMilestoneId:
          identical(dependencyMilestoneId, _notProvided)
          ? this.dependencyMilestoneId
          : dependencyMilestoneId as String?,
      lifeStageCode: identical(lifeStageCode, _notProvided)
          ? this.lifeStageCode
          : lifeStageCode as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      reachedAt: identical(reachedAt, _notProvided)
          ? this.reachedAt
          : reachedAt as DateTime?,
      acknowledgedAt: identical(acknowledgedAt, _notProvided)
          ? this.acknowledgedAt
          : acknowledgedAt as DateTime?,
      startedAt: identical(startedAt, _notProvided)
          ? this.startedAt
          : startedAt as DateTime?,
      completedAt: identical(completedAt, _notProvided)
          ? this.completedAt
          : completedAt as DateTime?,
      canceledAt: identical(canceledAt, _notProvided)
          ? this.canceledAt
          : canceledAt as DateTime?,
      archivedAt: identical(archivedAt, _notProvided)
          ? this.archivedAt
          : archivedAt as DateTime?,
      workCaseId: identical(workCaseId, _notProvided)
          ? this.workCaseId
          : workCaseId as String?,
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
  return Milestone.currentSchemaVersion;
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

double? _readNullableDouble(Object? value) {
  if (value is num) {
    return value.toDouble();
  }
  return null;
}

DateTime? _readNullableDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}
