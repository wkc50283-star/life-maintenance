import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/history_projection.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_attachment_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_history_projection_repository.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftAttachmentRuntime attachmentRuntime;
  late DriftHistoryProjectionRepository history;
  final now = DateTime.utc(2026, 7, 19, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    attachmentRuntime = DriftAttachmentRuntime(repositories.attachments);
    history = DriftHistoryProjectionRepository(
      database: database,
      attachments: repositories.attachments,
    );
    await repositories.itemCategories.save(
      ItemCategoryRow(
        id: 'category-1',
        systemCode: 'other',
        displayName: '其他',
        sortOrder: 0,
        status: 'active',
        createdAt: now,
        updatedAt: now,
      ),
    );
    for (final id in const ['item-1', 'item-2']) {
      await repositories.items.save(
        ItemRow(
          id: id,
          name: '生活項目 $id',
          categoryId: 'category-1',
          status: 'active',
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  });

  tearDown(() => database.close());

  Attachment attachment({
    required String id,
    required AttachmentOwnerType ownerType,
    required String ownerId,
    String identifier = 'managed/attachment.bin',
  }) => Attachment(
    id: id,
    ownerType: ownerType,
    ownerId: ownerId,
    kind: AttachmentKind.document,
    storageIdentifier: identifier,
    mimeType: 'application/octet-stream',
    contentHash: 'sha256:$id',
    byteSize: 10,
    createdAt: now,
  );

  test(
    'projects formal facts without writing a parallel History truth',
    () async {
      final workCase = WorkCase(
        id: 'case-1',
        itemId: 'item-1',
        sourceType: WorkCaseSourceType.manual,
        caseType: WorkCaseType.repair,
        title: '處理漏水',
        status: WorkCaseStatus.inProgress,
        createdAt: now,
        updatedAt: now,
      );
      await repositories.workCases.createCaseWithInitialUpdate(
        workCase,
        WorkCaseUpdate(
          id: 'update-1',
          workCaseId: workCase.id,
          occurredAt: now.add(const Duration(hours: 1)),
          description: '已聯絡師傅',
          createdAt: now.add(const Duration(hours: 1)),
        ),
      );
      await repositories.workCases.appendUpdate(
        WorkCaseUpdate(
          id: 'update-2',
          workCaseId: workCase.id,
          occurredAt: now.add(const Duration(hours: 2)),
          description: '完成修繕測試',
          createdAt: now.add(const Duration(hours: 2)),
        ),
      );
      await repositories.workCaseClosures.closeCase(
        WorkCaseClosure(
          id: 'closure-1',
          workCaseId: workCase.id,
          completedAt: now.add(const Duration(hours: 3)),
          finalResult: '已修復',
          completionSummary: '更換接頭並測試無漏水',
          totalCost: 1200,
          createdAt: now.add(const Duration(hours: 3)),
        ),
      );
      await repositories.tasks.save(
        TaskRow(
          id: 'task-record',
          itemId: 'item-1',
          sourceType: 'manual',
          title: '簡單檢查',
          dueDate: now.add(const Duration(hours: 4)),
          status: 'completed',
          completedAt: now.add(const Duration(hours: 4)),
          createdAt: now,
          updatedAt: now.add(const Duration(hours: 4)),
        ),
      );
      await repositories.maintenanceRecords.create(
        MaintenanceRecordRow(
          id: 'record-1',
          itemId: 'item-1',
          taskId: 'task-record',
          recordType: 'regularMaintenance',
          date: now.add(const Duration(hours: 4)),
          title: '完成簡單檢查',
          partsChanged: '["墊片"]',
          cost: 50,
          createdAt: now.add(const Duration(hours: 4)),
        ),
      );
      await repositories.milestones.save(
        Milestone(
          id: 'milestone-1',
          itemId: 'item-1',
          title: '完成年度整理',
          kind: MilestoneKind.custom,
          triggerType: MilestoneTriggerType.manual,
          status: MilestoneStatus.completed,
          completedAt: now.add(const Duration(hours: 5)),
          createdAt: now,
          updatedAt: now.add(const Duration(hours: 5)),
        ),
      );
      await repositories.workCases.saveCase(
        WorkCase(
          id: 'case-open',
          itemId: 'item-1',
          sourceType: WorkCaseSourceType.manual,
          caseType: WorkCaseType.other,
          title: '仍在處理',
          status: WorkCaseStatus.waiting,
          createdAt: now,
          updatedAt: now,
        ),
      );

      for (final value in [
        attachment(
          id: 'attachment-update',
          ownerType: AttachmentOwnerType.workCaseUpdate,
          ownerId: 'update-1',
        ),
        attachment(
          id: 'attachment-closure',
          ownerType: AttachmentOwnerType.workCaseClosure,
          ownerId: 'closure-1',
        ),
        attachment(
          id: 'attachment-record',
          ownerType: AttachmentOwnerType.maintenanceRecord,
          ownerId: 'record-1',
        ),
        attachment(
          id: 'attachment-milestone',
          ownerType: AttachmentOwnerType.milestone,
          ownerId: 'milestone-1',
        ),
        attachment(
          id: 'attachment-item',
          ownerType: AttachmentOwnerType.item,
          ownerId: 'item-1',
        ),
      ]) {
        await attachmentRuntime.registerManaged(value);
      }

      final sourceCountsBefore = <int>[
        (await database.select(database.items).get()).length,
        (await database.select(database.tasks).get()).length,
        (await database.select(database.workCases).get()).length,
        (await database.select(database.workCaseUpdates).get()).length,
        (await database.select(database.workCaseClosures).get()).length,
        (await database.select(database.maintenanceRecords).get()).length,
        (await database.select(database.milestones).get()).length,
        (await database.select(database.attachments).get()).length,
      ];
      final projection = await history.projectForItem('item-1');

      expect(projection.entries, hasLength(3));
      expect(projection.entries[0], isA<MilestoneHistoryEntry>());
      expect(projection.entries[1], isA<MaintenanceRecordHistoryEntry>());
      expect(projection.entries[2], isA<WorkCaseHistoryEntry>());
      expect(projection.itemAttachments.single.id, 'attachment-item');
      final caseEntry = projection.entries[2] as WorkCaseHistoryEntry;
      expect(caseEntry.updates, hasLength(2));
      expect(caseEntry.closure?.id, 'closure-1');
      expect(caseEntry.attachments.map((value) => value.id), {
        'attachment-update',
        'attachment-closure',
      });
      final recordEntry =
          projection.entries[1] as MaintenanceRecordHistoryEntry;
      expect(recordEntry.task?.id, 'task-record');
      expect(recordEntry.record.partsChanged, ['墊片']);
      expect(recordEntry.attachments.single.id, 'attachment-record');
      expect(
        projection.entries.where((entry) => entry.sourceId == 'case-open'),
        isEmpty,
      );

      expect(await database.select(database.workCases).get(), hasLength(2));
      expect(
        await database.select(database.workCaseUpdates).get(),
        hasLength(2),
      );
      expect(
        await database.select(database.workCaseClosures).get(),
        hasLength(1),
      );
      expect(
        <int>[
          (await database.select(database.items).get()).length,
          (await database.select(database.tasks).get()).length,
          (await database.select(database.workCases).get()).length,
          (await database.select(database.workCaseUpdates).get()).length,
          (await database.select(database.workCaseClosures).get()).length,
          (await database.select(database.maintenanceRecords).get()).length,
          (await database.select(database.milestones).get()).length,
          (await database.select(database.attachments).get()).length,
        ],
        sourceCountsBefore,
        reason: 'History must remain a read-only projection of formal facts.',
      );
    },
  );

  test('orders events newest first with a stable source tie-breaker', () async {
    final sameTime = now.add(const Duration(hours: 1));
    for (final task in [
      TaskRow(
        id: 'task-b',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '同時完成 B',
        dueDate: now,
        status: 'completed',
        completedAt: sameTime,
        createdAt: now,
        updatedAt: sameTime,
      ),
      TaskRow(
        id: 'task-newest',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '較晚完成',
        dueDate: now,
        status: 'completed',
        completedAt: now.add(const Duration(hours: 2)),
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 2)),
      ),
      TaskRow(
        id: 'task-a',
        itemId: 'item-1',
        sourceType: 'manual',
        title: '同時完成 A',
        dueDate: now,
        status: 'completed',
        completedAt: sameTime,
        createdAt: now,
        updatedAt: sameTime,
      ),
    ]) {
      await repositories.tasks.save(task);
    }

    final projection = await history.projectForItem('item-1');

    expect(projection.entries.map((entry) => entry.sourceId), [
      'task-newest',
      'task-a',
      'task-b',
    ]);
  });

  test(
    'keeps a terminal legacy case visible without inventing Closure',
    () async {
      await database
          .into(database.workCases)
          .insert(
            WorkCasesCompanion.insert(
              id: 'legacy-case',
              itemId: 'item-1',
              sourceType: WorkCaseSourceType.unknown,
              caseType: WorkCaseType.other,
              title: '舊案件',
              status: WorkCaseStatus.completed,
              createdAt: now,
              updatedAt: now,
            ),
          );

      final projection = await history.projectForItem('item-1');
      final entry = projection.entries.single as WorkCaseHistoryEntry;
      expect(entry.hasFormalClosure, isFalse);
      expect(entry.closure, isNull);
    },
  );

  test('rejects cross-Item facts instead of composing false History', () async {
    await repositories.tasks.save(
      TaskRow(
        id: 'task-item-2',
        itemId: 'item-2',
        sourceType: 'manual',
        title: '另一個項目的提醒',
        dueDate: now,
        status: 'completed',
        completedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await database
        .into(database.maintenanceRecords)
        .insert(
          MaintenanceRecordsCompanion.insert(
            id: 'corrupt-record',
            itemId: 'item-1',
            taskId: const Value('task-item-2'),
            recordType: 'other',
            date: now,
            title: '錯誤跨項目紀錄',
            createdAt: now,
          ),
        );

    await expectLater(
      history.projectForItem('item-1'),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });

  test('Attachment Runtime rejects platform paths and orphan owners', () async {
    const unsafeIdentifiers = <String>[
      '/tmp/photo.jpg',
      r'C:\Users\person\photo.jpg',
      '../private/photo.jpg',
      'managed/../private/photo.jpg',
      r'managed\..\private\photo.jpg',
      'managed/%2e%2e/private/photo.jpg',
      'FILE:///tmp/photo.jpg',
      'https://example.test/photo.jpg',
      'managed/photo.jpg?token=sensitive',
      'managed/photo.jpg#fragment',
      'managed/photo\u0000.jpg',
    ];
    for (final (index, identifier) in unsafeIdentifiers.indexed) {
      final unsafe = attachment(
        id: 'unsafe-$index',
        ownerType: AttachmentOwnerType.item,
        ownerId: 'item-1',
        identifier: identifier,
      );
      await expectLater(
        attachmentRuntime.registerManaged(unsafe),
        throwsA(isA<RepositoryConstraintException>()),
        reason: identifier,
      );
      await expectLater(
        repositories.attachments.create(unsafe),
        throwsA(isA<RepositoryConstraintException>()),
        reason: 'Repository bypass: $identifier',
      );
    }
    await expectLater(
      attachmentRuntime.registerManaged(
        attachment(
          id: 'orphan',
          ownerType: AttachmentOwnerType.item,
          ownerId: 'missing-item',
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      attachmentRuntime.registerManaged(
        Attachment(
          id: 'empty-mime',
          ownerType: AttachmentOwnerType.item,
          ownerId: 'item-1',
          kind: AttachmentKind.document,
          storageIdentifier: 'managed/empty-mime.bin',
          mimeType: ' ',
          createdAt: now,
        ),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    expect(await database.select(database.attachments).get(), isEmpty);
  });

  test('Attachment lifecycle preserves missing and deletion facts', () async {
    await attachmentRuntime.registerManaged(
      attachment(
        id: 'attachment-1',
        ownerType: AttachmentOwnerType.item,
        ownerId: 'item-1',
      ),
    );
    await expectLater(
      attachmentRuntime.recordMissing(
        'attachment-1',
        now.subtract(const Duration(minutes: 1)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    final missingAt = now.add(const Duration(minutes: 1));
    final verifiedAt = now.add(const Duration(minutes: 2));
    final deletedAt = now.add(const Duration(minutes: 3));
    await attachmentRuntime.recordMissing('attachment-1', missingAt);
    expect(
      (await attachmentRuntime.findById('attachment-1'))?.isMissing,
      isTrue,
    );
    await attachmentRuntime.recordAvailable('attachment-1', verifiedAt);
    final restored = await attachmentRuntime.findById('attachment-1');
    expect(restored?.isAvailable, isTrue);
    expect(restored?.missingAt, isNull);
    expect(restored?.verifiedAt, verifiedAt);
    await attachmentRuntime.recordStorageDeleted('attachment-1', deletedAt);
    final deleted = await attachmentRuntime.findById('attachment-1');
    expect(deleted?.isDeleted, isTrue);
    expect(deleted?.deletedAt, deletedAt);
    await expectLater(
      attachmentRuntime.recordAvailable(
        'attachment-1',
        deletedAt.add(const Duration(minutes: 1)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
    await expectLater(
      attachmentRuntime.recordStorageDeleted(
        'attachment-1',
        deletedAt.add(const Duration(minutes: 2)),
      ),
      throwsA(isA<RepositoryConstraintException>()),
    );
  });
}
