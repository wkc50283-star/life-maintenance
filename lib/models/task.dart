import 'enums.dart';

class Task {
  final String id;
  final String itemId;
  final String cardId;
  final String scheduleId;
  final String title;
  final DateTime dueDate;
  final TaskStatus status;
  final DateTime? completedAt;
  final DateTime? postponedAt;
  final bool overdue;

  const Task({
    required this.id,
    required this.itemId,
    required this.cardId,
    required this.scheduleId,
    required this.title,
    required this.dueDate,
    this.status = TaskStatus.pending,
    this.completedAt,
    this.postponedAt,
    this.overdue = false,
  });

  Task copyWith({
    String? id,
    String? itemId,
    String? cardId,
    String? scheduleId,
    String? title,
    DateTime? dueDate,
    TaskStatus? status,
    DateTime? completedAt,
    DateTime? postponedAt,
    bool? overdue,
  }) {
    return Task(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      cardId: cardId ?? this.cardId,
      scheduleId: scheduleId ?? this.scheduleId,
      title: title ?? this.title,
      dueDate: dueDate ?? this.dueDate,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
      postponedAt: postponedAt ?? this.postponedAt,
      overdue: overdue ?? this.overdue,
    );
  }
}
