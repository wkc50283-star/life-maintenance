class MaintenancePlanStep {
  const MaintenancePlanStep({
    required this.id,
    required this.order,
    required this.title,
    required this.description,
    this.isRequired = true,
    this.photoRequired = false,
    this.noteRequired = false,
  });

  final String id;
  final int order;
  final String title;
  final String description;
  final bool isRequired;
  final bool photoRequired;
  final bool noteRequired;

  factory MaintenancePlanStep.fromJson(Map<String, dynamic> json) {
    return MaintenancePlanStep(
      id: json['id'] as String,
      order: (json['order'] as num).toInt(),
      title: json['title'] as String,
      description: json['description'] as String? ?? '',
      isRequired: json['isRequired'] is bool
          ? json['isRequired'] as bool
          : true,
      photoRequired: json['photoRequired'] is bool
          ? json['photoRequired'] as bool
          : false,
      noteRequired: json['noteRequired'] is bool
          ? json['noteRequired'] as bool
          : false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'title': title,
      'description': description,
      'isRequired': isRequired,
      'photoRequired': photoRequired,
      'noteRequired': noteRequired,
    };
  }

  MaintenancePlanStep copyWith({
    String? id,
    int? order,
    String? title,
    String? description,
    bool? isRequired,
    bool? photoRequired,
    bool? noteRequired,
  }) {
    return MaintenancePlanStep(
      id: id ?? this.id,
      order: order ?? this.order,
      title: title ?? this.title,
      description: description ?? this.description,
      isRequired: isRequired ?? this.isRequired,
      photoRequired: photoRequired ?? this.photoRequired,
      noteRequired: noteRequired ?? this.noteRequired,
    );
  }
}
