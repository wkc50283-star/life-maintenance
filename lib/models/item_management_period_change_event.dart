import 'item_custom_management_period.dart';
import 'item_management_period.dart';

class ItemManagementPeriodSnapshot {
  ItemManagementPeriodSnapshot({
    required Iterable<ItemManagementPeriod> fixed,
    required Iterable<ItemCustomManagementPeriod> custom,
  }) : fixed = Set<ItemManagementPeriod>.unmodifiable(fixed),
       custom = Set<ItemCustomManagementPeriod>.unmodifiable(custom);

  final Set<ItemManagementPeriod> fixed;
  final Set<ItemCustomManagementPeriod> custom;
}

class ItemManagementPeriodChangeEvent {
  ItemManagementPeriodChangeEvent({
    required this.id,
    required this.itemId,
    required this.occurredAt,
    required this.createdAt,
    required this.before,
    required this.after,
  });

  final String id;
  final String itemId;
  final DateTime occurredAt;
  final DateTime createdAt;
  final ItemManagementPeriodSnapshot before;
  final ItemManagementPeriodSnapshot after;
}
