import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/item_custom_management_period.dart';
import '../../models/item_management_period.dart';
import '../../models/item_management_period_change_event.dart';
import '../item_management_period_runtime.dart';
import '../repository_constraint_exception.dart';
import 'drift_item_management_period_normalizer.dart';

class DriftItemManagementPeriodRuntime implements ItemManagementPeriodRuntime {
  DriftItemManagementPeriodRuntime(this._database);

  final AppDatabase _database;

  @override
  Future<ItemManagementPeriodSnapshot> readCurrent(String itemId) async {
    final fixedQuery = _database.select(_database.itemManagementPeriods)
      ..where((table) => table.itemId.equals(itemId));
    final customQuery = _database.select(_database.itemCustomManagementPeriods)
      ..where((table) => table.itemId.equals(itemId));
    return ItemManagementPeriodSnapshot(
      fixed: (await fixedQuery.get()).map(
        (row) => ItemManagementPeriod.values.byName(row.period),
      ),
      custom: (await customQuery.get()).map(_customPeriodFromCurrentRow),
    );
  }

  @override
  Future<ItemManagementPeriodChangeEvent?> replace(
    ItemManagementPeriodChangeRequest request,
  ) {
    return _database.transaction(() async {
      final itemId = request.itemId.trim();
      final eventId = request.eventId.trim();
      if (itemId.isEmpty || eventId.isEmpty) {
        throw const RepositoryConstraintException(
          'Item ID and event ID must not be empty.',
        );
      }
      final itemQuery = _database.select(_database.items)
        ..where((table) => table.id.equals(itemId));
      final item = await itemQuery.getSingleOrNull();
      if (item == null) {
        throw RepositoryConstraintException('Item $itemId does not exist.');
      }
      if (item.status != 'active') {
        throw RepositoryConstraintException(
          'Item $itemId is not available for management-period changes.',
        );
      }
      final normalized = normalizeItemManagementPeriods(
        fixed: request.fixed,
        custom: request.custom,
      );
      final before = await readCurrent(itemId);
      final after = ItemManagementPeriodSnapshot(
        fixed: normalized.fixed,
        custom: normalized.custom,
      );
      if (_snapshotsEqual(before, after)) return null;

      await (_database.delete(
        _database.itemManagementPeriods,
      )..where((table) => table.itemId.equals(itemId))).go();
      await (_database.delete(
        _database.itemCustomManagementPeriods,
      )..where((table) => table.itemId.equals(itemId))).go();
      await _writeCurrent(itemId, request.occurredAt, after);

      await _database
          .into(_database.itemManagementPeriodChangeEvents)
          .insert(
            ItemManagementPeriodChangeEventsCompanion.insert(
              id: eventId,
              itemId: itemId,
              occurredAt: request.occurredAt,
              createdAt: request.occurredAt,
            ),
          );
      await _writeSnapshot(eventId, 'before', before);
      await _writeSnapshot(eventId, 'after', after);
      return ItemManagementPeriodChangeEvent(
        id: eventId,
        itemId: itemId,
        occurredAt: request.occurredAt,
        createdAt: request.occurredAt,
        before: before,
        after: after,
      );
    });
  }

  @override
  Future<List<ItemManagementPeriodChangeEvent>> listChanges(
    String itemId,
  ) async {
    final query = _database.select(_database.itemManagementPeriodChangeEvents)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.id),
      ]);
    final events = <ItemManagementPeriodChangeEvent>[];
    for (final row in await query.get()) {
      events.add(
        ItemManagementPeriodChangeEvent(
          id: row.id,
          itemId: row.itemId,
          occurredAt: row.occurredAt,
          createdAt: row.createdAt,
          before: await _readSnapshot(row.id, 'before'),
          after: await _readSnapshot(row.id, 'after'),
        ),
      );
    }
    return List.unmodifiable(events);
  }

  Future<void> _writeCurrent(
    String itemId,
    DateTime createdAt,
    ItemManagementPeriodSnapshot snapshot,
  ) async {
    for (final period in snapshot.fixed) {
      await _database
          .into(_database.itemManagementPeriods)
          .insert(
            ItemManagementPeriodsCompanion.insert(
              itemId: itemId,
              period: period.name,
              createdAt: createdAt,
            ),
          );
    }
    for (final period in snapshot.custom) {
      await _database
          .into(_database.itemCustomManagementPeriods)
          .insert(
            ItemCustomManagementPeriodsCompanion.insert(
              itemId: itemId,
              intervalValue: period.intervalValue,
              intervalUnit: period.intervalUnit.name,
              canonicalFamily: period.canonicalFamily.name,
              canonicalValue: period.canonicalValue,
              createdAt: createdAt,
            ),
          );
    }
  }

  Future<void> _writeSnapshot(
    String eventId,
    String side,
    ItemManagementPeriodSnapshot snapshot,
  ) async {
    for (final period in snapshot.fixed) {
      await _database
          .into(_database.itemManagementPeriodChangeEventPeriods)
          .insert(
            ItemManagementPeriodChangeEventPeriodsCompanion.insert(
              eventId: eventId,
              snapshotSide: side,
              period: period.name,
            ),
          );
    }
    for (final period in snapshot.custom) {
      await _database
          .into(_database.itemManagementPeriodChangeEventCustomPeriods)
          .insert(
            ItemManagementPeriodChangeEventCustomPeriodsCompanion.insert(
              eventId: eventId,
              snapshotSide: side,
              intervalValue: period.intervalValue,
              intervalUnit: period.intervalUnit.name,
              canonicalFamily: period.canonicalFamily.name,
              canonicalValue: period.canonicalValue,
            ),
          );
    }
  }

  Future<ItemManagementPeriodSnapshot> _readSnapshot(
    String eventId,
    String side,
  ) async {
    final fixedQuery =
        _database.select(_database.itemManagementPeriodChangeEventPeriods)
          ..where(
            (table) =>
                table.eventId.equals(eventId) & table.snapshotSide.equals(side),
          );
    final customQuery =
        _database.select(_database.itemManagementPeriodChangeEventCustomPeriods)
          ..where(
            (table) =>
                table.eventId.equals(eventId) & table.snapshotSide.equals(side),
          );
    return ItemManagementPeriodSnapshot(
      fixed: (await fixedQuery.get()).map(
        (row) => ItemManagementPeriod.values.byName(row.period),
      ),
      custom: (await customQuery.get()).map(
        (row) => ItemCustomManagementPeriod(
          intervalValue: row.intervalValue,
          intervalUnit: ItemManagementIntervalUnit.values.byName(
            row.intervalUnit,
          ),
        ),
      ),
    );
  }
}

ItemCustomManagementPeriod _customPeriodFromCurrentRow(
  ItemCustomManagementPeriodRow row,
) => ItemCustomManagementPeriod(
  intervalValue: row.intervalValue,
  intervalUnit: ItemManagementIntervalUnit.values.byName(row.intervalUnit),
);

bool _snapshotsEqual(
  ItemManagementPeriodSnapshot left,
  ItemManagementPeriodSnapshot right,
) =>
    left.fixed.length == right.fixed.length &&
    left.fixed.containsAll(right.fixed) &&
    left.custom.length == right.custom.length &&
    left.custom.containsAll(right.custom);
