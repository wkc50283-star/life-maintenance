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

  factory Task.fromJson(Map<String, dynamic> json) {
    final status = _taskStatusFromJson(json['status']);

    return Task(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      cardId: json['cardId'] as String? ?? '',
      scheduleId: json['scheduleId'] as String? ?? '',
      title: json['title'] as String,
      dueDate: DateTime.parse(json['dueDate'] as String),
      status: status,
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
      postponedAt: json['postponedAt'] == null
          ? null
          : DateTime.parse(json['postponedAt'] as String),
      overdue: json['overdue'] is bool
          ? json['overdue'] as bool
          : status == TaskStatus.overdue,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'cardId': cardId,
      'scheduleId': scheduleId,
      'title': title,
      'dueDate': dueDate.toIso8601String(),
      'status': status.name,
      'completedAt': completedAt?.toIso8601String(),
      'postponedAt': postponedAt?.toIso8601String(),
      'overdue': overdue,
    };
  }

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

TaskStatus _taskStatusFromJson(Object? value) {
  if (value is String) {
    try {
      return TaskStatus.values.byName(value);
    } catch (_) {
      // Unknown or legacy task states remain pending instead of being lost.
    }
  }

  return TaskStatus.pending;
}
