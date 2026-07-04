import 'enums.dart';

class MaintenanceCard {
  final String id;
  final String itemId;
  final String title;
  final MaintenanceType type;
  final RiskLevel riskLevel;
  final CycleType cycleType;
  final int estimatedMinutes;
  final List<MaintenanceStep> steps;
  final bool requiredPhotos;
  final bool requiredNote;
  final String? safetyNotice;
  final DateTime createdAt;

  const MaintenanceCard({
    required this.id,
    required this.itemId,
    required this.title,
    required this.type,
    required this.riskLevel,
    required this.cycleType,
    required this.estimatedMinutes,
    required this.steps,
    required this.createdAt,
    this.requiredPhotos = false,
    this.requiredNote = false,
    this.safetyNotice,
  });

  factory MaintenanceCard.fromJson(Map<String, dynamic> json) {
    return MaintenanceCard(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      title: json['title'] as String,
      type: MaintenanceType.values.byName(json['type'] as String),
      riskLevel: RiskLevel.values.byName(json['riskLevel'] as String),
      cycleType: CycleType.values.byName(json['cycleType'] as String),
      estimatedMinutes: json['estimatedMinutes'] as int,
      steps: (json['steps'] as List<dynamic>)
          .map((step) => MaintenanceStep.fromJson(step as Map<String, dynamic>))
          .toList(),
      requiredPhotos: json['requiredPhotos'] as bool,
      requiredNote: json['requiredNote'] as bool,
      safetyNotice: json['safetyNotice'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'title': title,
      'type': type.name,
      'riskLevel': riskLevel.name,
      'cycleType': cycleType.name,
      'estimatedMinutes': estimatedMinutes,
      'steps': steps.map((step) => step.toJson()).toList(),
      'requiredPhotos': requiredPhotos,
      'requiredNote': requiredNote,
      'safetyNotice': safetyNotice,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MaintenanceCard copyWith({
    String? id,
    String? itemId,
    String? title,
    MaintenanceType? type,
    RiskLevel? riskLevel,
    CycleType? cycleType,
    int? estimatedMinutes,
    List<MaintenanceStep>? steps,
    bool? requiredPhotos,
    bool? requiredNote,
    String? safetyNotice,
    DateTime? createdAt,
  }) {
    return MaintenanceCard(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      title: title ?? this.title,
      type: type ?? this.type,
      riskLevel: riskLevel ?? this.riskLevel,
      cycleType: cycleType ?? this.cycleType,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      steps: steps ?? this.steps,
      requiredPhotos: requiredPhotos ?? this.requiredPhotos,
      requiredNote: requiredNote ?? this.requiredNote,
      safetyNotice: safetyNotice ?? this.safetyNotice,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class MaintenanceStep {
  final String id;
  final String cardId;
  final int order;
  final String title;
  final String description;
  final bool isRequired;
  final bool photoRequired;
  final bool noteRequired;

  const MaintenanceStep({
    required this.id,
    required this.cardId,
    required this.order,
    required this.title,
    required this.description,
    this.isRequired = true,
    this.photoRequired = false,
    this.noteRequired = false,
  });

  factory MaintenanceStep.fromJson(Map<String, dynamic> json) {
    return MaintenanceStep(
      id: json['id'] as String,
      cardId: json['cardId'] as String,
      order: json['order'] as int,
      title: json['title'] as String,
      description: json['description'] as String,
      isRequired: json['isRequired'] as bool,
      photoRequired: json['photoRequired'] as bool,
      noteRequired: json['noteRequired'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'cardId': cardId,
      'order': order,
      'title': title,
      'description': description,
      'isRequired': isRequired,
      'photoRequired': photoRequired,
      'noteRequired': noteRequired,
    };
  }

  MaintenanceStep copyWith({
    String? id,
    String? cardId,
    int? order,
    String? title,
    String? description,
    bool? isRequired,
    bool? photoRequired,
    bool? noteRequired,
  }) {
    return MaintenanceStep(
      id: id ?? this.id,
      cardId: cardId ?? this.cardId,
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      photoRequired: photoRequired ?? this.photoRequired,
      noteRequired: noteRequired ?? this.noteRequired,
    );
  }
}
