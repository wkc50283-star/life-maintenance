class WorkCaseUpdate {
  WorkCaseUpdate({
    required this.id,
    required this.workCaseId,
    required this.occurredAt,
    required this.description,
    required this.createdAt,
    this.schemaVersion = currentSchemaVersion,
    this.contactOrVendor,
    this.result,
    this.cost,
    List<String> partsOrItems = const [],
    List<String> photoIdentifiers = const [],
    this.waitingReason,
    this.note,
    this.nextAction,
  }) : partsOrItems = List<String>.unmodifiable(partsOrItems),
       photoIdentifiers = List<String>.unmodifiable(photoIdentifiers);

  static const int currentSchemaVersion = 1;

  final int schemaVersion;
  final String id;
  final String workCaseId;
  final DateTime occurredAt;
  final String description;
  final String? contactOrVendor;
  final String? result;
  final int? cost;
  final List<String> partsOrItems;
  final List<String> photoIdentifiers;
  final String? waitingReason;
  final String? note;
  final String? nextAction;
  final DateTime createdAt;

  factory WorkCaseUpdate.fromJson(Map<String, dynamic> json) {
    return WorkCaseUpdate(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      workCaseId: json['workCaseId'] as String,
      occurredAt: DateTime.parse(json['occurredAt'] as String),
      description: json['description'] as String,
      contactOrVendor: _readNullableString(json['contactOrVendor']),
      result: _readNullableString(json['result']),
      cost: _readNullableInt(json['cost']),
      partsOrItems: _readStringList(json['partsOrItems']),
      photoIdentifiers: _readStringList(json['photoIdentifiers']),
      waitingReason: _readNullableString(json['waitingReason']),
      note: _readNullableString(json['note']),
      nextAction: _readNullableString(json['nextAction']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'workCaseId': workCaseId,
      'occurredAt': occurredAt.toIso8601String(),
      'description': description,
      'contactOrVendor': contactOrVendor,
      'result': result,
      'cost': cost,
      'partsOrItems': partsOrItems,
      'photoIdentifiers': photoIdentifiers,
      'waitingReason': waitingReason,
      'note': note,
      'nextAction': nextAction,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}

int _readSchemaVersion(Object? value) {
  if (value is int && value > 0) {
    return value;
  }
  if (value is num && value > 0) {
    return value.toInt();
  }
  return WorkCaseUpdate.currentSchemaVersion;
}

String? _readNullableString(Object? value) {
  return value is String ? value : null;
}

int? _readNullableInt(Object? value) {
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return null;
}

List<String> _readStringList(Object? value) {
  if (value is! List) {
    return const <String>[];
  }

  return value.whereType<String>().toList(growable: false);
}
