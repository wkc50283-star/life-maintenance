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
