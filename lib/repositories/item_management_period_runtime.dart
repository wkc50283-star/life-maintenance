import '../models/item_custom_management_period.dart';
import '../models/item_management_period.dart';
import '../models/item_management_period_change_event.dart';

class ItemManagementPeriodChangeRequest {
  ItemManagementPeriodChangeRequest({
    required this.eventId,
    required this.itemId,
    required this.occurredAt,
    required Iterable<ItemManagementPeriod> fixed,
    required Iterable<ItemCustomManagementPeriod> custom,
  }) : fixed = Set<ItemManagementPeriod>.unmodifiable(fixed),
       custom = List<ItemCustomManagementPeriod>.unmodifiable(custom);

  final String eventId;
  final String itemId;
  final DateTime occurredAt;
  final Set<ItemManagementPeriod> fixed;
  final List<ItemCustomManagementPeriod> custom;
}

abstract interface class ItemManagementPeriodRuntime {
  Future<ItemManagementPeriodSnapshot> readCurrent(String itemId);

  Future<ItemManagementPeriodChangeEvent?> replace(
    ItemManagementPeriodChangeRequest request,
  );

  Future<List<ItemManagementPeriodChangeEvent>> listChanges(String itemId);
}
