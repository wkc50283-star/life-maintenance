import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/item_lifecycle_event.dart';
import '../../models/item_management_period.dart';
import '../../models/item_system_category.dart';
import '../item_creation_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftItemCreationRuntime implements ItemCreationRuntime {
  DriftItemCreationRuntime(this._database);

  final AppDatabase _database;

  @override
  Future<ItemCreationResult> create(ItemCreationRequest request) {
    return _database.transaction(() async {
      final itemId = request.itemId.trim();
      final name = request.name.trim();
      if (itemId.isEmpty || name.isEmpty) {
        throw const RepositoryConstraintException(
          'Item ID and name must not be empty.',
        );
      }
      final categoryId = request.categoryId?.trim().isNotEmpty == true
          ? request.categoryId!.trim()
          : ItemSystemCategory.unclassifiedId;
      final categoryQuery = _database.select(_database.itemCategories)
        ..where((table) => table.id.equals(categoryId));
      final category = await categoryQuery.getSingleOrNull();
      if (category == null || category.status != 'active') {
        throw RepositoryConstraintException(
          'Item category $categoryId is not available.',
        );
      }

      final eventId = 'item-created-$itemId';
      await _database
          .into(_database.items)
          .insert(
            ItemsCompanion.insert(
              id: itemId,
              name: name,
              categoryId: categoryId,
              createdAt: request.createdAt,
              updatedAt: request.createdAt,
              purchaseDate: Value(request.purchaseDate),
              warrantyEndDate: Value(request.warrantyEndDate),
              expectedLifeYears: Value(request.expectedLifeYears),
              location: Value(_textOrNull(request.location)),
              note: Value(_textOrNull(request.note)),
              status: 'active',
            ),
          );

      for (final period in request.managementPeriods) {
        await _database
            .into(_database.itemManagementPeriods)
            .insert(
              ItemManagementPeriodsCompanion.insert(
                itemId: itemId,
                period: period.name,
                createdAt: request.createdAt,
              ),
            );
      }

      await _database
          .into(_database.itemLifecycleEvents)
          .insert(
            ItemLifecycleEventsCompanion.insert(
              id: eventId,
              itemId: itemId,
              eventType: ItemLifecycleEventType.created.name,
              itemNameSnapshot: name,
              categoryIdSnapshot: category.id,
              categorySystemCodeSnapshot: Value(category.systemCode),
              categoryCustomNameSnapshot: Value(category.customName),
              categoryDisplayNameSnapshot: category.displayName,
              occurredAt: request.createdAt,
              createdAt: request.createdAt,
            ),
          );

      for (final period in request.managementPeriods) {
        await _database
            .into(_database.itemLifecycleEventPeriods)
            .insert(
              ItemLifecycleEventPeriodsCompanion.insert(
                eventId: eventId,
                period: period.name,
              ),
            );
      }

      final event = await findCreatedEvent(itemId);
      if (event == null) {
        throw StateError(
          'Created Item lifecycle event could not be read back.',
        );
      }
      return ItemCreationResult(itemId: itemId, createdEvent: event);
    });
  }

  @override
  Future<Set<ItemManagementPeriod>> listManagementPeriods(String itemId) async {
    final query = _database.select(_database.itemManagementPeriods)
      ..where((table) => table.itemId.equals(itemId));
    return Set.unmodifiable(
      (await query.get()).map(
        (row) => ItemManagementPeriod.values.byName(row.period),
      ),
    );
  }

  @override
  Future<ItemLifecycleEvent?> findCreatedEvent(String itemId) async {
    final eventQuery = _database.select(_database.itemLifecycleEvents)
      ..where(
        (table) =>
            table.itemId.equals(itemId) &
            table.eventType.equals(ItemLifecycleEventType.created.name),
      );
    final row = await eventQuery.getSingleOrNull();
    if (row == null) {
      return null;
    }
    final periodQuery = _database.select(_database.itemLifecycleEventPeriods)
      ..where((table) => table.eventId.equals(row.id));
    final periods = (await periodQuery.get())
        .map((period) => ItemManagementPeriod.values.byName(period.period))
        .toSet();
    return ItemLifecycleEvent(
      id: row.id,
      itemId: row.itemId,
      type: ItemLifecycleEventType.values.byName(row.eventType),
      itemNameSnapshot: row.itemNameSnapshot,
      categoryIdSnapshot: row.categoryIdSnapshot,
      categorySystemCodeSnapshot: row.categorySystemCodeSnapshot,
      categoryCustomNameSnapshot: row.categoryCustomNameSnapshot,
      categoryDisplayNameSnapshot: row.categoryDisplayNameSnapshot,
      occurredAt: row.occurredAt,
      createdAt: row.createdAt,
      managementPeriods: periods,
    );
  }
}

String? _textOrNull(String? value) {
  final normalized = value?.trim();
  return normalized == null || normalized.isEmpty ? null : normalized;
}
