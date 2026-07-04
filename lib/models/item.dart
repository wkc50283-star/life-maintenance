import 'enums.dart';

class Item {
  final String id;
  final String name;
  final ItemCategory category;
  final String? photoPath;
  final DateTime createdAt;
  final DateTime? purchaseDate;
  final DateTime? warrantyEndDate;
  final int? expectedLifeYears;
  final String? location;
  final String? note;
  final ItemStatus status;

  const Item({
    required this.id,
    required this.name,
    required this.category,
    required this.createdAt,
    this.photoPath,
    this.purchaseDate,
    this.warrantyEndDate,
    this.expectedLifeYears,
    this.location,
    this.note,
    this.status = ItemStatus.active,
  });

  factory Item.fromJson(Map<String, dynamic> json) {
    return Item(
      id: json['id'] as String,
      name: json['name'] as String,
      category: ItemCategory.values.byName(json['category'] as String),
      photoPath: json['photoPath'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
      purchaseDate: json['purchaseDate'] == null
          ? null
          : DateTime.parse(json['purchaseDate'] as String),
      warrantyEndDate: json['warrantyEndDate'] == null
          ? null
          : DateTime.parse(json['warrantyEndDate'] as String),
      expectedLifeYears: json['expectedLifeYears'] as int?,
      location: json['location'] as String?,
      note: json['note'] as String?,
      status: ItemStatus.values.byName(json['status'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'category': category.name,
      'photoPath': photoPath,
      'createdAt': createdAt.toIso8601String(),
      'purchaseDate': purchaseDate?.toIso8601String(),
      'warrantyEndDate': warrantyEndDate?.toIso8601String(),
      'expectedLifeYears': expectedLifeYears,
      'location': location,
      'note': note,
      'status': status.name,
    };
  }

  Item copyWith({
    String? id,
    String? name,
    ItemCategory? category,
    String? photoPath,
    DateTime? createdAt,
    DateTime? purchaseDate,
    DateTime? warrantyEndDate,
    int? expectedLifeYears,
    String? location,
    String? note,
    ItemStatus? status,
  }) {
    return Item(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      photoPath: photoPath ?? this.photoPath,
      createdAt: createdAt ?? this.createdAt,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      warrantyEndDate: warrantyEndDate ?? this.warrantyEndDate,
      expectedLifeYears: expectedLifeYears ?? this.expectedLifeYears,
      location: location ?? this.location,
      note: note ?? this.note,
      status: status ?? this.status,
    );
  }
}
