import 'enums.dart';
import 'maintenance_plan_enums.dart';
import 'maintenance_plan_step.dart';

class MaintenancePlan {
  MaintenancePlan({
    required this.id,
    required this.itemId,
    required this.title,
    required this.planType,
    required this.riskLevel,
    required this.createdAt,
    required this.updatedAt,
    this.schemaVersion = currentSchemaVersion,
    this.templateCardId,
    this.description,
    this.estimatedMinutes,
    this.requiredPhotos = false,
    this.requiredNote = false,
    this.safetyNotice,
    this.status = MaintenancePlanStatus.active,
    this.archivedAt,
    List<MaintenancePlanStep> steps = const [],
  }) : steps = List<MaintenancePlanStep>.unmodifiable(
         [...steps]..sort((a, b) => a.order.compareTo(b.order)),
       );

  static const int currentSchemaVersion = 1;
  static const Object _notProvided = Object();

  final int schemaVersion;
  final String id;
  final String itemId;
  final String? templateCardId;
  final String title;
  final MaintenancePlanType planType;
  final String? description;
  final RiskLevel riskLevel;
  final int? estimatedMinutes;
  final bool requiredPhotos;
  final bool requiredNote;
  final String? safetyNotice;
  final MaintenancePlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final List<MaintenancePlanStep> steps;

  bool get isArchived => status == MaintenancePlanStatus.archived;

  bool get isActive => status == MaintenancePlanStatus.active;

  factory MaintenancePlan.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.parse(json['createdAt'] as String);

    return MaintenancePlan(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      templateCardId: _readNullableString(json['templateCardId']),
      title: json['title'] as String,
      planType: _readEnum(
        MaintenancePlanType.values,
        json['planType'],
        MaintenancePlanType.custom,
      ),
      description: _readNullableString(json['description']),
      riskLevel: _readEnum(
        RiskLevel.values,
        json['riskLevel'],
        RiskLevel.unknown,
      ),
      estimatedMinutes: _readNullablePositiveInt(json['estimatedMinutes']),
      requiredPhotos: json['requiredPhotos'] is bool
          ? json['requiredPhotos'] as bool
          : false,
      requiredNote: json['requiredNote'] is bool
          ? json['requiredNote'] as bool
          : false,
      safetyNotice: _readNullableString(json['safetyNotice']),
      status: _readEnum(
        MaintenancePlanStatus.values,
        json['status'],
        MaintenancePlanStatus.active,
      ),
      createdAt: createdAt,
      updatedAt: _readNullableDate(json['updatedAt']) ?? createdAt,
      archivedAt: _readNullableDate(json['archivedAt']),
      steps: _readSteps(json['steps']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'itemId': itemId,
      'templateCardId': templateCardId,
      'title': title,
      'planType': planType.name,
      'description': description,
      'riskLevel': riskLevel.name,
      'estimatedMinutes': estimatedMinutes,
      'requiredPhotos': requiredPhotos,
      'requiredNote': requiredNote,
      'safetyNotice': safetyNotice,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'archivedAt': archivedAt?.toIso8601String(),
      'steps': steps.map((step) => step.toJson()).toList(growable: false),
    };
  }

  MaintenancePlan copyWith({
    int? schemaVersion,
    String? id,
    String? itemId,
    Object? templateCardId = _notProvided,
    String? title,
    MaintenancePlanType? planType,
    Object? description = _notProvided,
    RiskLevel? riskLevel,
    Object? estimatedMinutes = _notProvided,
    bool? requiredPhotos,
    bool? requiredNote,
    Object? safetyNotice = _notProvided,
    MaintenancePlanStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    Object? archivedAt = _notProvided,
    List<MaintenancePlanStep>? steps,
  }) {
    return MaintenancePlan(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      templateCardId: identical(templateCardId, _notProvided)
          ? this.templateCardId
          : templateCardId as String?,
      title: title ?? this.title,
      planType: planType ?? this.planType,
      description: identical(description, _notProvided)
          ? this.description
          : description as String?,
      riskLevel: riskLevel ?? this.riskLevel,
      estimatedMinutes: identical(estimatedMinutes, _notProvided)
          ? this.estimatedMinutes
          : estimatedMinutes as int?,
      requiredPhotos: requiredPhotos ?? this.requiredPhotos,
      requiredNote: requiredNote ?? this.requiredNote,
      safetyNotice: identical(safetyNotice, _notProvided)
          ? this.safetyNotice
          : safetyNotice as String?,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      archivedAt: identical(archivedAt, _notProvided)
          ? this.archivedAt
          : archivedAt as DateTime?,
      steps: steps ?? this.steps,
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
  return MaintenancePlan.currentSchemaVersion;
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

int? _readNullablePositiveInt(Object? value) {
  if (value is num && value > 0) {
    return value.toInt();
  }
  return null;
}

List<MaintenancePlanStep> _readSteps(Object? value) {
  if (value is! List) {
    return const <MaintenancePlanStep>[];
  }

  final steps = <MaintenancePlanStep>[];
  for (final entry in value) {
    if (entry is Map<String, dynamic>) {
      try {
        steps.add(MaintenancePlanStep.fromJson(entry));
      } catch (_) {
        // Preserve the plan even when one legacy or malformed step is unreadable.
      }
    } else if (entry is Map) {
      try {
        steps.add(
          MaintenancePlanStep.fromJson(Map<String, dynamic>.from(entry)),
        );
      } catch (_) {
        // Preserve the plan even when one legacy or malformed step is unreadable.
      }
    }
  }
  return steps;
}
