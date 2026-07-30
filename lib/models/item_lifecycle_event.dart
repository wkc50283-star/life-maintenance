import 'item_management_period.dart';

enum ItemLifecycleEventType { created }

class ItemLifecycleEvent {
  ItemLifecycleEvent({
    required this.id,
    required this.itemId,
    required this.type,
    required this.itemNameSnapshot,
    required this.categoryIdSnapshot,
    required this.categoryDisplayNameSnapshot,
    required this.occurredAt,
    required this.createdAt,
    required Iterable<ItemManagementPeriod> managementPeriods,
    this.categorySystemCodeSnapshot,
    this.categoryCustomNameSnapshot,
  }) : managementPeriods = Set<ItemManagementPeriod>.unmodifiable(
         managementPeriods,
       );

  final String id;
  final String itemId;
  final ItemLifecycleEventType type;
  final String itemNameSnapshot;
  final String categoryIdSnapshot;
  final String? categorySystemCodeSnapshot;
  final String? categoryCustomNameSnapshot;
  final String categoryDisplayNameSnapshot;
  final DateTime occurredAt;
  final DateTime createdAt;
  final Set<ItemManagementPeriod> managementPeriods;
}
