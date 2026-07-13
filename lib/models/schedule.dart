import 'enums.dart';

class Schedule {
  final String id;
  final String itemId;
  final String cardId;
  final CycleType cycleType;
  final int interval;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? title;
  final String? reminderTime;
  final ScheduleStatus status;
  final bool strictPeriodMode;

  bool get enabled => status == ScheduleStatus.active;

  const Schedule({
    required this.id,
    required this.itemId,
    required this.cardId,
    required this.cycleType,
    required this.interval,
    required this.startDate,
    required this.nextDueDate,
    this.title,
    this.reminderTime,
    bool enabled = true,
    ScheduleStatus? status,
    this.strictPeriodMode = false,
  }) : status = status ?? (enabled ? ScheduleStatus.active : ScheduleStatus.ended);

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      cardId: json['cardId'] as String,
      cycleType: CycleType.values.byName(json['cycleType'] as String),
      interval: json['interval'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      title: json['title'] as String?,
      reminderTime: json['reminderTime'] as String?,
      status: _statusFromJson(json),
      strictPeriodMode: json['strictPeriodMode'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'cardId': cardId,
      'cycleType': cycleType.name,
      'interval': interval,
      'startDate': startDate.toIso8601String(),
      'nextDueDate': nextDueDate.toIso8601String(),
      'title': title,
      'reminderTime': reminderTime,
      'status': status.name,
      'enabled': enabled,
      'strictPeriodMode': strictPeriodMode,
    };
  }

  Schedule copyWith({
    String? id,
    String? itemId,
    String? cardId,
    CycleType? cycleType,
    int? interval,
    DateTime? startDate,
    DateTime? nextDueDate,
    String? title,
    String? reminderTime,
    ScheduleStatus? status,
    bool? enabled,
    bool? strictPeriodMode,
  }) {
    final nextStatus =
        status ??
        (enabled == null
            ? this.status
            : enabled
            ? ScheduleStatus.active
            : ScheduleStatus.ended);

    return Schedule(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      cardId: cardId ?? this.cardId,
      cycleType: cycleType ?? this.cycleType,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      title: title ?? this.title,
      reminderTime: reminderTime ?? this.reminderTime,
      status: nextStatus,
      strictPeriodMode: strictPeriodMode ?? this.strictPeriodMode,
    );
  }
}

ScheduleStatus _statusFromJson(Map<String, dynamic> json) {
  final statusName = json['status'];
  if (statusName is String) {
    try {
      return ScheduleStatus.values.byName(statusName);
    } catch (_) {
      // Fall back to the legacy enabled flag below.
    }
  }

  return (json['enabled'] as bool) ? ScheduleStatus.active : ScheduleStatus.ended;
}
