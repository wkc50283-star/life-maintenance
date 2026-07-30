import '../models/item_management_period.dart';
import '../models/item_lifecycle_event.dart';

class ItemCreationRequest {
  ItemCreationRequest({
    required this.itemId,
    required this.name,
    required this.createdAt,
    required Iterable<ItemManagementPeriod> managementPeriods,
    this.categoryId,
    this.purchaseDate,
    this.warrantyEndDate,
    this.expectedLifeYears,
    this.location,
    this.note,
  }) : managementPeriods = Set<ItemManagementPeriod>.unmodifiable(
         managementPeriods,
       );

  final String itemId;
  final String name;
  final String? categoryId;
  final DateTime createdAt;
  final DateTime? purchaseDate;
  final DateTime? warrantyEndDate;
  final int? expectedLifeYears;
  final String? location;
  final String? note;
  final Set<ItemManagementPeriod> managementPeriods;
}

class ItemCreationResult {
  const ItemCreationResult({required this.itemId, required this.createdEvent});

  final String itemId;
  final ItemLifecycleEvent createdEvent;
}

abstract interface class ItemCreationRuntime {
  Future<ItemCreationResult> create(ItemCreationRequest request);

  Future<Set<ItemManagementPeriod>> listManagementPeriods(String itemId);

  Future<ItemLifecycleEvent?> findCreatedEvent(String itemId);
}
