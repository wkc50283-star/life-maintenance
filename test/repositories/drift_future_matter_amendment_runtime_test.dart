import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/future_matter.dart';
import 'package:life_maintenance/models/item_system_category.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_amendment_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_completion_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/future_matter_amendment_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_change_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_completion_runtime.dart';
import 'package:life_maintenance/repositories/future_matter_creation_runtime.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftFutureMatterCreationRuntime creation;
  late DriftFutureMatterCompletionRuntime completion;
  late DriftFutureMatterChangeRuntime changes;
  late DriftFutureMatterAmendmentRuntime amendments;
  late DriftHistoryProjectionRepository history;
  final createdAt = DateTime.utc(2026, 8, 8, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    await database.customSelect('SELECT 1').get();
    creation = DriftFutureMatterCreationRuntime(database);
    completion = DriftFutureMatterCompletionRuntime(database);
    changes = DriftFutureMatterChangeRuntime(database);
    amendments = DriftFutureMatterAmendmentRuntime(database);
    history = DriftHistoryProjectionRepository(
      database: database,
      attachments: DriftSchemaV2Repositories(database).attachments,
    );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-a',
            name: '冷氣',
            categoryId: ItemSystemCategory.unclassifiedId,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: 'active',
          ),
        );
    await database
        .into(database.items)
        .insert(
          ItemsCompanion.insert(
            id: 'item-b',
            name: '冰箱',
            categoryId: ItemSystemCategory.unclassifiedId,
            createdAt: createdAt,
            updatedAt: createdAt,
            status: 'active',
          ),
        );
    await database
        .into(database.maintenanceRecords)
        .insert(
          MaintenanceRecordsCompanion.insert(
            id: 'record-1',
            itemId: 'item-a',
            recordType: 'other',
            date: createdAt,
            title: '正式完成',
            createdAt: createdAt,
          ),
        );
    await database
        .into(database.attachments)
        .insert(
          AttachmentsCompanion.insert(
            id: 'attachment-1',
            ownerType: 'item',
            ownerId: 'item-a',
            kind: 'photo',
            storageIdentifier: 'photo-1',
            createdAt: createdAt,
          ),
        );
  });

  tearDown(() => database.close());

  Future<void> createMatter({
    String id = 'matter-1',
    String? itemId = 'item-a',
    FutureMatterSource? source = FutureMatterSource.manual,
    FutureMatterSourceReferenceKind? referenceKind,
    String? referenceId,
  }) async {
    await creation.create(
      FutureMatterCreationRequest(
        id: id,
        eventId: 'created-$id',
        title: '未來事項',
        itemId: itemId,
        timingMode: FutureMatterTimingMode.later,
        createdAt: createdAt,
        createdSource: source,
        createdSourceReferenceKind: referenceKind,
        createdSourceReferenceId: referenceId,
      ),
    );
  }

  FutureMatterAmendmentRequest request({
    required String id,
    required FutureMatterTargetEventKind targetKind,
    required String targetId,
    required List<FutureMatterFieldChange> changes,
    DateTime? occurredAt,
    DateTime? recordedAt,
    FutureMatterSourceReferenceKind? sourceKind,
    String? sourceId,
  }) => FutureMatterAmendmentRequest(
    id: id,
    futureMatterId: 'matter-1',
    target: FutureMatterEventReference(kind: targetKind, id: targetId),
    occurredAt: occurredAt,
    recordedAt: recordedAt ?? DateTime.utc(2026, 8, 9),
    eventSource: FutureMatterSource.manual,
    sourceReferenceKind: sourceKind,
    sourceReferenceId: sourceId,
    changes: changes,
  );

  test('created provenance supports four sources and legacy null', () async {
    for (final source in FutureMatterSource.values) {
      await createMatter(id: source.name, source: source);
      final row = await (database.select(
        database.futureMatters,
      )..where((table) => table.id.equals(source.name))).getSingle();
      expect(row.createdSource, source.name);
    }
    await createMatter(id: 'legacy', source: null);
    expect(
      (await (database.select(
            database.futureMatters,
          )..where((table) => table.id.equals('legacy'))).getSingle())
          .createdSource,
      isNull,
    );
  });

  test('provenance reference pair and five kinds are validated', () async {
    await createMatter(id: 'source-matter');
    await completion.complete(
      FutureMatterCompletionRequest(
        futureMatterId: 'source-matter',
        eventId: 'completed-source',
        completedDate: const FutureMatterDate(2026, 8, 8),
        confirmedAt: createdAt,
      ),
    );
    await createMatter(
      id: 'with-created-source',
      referenceKind: FutureMatterSourceReferenceKind.futureMatterCreatedEvent,
      referenceId: 'created-source-matter',
    );
    await expectLater(
      createMatter(
        id: 'broken-pair',
        referenceKind: FutureMatterSourceReferenceKind.maintenanceRecord,
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await createMatter(id: 'matter-1');
    await changes.replace(
      FutureMatterChangeRequest(
        eventId: 'change-source',
        futureMatterId: 'matter-1',
        itemId: 'item-b',
        timingMode: FutureMatterTimingMode.later,
        occurredAt: DateTime.utc(2026, 8, 9),
      ),
    );
    await amendments.createSupplement(
      request(
        id: 'amendment-source',
        targetKind: FutureMatterTargetEventKind.created,
        targetId: 'created-matter-1',
        changes: [
          const FutureMatterFieldChange(
            field: FutureMatterAmendmentField.note,
            oldValue: FutureMatterFieldValue.absent(),
            newValue: FutureMatterFieldValue.value('補充'),
          ),
        ],
      ),
    );
    final kinds = <FutureMatterSourceReferenceKind, String>{
      FutureMatterSourceReferenceKind.futureMatterCreatedEvent:
          'created-matter-1',
      FutureMatterSourceReferenceKind.futureMatterChangeEvent: 'change-source',
      FutureMatterSourceReferenceKind.futureMatterCompletedEvent:
          'completed-source',
      FutureMatterSourceReferenceKind.futureMatterAmendmentEvent:
          'amendment-source',
      FutureMatterSourceReferenceKind.maintenanceRecord: 'record-1',
    };
    var index = 0;
    for (final entry in kinds.entries) {
      await createMatter(
        id: 'reference-${index++}',
        referenceKind: entry.key,
        referenceId: entry.value,
      );
    }
    await expectLater(
      createMatter(
        id: 'missing-reference',
        referenceKind: FutureMatterSourceReferenceKind.maintenanceRecord,
        referenceId: 'missing-record',
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      database.customStatement(
        "UPDATE future_matters SET created_source = 'system' WHERE id = 'with-created-source'",
      ),
      throwsA(anything),
    );
  });

  test('created change completed and amendment targets are accepted', () async {
    await createMatter(id: 'matter-1');
    await changes.replace(
      FutureMatterChangeRequest(
        eventId: 'change-1',
        futureMatterId: 'matter-1',
        itemId: 'item-b',
        timingMode: FutureMatterTimingMode.later,
        occurredAt: DateTime.utc(2026, 8, 9),
      ),
    );
    await completion.complete(
      FutureMatterCompletionRequest(
        futureMatterId: 'matter-1',
        eventId: 'completed-1',
        completedDate: const FutureMatterDate(2026, 8, 10),
        confirmedAt: DateTime.utc(2026, 8, 10),
      ),
    );
    final targets = [
      const FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.created,
        id: 'created-matter-1',
      ),
      const FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.change,
        id: 'change-1',
      ),
      const FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.completed,
        id: 'completed-1',
      ),
    ];
    var index = 0;
    for (final target in targets) {
      await amendments.createSupplement(
        request(
          id: 'target-${index++}',
          targetKind: target.kind,
          targetId: target.id,
          changes: [
            FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: const FutureMatterFieldValue.absent(),
              newValue: FutureMatterFieldValue.value('目標 ${target.kind.name}'),
            ),
          ],
        ),
      );
    }
    await amendments.createCorrection(
      request(
        id: 'target-correction',
        targetKind: FutureMatterTargetEventKind.supplement,
        targetId: 'target-0',
        recordedAt: DateTime.utc(2026, 8, 11),
        changes: [
          const FutureMatterFieldChange(
            field: FutureMatterAmendmentField.note,
            oldValue: FutureMatterFieldValue.value('目標 created'),
            newValue: FutureMatterFieldValue.value('已更正'),
          ),
        ],
      ),
    );
    expect(await amendments.listAmendments('matter-1'), hasLength(4));
    for (final itemId in ['item-a', 'item-b']) {
      final projected = await history.projectForItem(itemId);
      expect(
        projected.futureMatterAmendmentEntries.where(
          (entry) => entry.event.id == 'target-1',
        ),
        hasLength(1),
      );
    }
  });

  test(
    'supplement stores every structured value and folds by recorded order',
    () async {
      await createMatter();
      final changes = <FutureMatterFieldChange>[
        FutureMatterFieldChange(
          field: FutureMatterAmendmentField.completedDate,
          oldValue: const FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value(
            const FutureMatterDate(2026, 8, 1),
          ),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.completedMinuteOfDay,
          oldValue: FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value(0),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.note,
          oldValue: FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value('使用者補充'),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.attachments,
          oldValue: FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value(<String>['attachment-1']),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.cost,
          oldValue: FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value(
            FutureMatterMoney(amountMinor: 0, currency: 'TWD'),
          ),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.relatedPeople,
          oldValue: FutureMatterFieldValue.absent(),
          newValue: FutureMatterFieldValue.value(<FutureMatterRelatedPerson>[
            FutureMatterRelatedPerson(
              displayName: '王先生',
              relationNote: '維修聯絡人',
            ),
          ]),
        ),
      ];
      final event = await amendments.createSupplement(
        request(
          id: 'supp-1',
          targetKind: FutureMatterTargetEventKind.created,
          targetId: 'created-matter-1',
          occurredAt: DateTime.utc(2020),
          changes: changes,
        ),
      );
      expect(event.changes, hasLength(6));
      final folded = await amendments.foldEffectiveResult(
        const FutureMatterEventReference(
          kind: FutureMatterTargetEventKind.created,
          id: 'created-matter-1',
        ),
      );
      expect(
        folded.values[FutureMatterAmendmentField.completedMinuteOfDay],
        const FutureMatterFieldValue.value(0),
      );
      expect(
        folded.values[FutureMatterAmendmentField.attachments],
        const FutureMatterFieldValue.value(<String>['attachment-1']),
      );
    },
  );

  test(
    'correction supports value to value/null and rejects stale or same',
    () async {
      await createMatter();
      await amendments.createSupplement(
        request(
          id: 'supp-note',
          targetKind: FutureMatterTargetEventKind.created,
          targetId: 'created-matter-1',
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.absent(),
              newValue: FutureMatterFieldValue.value('舊值'),
            ),
          ],
        ),
      );
      await amendments.createCorrection(
        request(
          id: 'correction-1',
          targetKind: FutureMatterTargetEventKind.supplement,
          targetId: 'supp-note',
          recordedAt: DateTime.utc(2026, 8, 10),
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.value('舊值'),
              newValue: FutureMatterFieldValue.value('新值'),
            ),
          ],
        ),
      );
      await amendments.createCorrection(
        request(
          id: 'correction-2',
          targetKind: FutureMatterTargetEventKind.correction,
          targetId: 'correction-1',
          recordedAt: DateTime.utc(2026, 8, 11),
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.value('新值'),
              newValue: FutureMatterFieldValue.nullValue(),
            ),
          ],
        ),
      );
      final beforeCount =
          (await database.select(database.futureMatterAmendmentEvents).get())
              .length;
      for (final invalid in [
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.note,
          oldValue: FutureMatterFieldValue.value('舊值'),
          newValue: FutureMatterFieldValue.value('其他'),
        ),
        const FutureMatterFieldChange(
          field: FutureMatterAmendmentField.note,
          oldValue: FutureMatterFieldValue.value('新值'),
          newValue: FutureMatterFieldValue.value('新值'),
        ),
      ]) {
        await expectLater(
          amendments.createCorrection(
            request(
              id: 'bad-${invalid.hashCode}',
              targetKind: FutureMatterTargetEventKind.correction,
              targetId: 'correction-2',
              changes: [invalid],
            ),
          ),
          throwsA(isA<RepositoryConstraintException>()),
        );
      }
      expect(
        (await database.select(database.futureMatterAmendmentEvents).get())
            .length,
        beforeCount,
      );
    },
  );

  test('fold uses recordedAt then eventId and ignores occurredAt', () async {
    await createMatter();
    final recordedAt = DateTime.utc(2026, 8, 10);
    await amendments.createSupplement(
      request(
        id: 'a-supplement',
        targetKind: FutureMatterTargetEventKind.created,
        targetId: 'created-matter-1',
        recordedAt: recordedAt,
        occurredAt: DateTime.utc(2030),
        changes: [
          const FutureMatterFieldChange(
            field: FutureMatterAmendmentField.note,
            oldValue: FutureMatterFieldValue.absent(),
            newValue: FutureMatterFieldValue.value('第一值'),
          ),
        ],
      ),
    );
    await amendments.createCorrection(
      request(
        id: 'b-correction',
        targetKind: FutureMatterTargetEventKind.supplement,
        targetId: 'a-supplement',
        recordedAt: recordedAt,
        occurredAt: DateTime.utc(2020),
        changes: [
          const FutureMatterFieldChange(
            field: FutureMatterAmendmentField.note,
            oldValue: FutureMatterFieldValue.value('第一值'),
            newValue: FutureMatterFieldValue.value('第二值'),
          ),
        ],
      ),
    );
    final folded = await amendments.foldEffectiveResult(
      const FutureMatterEventReference(
        kind: FutureMatterTargetEventKind.created,
        id: 'created-matter-1',
      ),
    );
    expect(
      folded.values[FutureMatterAmendmentField.note],
      const FutureMatterFieldValue.value('第二值'),
    );
  });

  test('invalid target, attachment, minute, and currency roll back', () async {
    await createMatter();
    final invalidValues = <FutureMatterFieldChange>[
      const FutureMatterFieldChange(
        field: FutureMatterAmendmentField.completedMinuteOfDay,
        oldValue: FutureMatterFieldValue.absent(),
        newValue: FutureMatterFieldValue.value(1440),
      ),
      const FutureMatterFieldChange(
        field: FutureMatterAmendmentField.attachments,
        oldValue: FutureMatterFieldValue.absent(),
        newValue: FutureMatterFieldValue.value(<String>['missing']),
      ),
      const FutureMatterFieldChange(
        field: FutureMatterAmendmentField.cost,
        oldValue: FutureMatterFieldValue.absent(),
        newValue: FutureMatterFieldValue.value(
          FutureMatterMoney(amountMinor: -1, currency: 'twd'),
        ),
      ),
    ];
    for (var index = 0; index < invalidValues.length; index++) {
      await expectLater(
        amendments.createSupplement(
          request(
            id: 'invalid-$index',
            targetKind: FutureMatterTargetEventKind.created,
            targetId: 'created-matter-1',
            changes: [invalidValues[index]],
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
    }
    await expectLater(
      amendments.createSupplement(
        request(
          id: 'broken-target',
          targetKind: FutureMatterTargetEventKind.completed,
          targetId: 'created-matter-1',
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.absent(),
              newValue: FutureMatterFieldValue.value('內容'),
            ),
          ],
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(
      await database.select(database.futureMatterAmendmentEvents).get(),
      isEmpty,
    );
    expect(await database.select(database.tasks).get(), isEmpty);
    expect(await database.select(database.schedules).get(), isEmpty);
  });

  test('self, cycle, and broken amendment chains are rejected', () async {
    await createMatter();
    await expectLater(
      amendments.createSupplement(
        request(
          id: 'self',
          targetKind: FutureMatterTargetEventKind.supplement,
          targetId: 'self',
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.absent(),
              newValue: FutureMatterFieldValue.value('內容'),
            ),
          ],
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await database.customStatement('''
      INSERT INTO future_matter_amendment_events
        (id, future_matter_id, event_type, target_event_kind, target_event_id,
         occurred_at, recorded_at, event_source,
         source_reference_kind, source_reference_id)
      VALUES
        ('cycle-a', 'matter-1', 'supplement', 'supplement', 'cycle-b',
         NULL, '2026-08-10T00:00:00.000Z', 'system', NULL, NULL),
        ('cycle-b', 'matter-1', 'supplement', 'supplement', 'cycle-a',
         NULL, '2026-08-11T00:00:00.000Z', 'system', NULL, NULL)
    ''');
    await expectLater(
      amendments.foldEffectiveResult(
        const FutureMatterEventReference(
          kind: FutureMatterTargetEventKind.supplement,
          id: 'cycle-a',
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test(
    'events are immutable and project globally and by target snapshot scope',
    () async {
      await createMatter();
      await amendments.createSupplement(
        request(
          id: 'supp-history',
          targetKind: FutureMatterTargetEventKind.created,
          targetId: 'created-matter-1',
          changes: [
            const FutureMatterFieldChange(
              field: FutureMatterAmendmentField.note,
              oldValue: FutureMatterFieldValue.absent(),
              newValue: FutureMatterFieldValue.value('履歷'),
            ),
          ],
        ),
      );
      expect(
        await history.projectGlobalFutureMatterAmendmentEntries(),
        hasLength(1),
      );
      expect(
        (await history.projectForItem('item-a')).futureMatterAmendmentEntries,
        hasLength(1),
      );
      expect(
        (await history.projectForItem('item-b')).futureMatterAmendmentEntries,
        isEmpty,
      );
      await expectLater(
        database.customStatement(
          "UPDATE future_matter_amendment_events SET event_source = 'system' WHERE id = 'supp-history'",
        ),
        throwsA(anything),
      );
      await expectLater(
        database.customStatement(
          "DELETE FROM future_matter_amendment_field_changes WHERE event_id = 'supp-history'",
        ),
        throwsA(anything),
      );
    },
  );
}
