import 'enums.dart';

class MaintenanceRecord {
  final String id;
  final String itemId;
  final String? taskId;
  final RecordType recordType;
  final DateTime date;
  final String title;
  final String? issueDescription;
  final String? workDescription;
  final List<String> partsChanged;
  final int? cost;
  final String? vendorName;
  final DateTime? warrantyUntil;
  final String? result;
  final List<String> photos;
  final String? note;
  final DateTime createdAt;

  const MaintenanceRecord({
    required this.id,
    required this.itemId,
    required this.recordType,
    required this.date,
    required this.title,
    required this.createdAt,
    this.taskId,
    this.issueDescription,
    this.workDescription,
    this.partsChanged = const [],
    this.cost,
    this.vendorName,
    this.warrantyUntil,
    this.result,
    this.photos = const [],
    this.note,
  });

  factory MaintenanceRecord.fromJson(Map<String, dynamic> json) {
    return MaintenanceRecord(
      id: json['id'] as String,
      itemId: json['itemId'] as String,
      taskId: json['taskId'] as String?,
      recordType: RecordType.values.byName(json['recordType'] as String),
      date: DateTime.parse(json['date'] as String),
      title: json['title'] as String,
      issueDescription: json['issueDescription'] as String?,
      workDescription: json['workDescription'] as String?,
      partsChanged: List<String>.from(json['partsChanged'] as List<dynamic>),
      cost: json['cost'] as int?,
      vendorName: json['vendorName'] as String?,
      warrantyUntil: json['warrantyUntil'] == null
          ? null
          : DateTime.parse(json['warrantyUntil'] as String),
      result: json['result'] as String?,
      photos: List<String>.from(json['photos'] as List<dynamic>),
      note: json['note'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'itemId': itemId,
      'taskId': taskId,
      'recordType': recordType.name,
      'date': date.toIso8601String(),
      'title': title,
      'issueDescription': issueDescription,
      'workDescription': workDescription,
      'partsChanged': partsChanged,
      'cost': cost,
      'vendorName': vendorName,
      'warrantyUntil': warrantyUntil?.toIso8601String(),
      'result': result,
      'photos': photos,
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  MaintenanceRecord copyWith({
    String? id,
    String? itemId,
    String? taskId,
    RecordType? recordType,
    DateTime? date,
    String? title,
    String? issueDescription,
    String? workDescription,
    List<String>? partsChanged,
    int? cost,
    String? vendorName,
    DateTime? warrantyUntil,
    String? result,
    List<String>? photos,
    String? note,
    DateTime? createdAt,
  }) {
    return MaintenanceRecord(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      taskId: taskId ?? this.taskId,
      recordType: recordType ?? this.recordType,
      date: date ?? this.date,
      title: title ?? this.title,
      issueDescription: issueDescription ?? this.issueDescription,
      workDescription: workDescription ?? this.workDescription,
      partsChanged: partsChanged ?? this.partsChanged,
      cost: cost ?? this.cost,
      vendorName: vendorName ?? this.vendorName,
      warrantyUntil: warrantyUntil ?? this.warrantyUntil,
      result: result ?? this.result,
      photos: photos ?? this.photos,
      note: note ?? this.note,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
