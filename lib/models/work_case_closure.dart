enum WorkCaseFollowUpType {
  none,
  schedule,
  reminder,
  scheduleAndReminder,
  manual,
  unknown,
}

class WorkCaseClosure {
  const WorkCaseClosure({
    required this.id,
    required this.workCaseId,
    required this.completedAt,
    required this.finalResult,
    required this.completionSummary,
    required this.totalCost,
    required this.createdAt,
    this.schemaVersion = currentSchemaVersion,
    this.followUpType = WorkCaseFollowUpType.none,
    this.followUpNotes,
    this.nextScheduleId,
    this.nextReminderTaskId,
  }) : assert(totalCost >= 0);

  static const int currentSchemaVersion = 1;
  static const Object _notProvided = Object();

  final int schemaVersion;
  final String id;
  final String workCaseId;
  final DateTime completedAt;
  final String finalResult;
  final String completionSummary;
  final int totalCost;
  final String? followUpNotes;
  final WorkCaseFollowUpType followUpType;
  final String? nextScheduleId;
  final String? nextReminderTaskId;
  final DateTime createdAt;

  bool get needsFollowUp => followUpType != WorkCaseFollowUpType.none;

  bool get createsSchedule =>
      followUpType == WorkCaseFollowUpType.schedule ||
      followUpType == WorkCaseFollowUpType.scheduleAndReminder;

  bool get createsReminder =>
      followUpType == WorkCaseFollowUpType.reminder ||
      followUpType == WorkCaseFollowUpType.scheduleAndReminder;

  factory WorkCaseClosure.fromJson(Map<String, dynamic> json) {
    return WorkCaseClosure(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      workCaseId: json['workCaseId'] as String,
      completedAt: DateTime.parse(json['completedAt'] as String),
      finalResult: json['finalResult'] as String,
      completionSummary: json['completionSummary'] as String,
      totalCost: _readNonNegativeInt(json['totalCost']),
      followUpNotes: _readNullableString(json['followUpNotes']),
      followUpType: _readFollowUpType(json['followUpType']),
      nextScheduleId: _readNullableString(json['nextScheduleId']),
      nextReminderTaskId: _readNullableString(json['nextReminderTaskId']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'workCaseId': workCaseId,
      'completedAt': completedAt.toIso8601String(),
      'finalResult': finalResult,
      'completionSummary': completionSummary,
      'totalCost': totalCost,
      'followUpNotes': followUpNotes,
      'followUpType': followUpType.name,
      'nextScheduleId': nextScheduleId,
      'nextReminderTaskId': nextReminderTaskId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  WorkCaseClosure copyWith({
    int? schemaVersion,
    String? id,
    String? workCaseId,
    DateTime? completedAt,
    String? finalResult,
    String? completionSummary,
    int? totalCost,
    Object? followUpNotes = _notProvided,
    WorkCaseFollowUpType? followUpType,
    Object? nextScheduleId = _notProvided,
    Object? nextReminderTaskId = _notProvided,
    DateTime? createdAt,
  }) {
    return WorkCaseClosure(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      workCaseId: workCaseId ?? this.workCaseId,
      completedAt: completedAt ?? this.completedAt,
      finalResult: finalResult ?? this.finalResult,
      completionSummary: completionSummary ?? this.completionSummary,
      totalCost: totalCost ?? this.totalCost,
      followUpNotes: identical(followUpNotes, _notProvided)
          ? this.followUpNotes
          : followUpNotes as String?,
      followUpType: followUpType ?? this.followUpType,
      nextScheduleId: identical(nextScheduleId, _notProvided)
          ? this.nextScheduleId
          : nextScheduleId as String?,
      nextReminderTaskId: identical(nextReminderTaskId, _notProvided)
          ? this.nextReminderTaskId
          : nextReminderTaskId as String?,
      createdAt: createdAt ?? this.createdAt,
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
  return WorkCaseClosure.currentSchemaVersion;
}

int _readNonNegativeInt(Object? value) {
  if (value is num) {
    final normalized = value.toInt();
    return normalized < 0 ? 0 : normalized;
  }
  return 0;
}

String? _readNullableString(Object? value) {
  return value is String ? value : null;
}

WorkCaseFollowUpType _readFollowUpType(Object? value) {
  if (value is String) {
    for (final candidate in WorkCaseFollowUpType.values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return WorkCaseFollowUpType.unknown;
}
