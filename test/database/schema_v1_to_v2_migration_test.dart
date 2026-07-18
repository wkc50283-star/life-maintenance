import 'dart:io';

import 'package:drift/drift.dart' hide isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/work_case_enums.dart';

void main() {
  test('migrates every schema v1 case and update field safely', () async {
    final fixture = await _createSchemaV1Fixture();
    addTearDown(fixture.dispose);
    final executor = NativeDatabase(fixture.file);
    final database = AppDatabase(executor);
    addTearDown(database.close);

    final cases = await database.select(database.workCases).get();
    final updates = await database.select(database.workCaseUpdates).get();
    final items = await database.select(database.items).get();
    final categories = await database.select(database.itemCategories).get();

    expect(database.schemaVersion, 2);
    expect(cases, hasLength(2));
    expect(updates, hasLength(2));
    expect(items, hasLength(2));
    expect(categories, hasLength(1));

    final firstCase = cases.singleWhere((row) => row.id == 'case-1');
    expect(firstCase.schemaVersion, 1);
    expect(firstCase.itemId, 'item-1');
    expect(firstCase.sourceType, WorkCaseSourceType.maintenanceTask);
    expect(firstCase.sourceId, 'task-1');
    expect(firstCase.caseType, WorkCaseType.repair);
    expect(firstCase.title, '冷氣維修');
    expect(firstCase.description, '運轉時出現異音');
    expect(firstCase.occurredAt, _at(0, 0));
    expect(firstCase.startedAt, _at(1, 40));
    expect(firstCase.status, WorkCaseStatus.waiting);
    expect(firstCase.createdAt, _at(3, 20));
    expect(firstCase.updatedAt, _at(5, 0));
    expect(firstCase.closedAt, isNull);
    expect(firstCase.canceledAt, isNull);
    expect(firstCase.closeResult, isNull);
    expect(firstCase.cancellationReason, isNull);

    final canceledCase = cases.singleWhere((row) => row.id == 'case-2');
    expect(canceledCase.schemaVersion, 1);
    expect(canceledCase.itemId, 'item-2');
    expect(canceledCase.sourceType, WorkCaseSourceType.manual);
    expect(canceledCase.sourceId, isNull);
    expect(canceledCase.caseType, WorkCaseType.construction);
    expect(canceledCase.title, '浴室修繕');
    expect(canceledCase.description, '原訂修補牆面');
    expect(canceledCase.occurredAt, _at(6, 40));
    expect(canceledCase.startedAt, _at(8, 20));
    expect(canceledCase.status, WorkCaseStatus.canceled);
    expect(canceledCase.createdAt, _at(10, 0));
    expect(canceledCase.updatedAt, _at(11, 40));
    expect(canceledCase.closedAt, _at(13, 20));
    expect(canceledCase.canceledAt, _at(13, 20));
    expect(canceledCase.closeResult, '不再施工');
    expect(canceledCase.cancellationReason, '房東改由其他廠商處理');

    final firstUpdate = updates.singleWhere((row) => row.id == 'update-1');
    expect(firstUpdate.schemaVersion, 1);
    expect(firstUpdate.workCaseId, 'case-1');
    expect(firstUpdate.occurredAt, _at(15, 0));
    expect(firstUpdate.description, '完成初步檢查');
    expect(firstUpdate.contactOrVendor, '安心冷氣行');
    expect(firstUpdate.result, '等待零件');
    expect(firstUpdate.cost, 500);
    expect(firstUpdate.partsOrItems, ['軸承']);
    expect(firstUpdate.photoIdentifiers, ['photo-1']);
    expect(firstUpdate.waitingReason, '零件調貨');
    expect(firstUpdate.note, '先停止使用');
    expect(firstUpdate.nextAction, '到貨後更換');
    expect(firstUpdate.createdAt, _at(16, 40));

    final secondUpdate = updates.singleWhere((row) => row.id == 'update-2');
    expect(secondUpdate.schemaVersion, 1);
    expect(secondUpdate.workCaseId, 'case-2');
    expect(secondUpdate.occurredAt, _at(18, 20));
    expect(secondUpdate.description, '通知取消施工');
    expect(secondUpdate.contactOrVendor, isNull);
    expect(secondUpdate.result, '已取消');
    expect(secondUpdate.cost, isNull);
    expect(secondUpdate.partsOrItems, isEmpty);
    expect(secondUpdate.photoIdentifiers, isEmpty);
    expect(secondUpdate.waitingReason, isNull);
    expect(secondUpdate.note, isNull);
    expect(secondUpdate.nextAction, isNull);
    expect(secondUpdate.createdAt, _at(20, 0));

    expect(items.map((row) => row.id), containsAll(['item-1', 'item-2']));
    expect(items.every((row) => row.note!.contains('schema v1')), isTrue);
    expect(categories.single.systemCode, 'legacyImported');

    final legacyTables = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name LIKE 'legacy_%'
    ''').get();
    expect(legacyTables, isEmpty);

    final indexes = await database.customSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'index' AND name IN (
        'work_cases_item_status_idx',
        'work_cases_source_idx',
        'work_cases_updated_at_idx',
        'work_case_updates_case_occurred_idx'
      )
    ''').get();
    expect(indexes, hasLength(4));

    final violations = await database
        .customSelect('PRAGMA foreign_key_check')
        .get();
    expect(violations, isEmpty);
    final foreignKeys =
        await database.customSelect('PRAGMA foreign_keys').get();
    expect(foreignKeys.single.read<int>('foreign_keys'), 1);
  });

  test(
    'rolls back the whole migration when legacy data violates v2 rules',
    () async {
      final fixture = await _createSchemaV1Fixture(includeInvalidCase: true);
      addTearDown(fixture.dispose);
      final database = AppDatabase(NativeDatabase(fixture.file));

      await expectLater(
        database.customSelect('SELECT 1').get(),
        throwsA(isA<Exception>()),
      );
      await database.close();

      final inspection = NativeDatabase(fixture.file);
      await inspection.ensureOpen(const _FixtureDatabaseUser(1));
      addTearDown(inspection.close);

      final version = await inspection.runSelect(
        'PRAGMA user_version',
        const [],
      );
      expect(version.single['user_version'], 1);

      final tableRows = await inspection.runSelect('''
      SELECT name FROM sqlite_master
      WHERE type = 'table' AND name IN (
        'work_cases', 'work_case_updates', 'items', 'item_categories',
        'legacy_work_cases_v1', 'legacy_work_case_updates_v1'
      ) ORDER BY name
    ''', const []);
      expect(tableRows.map((row) => row['name']), [
        'work_case_updates',
        'work_cases',
      ]);

      final oldCases = await inspection.runSelect(
        'SELECT id, source_id FROM work_cases ORDER BY id',
        const [],
      );
      expect(oldCases, hasLength(3));
      expect(oldCases.last['id'], 'invalid-case');
      expect(oldCases.last['source_id'], 'illegal-source');

      final oldUpdates = await inspection.runSelect(
        'SELECT id, work_case_id FROM work_case_updates ORDER BY id',
        const [],
      );
      expect(oldUpdates, hasLength(2));
      expect(oldUpdates.first['id'], 'update-1');
      expect(oldUpdates.last['id'], 'update-2');
    },
  );

  test('blocks unsupported schema versions', () async {
    final fixture = await _createEmptyFixture(3);
    addTearDown(fixture.dispose);
    final database = AppDatabase(NativeDatabase(fixture.file));

    await expectLater(
      database.customSelect('SELECT 1').get(),
      throwsA(
        isA<UnsupportedError>().having(
          (error) => error.message,
          'message',
          contains('schema 3 to 2'),
        ),
      ),
    );
    await database.close();
  });
}

