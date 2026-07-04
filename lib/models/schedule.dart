import 'enums.dart';

class Schedule {
  final String id;
  final String itemId;
  final String cardId;
  final CycleType cycleType;
  final int interval;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? reminderTime;
  final bool enabled;
  final bool strictPeriodMode;

  const Schedule({
    required this.id,
    required this.itemId,
    required this.cardId,
    required this.cycleType,
    required this.interval,
    required this.startDate,
    required this.nextDueDate,
    this.reminderTime,
    this.enabled = true,
    this.strictPeriodMode = false,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      cardId: json['cardId'] as String,
      cycleType: CycleType.values.byName(json['cycleType'] as String),
      interval: json['interval'] as int,
      startDate: DateTime.parse(json['startDate'] as String),
      nextDueDate: DateTime.parse(json['nextDueDate'] as String),
      reminderTime: json['reminderTime'] as String?,
      enabled: json['enabled'] as bool,
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
      'reminderTime': reminderTime,
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
    String? reminderTime,
    bool? enabled,
    bool? strictPeriodMode,
  }) {
    return Schedule(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      cardId: cardId ?? this.cardId,
      cycleType: cycleType ?? this.cycleType,
      interval: interval ?? this.interval,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      reminderTime: reminderTime ?? this.reminderTime,
      enabled: enabled ?? this.enabled,
      strictPeriodMode: strictPeriodMode ?? this.strictPeriodMode,
    );
  }
}
