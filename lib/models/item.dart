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
