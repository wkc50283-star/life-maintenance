import 'enums.dart';
import 'maintenance_plan_enums.dart';

class MaintenancePlan {
  MaintenancePlan({
    required this.id,
    required this.itemId,
    required this.title,
    required this.planType,
    required this.riskLevel,
    required this.estimatedMinutes,
    required this.createdAt,
    required this.updatedAt,
    List<MaintenancePlanStep> steps = const [],
    this.templateCardId,
    this.description,
    this.requiredPhotos = false,
    this.requiredNote = false,
    this.safetyNotice,
    this.status = MaintenancePlanStatus.active,
    this.archivedAt,
  }) : steps = List<MaintenancePlanStep>.unmodifiable(steps);

  final String id;
  final String itemId;
  final String? templateCardId;
  final String title;
  final MaintenanceType planType;
  final String? description;
  final RiskLevel riskLevel;
  final int estimatedMinutes;
  final bool requiredPhotos;
  final bool requiredNote;
  final String? safetyNotice;
  final MaintenancePlanStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
  final List<MaintenancePlanStep> steps;
}

class MaintenancePlanStep {
  const MaintenancePlanStep({
    required this.id,
    required this.maintenancePlanId,
    required this.order,
    required this.title,
    required this.description,
    this.isRequired = true,
    this.photoRequired = false,
    this.noteRequired = false,
  });

  final String id;
  final String maintenancePlanId;
  final int order;
  final String title;
  final String description;
  final bool isRequired;
  final bool photoRequired;
  final bool noteRequired;
}
