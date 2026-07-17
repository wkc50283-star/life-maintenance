import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/work_case.dart';
import '../../models/work_case_update.dart';
import '../work_case_repository.dart';
import 'work_case_drift_mappers.dart';

class DriftWorkCaseRepository implements WorkCaseRepository {
  DriftWorkCaseRepository(this._database);

  final AppDatabase _database;

  @override
  Future<WorkCase?> findCaseById(String id) async {
    final query = _database.select(_database.workCases)
      ..where((table) => table.id.equals(id));
    return (await query.getSingleOrNull())?.toModel();
  }

  @override
  Future<List<WorkCase>> listCasesForItem(String itemId) async {
    final query = _database.select(_database.workCases)
      ..where((table) => table.itemId.equals(itemId))
      ..orderBy([
        (table) => OrderingTerm.desc(table.updatedAt),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  @override
  Future<List<WorkCaseUpdate>> listUpdatesForCase(String workCaseId) async {
    final query = _database.select(_database.workCaseUpdates)
      ..where((table) => table.workCaseId.equals(workCaseId))
      ..orderBy([
        (table) => OrderingTerm.asc(table.occurredAt),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    return (await query.get()).map((row) => row.toModel()).toList();
  }

  @override
  Future<void> saveCase(WorkCase workCase) async {
    await _database.into(_database.workCases).insertOnConflictUpdate(
          workCase.toCompanion(),
        );
  }

  @override
  Future<void> appendUpdate(WorkCaseUpdate update) async {
    await _database.into(_database.workCaseUpdates).insert(
          update.toCompanion(),
          mode: InsertMode.insert,
        );
  }

  @override
  Future<void> createCaseWithInitialUpdate(
    WorkCase workCase,
    WorkCaseUpdate initialUpdate,
  ) async {
    if (initialUpdate.workCaseId != workCase.id) {
      throw ArgumentError.value(
        initialUpdate.workCaseId,
        'initialUpdate.workCaseId',
        'Must match workCase.id',
      );
    }

    await _database.transaction(() async {
      await _database.into(_database.workCases).insert(
            workCase.toCompanion(),
            mode: InsertMode.insert,
          );
      await _database.into(_database.workCaseUpdates).insert(
            initialUpdate.toCompanion(),
            mode: InsertMode.insert,
          );
    });
  }
}