DateTime _at(int minute, int second) =>
    DateTime.utc(2026, 7, 18, 0, minute, second);

Future<_DatabaseFixture> _createSchemaV1Fixture({
  bool includeInvalidCase = false,
}) async {
  final fixture = await _createEmptyFixture(1);
  final executor = NativeDatabase(fixture.file);
  await executor.ensureOpen(const _FixtureDatabaseUser(1));

  await executor.runCustom('''
    CREATE TABLE work_cases (
      schema_version INTEGER NOT NULL DEFAULT 1,
      id TEXT NOT NULL PRIMARY KEY,
      item_id TEXT NOT NULL,
      source_type TEXT NOT NULL,
      source_id TEXT NULL,
      case_type TEXT NOT NULL,
      title TEXT NOT NULL,
      description TEXT NULL,
      occurred_at TEXT NULL,
      started_at TEXT NULL,
      status TEXT NOT NULL,
      created_at TEXT NOT NULL,
      updated_at TEXT NOT NULL,
      closed_at TEXT NULL,
      close_result TEXT NULL,
      cancellation_reason TEXT NULL
    )
  ''');
  await executor.runCustom('''
    CREATE TABLE work_case_updates (
      schema_version INTEGER NOT NULL DEFAULT 1,
      id TEXT NOT NULL PRIMARY KEY,
      work_case_id TEXT NOT NULL REFERENCES work_cases(id)
        ON UPDATE CASCADE ON DELETE RESTRICT,
      occurred_at TEXT NOT NULL,
      description TEXT NOT NULL,
      contact_or_vendor TEXT NULL,
      result TEXT NULL,
      cost INTEGER NULL,
      parts_or_items TEXT NOT NULL DEFAULT '[]',
      photo_identifiers TEXT NOT NULL DEFAULT '[]',
      waiting_reason TEXT NULL,
      note TEXT NULL,
      next_action TEXT NULL,
      created_at TEXT NOT NULL
    )
  ''');
  await executor.runCustom(
    'CREATE INDEX work_cases_item_status_idx '
    'ON work_cases (item_id, status)',
  );
  await executor.runCustom(
    'CREATE INDEX work_cases_source_idx '
    'ON work_cases (source_type, source_id)',
  );
  await executor.runCustom(
    'CREATE INDEX work_cases_updated_at_idx ON work_cases (updated_at)',
  );
  await executor.runCustom(
    'CREATE INDEX work_case_updates_case_occurred_idx '
    'ON work_case_updates (work_case_id, occurred_at)',
  );

  await executor.runCustom('''
    INSERT INTO work_cases (
      id, item_id, source_type, source_id, case_type, title, description,
      occurred_at, started_at, status, created_at, updated_at
    ) VALUES (
      'case-1', 'item-1', 'maintenanceTask', 'task-1', 'repair',
      '冷氣維修', '運轉時出現異音',
      '2026-07-18T00:00:00.000000Z', '2026-07-18T00:01:40.000000Z',
      'waiting', '2026-07-18T00:03:20.000000Z',
      '2026-07-18T00:05:00.000000Z'
    )
  ''');
  await executor.runCustom('''
    INSERT INTO work_cases (
      id, item_id, source_type, source_id, case_type, title, description,
      occurred_at, started_at, status, created_at, updated_at, closed_at,
      close_result, cancellation_reason
    ) VALUES (
      'case-2', 'item-2', 'manual', NULL, 'construction',
      '浴室修繕', '原訂修補牆面',
      '2026-07-18T00:06:40.000000Z', '2026-07-18T00:08:20.000000Z',
      'canceled', '2026-07-18T00:10:00.000000Z',
      '2026-07-18T00:11:40.000000Z', '2026-07-18T00:13:20.000000Z',
      '不再施工', '房東改由其他廠商處理'
    )
  ''');
  await executor.runCustom('''
    INSERT INTO work_case_updates (
      id, work_case_id, occurred_at, description, contact_or_vendor, result,
      cost, parts_or_items, photo_identifiers, waiting_reason, note,
      next_action, created_at
    ) VALUES (
      'update-1', 'case-1', '2026-07-18T00:15:00.000000Z', '完成初步檢查',
      '安心冷氣行', '等待零件', 500, '["軸承"]', '["photo-1"]',
      '零件調貨', '先停止使用', '到貨後更換',
      '2026-07-18T00:16:40.000000Z'
    )
  ''');
  await executor.runCustom('''
    INSERT INTO work_case_updates (
      id, work_case_id, occurred_at, description, result,
      parts_or_items, photo_identifiers, created_at
    ) VALUES (
      'update-2', 'case-2', '2026-07-18T00:18:20.000000Z',
      '通知取消施工', '已取消', '[]', '[]',
      '2026-07-18T00:20:00.000000Z'
    )
  ''');

  if (includeInvalidCase) {
    await executor.runCustom('''
      INSERT INTO work_cases (
        id, item_id, source_type, source_id, case_type, title, status,
        created_at, updated_at
      ) VALUES (
        'invalid-case', 'item-3', 'manual', 'illegal-source', 'repair',
        '無效舊案件', 'inProgress',
        '2026-07-18T00:00:00.000000Z', '2026-07-18T00:00:00.000000Z'
      )
    ''');
  }

  await executor.close();
  return fixture;
}

Future<_DatabaseFixture> _createEmptyFixture(int schemaVersion) async {
  final directory = await Directory.systemTemp.createTemp(
    'life-maintenance-migration-',
  );
  final file = File('${directory.path}/fixture.sqlite');
  final executor = NativeDatabase(file);
  await executor.ensureOpen(_FixtureDatabaseUser(schemaVersion));
  await executor.close();
  return _DatabaseFixture(directory, file);
}

class _FixtureDatabaseUser implements QueryExecutorUser {
  const _FixtureDatabaseUser(this.schemaVersion);

  @override
  final int schemaVersion;

  @override
  Future<void> beforeOpen(
    QueryExecutor executor,
    OpeningDetails details,
  ) async {}
}

class _DatabaseFixture {
  const _DatabaseFixture(this.directory, this.file);

  final Directory directory;
  final File file;

  Future<void> dispose() => directory.delete(recursive: true);
}
