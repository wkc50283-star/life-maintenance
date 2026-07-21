import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/database/app_database.dart';
import 'package:life_maintenance/models/attachment.dart';
import 'package:life_maintenance/models/milestone.dart';
import 'package:life_maintenance/models/milestone_enums.dart';
import 'package:life_maintenance/models/work_case.dart';
import 'package:life_maintenance/models/work_case_closure.dart';
import 'package:life_maintenance/models/work_case_enums.dart';
import 'package:life_maintenance/models/work_case_update.dart';
import 'package:life_maintenance/repositories/drift/drift_attachment_runtime.dart';
import 'package:life_maintenance/repositories/drift/drift_schema_v2_repositories.dart';
import 'package:life_maintenance/repositories/repository_constraint_exception.dart';

void main() {
  late AppDatabase database;
  late DriftSchemaV2Repositories repositories;
  late DriftAttachmentRuntime runtime;
  final createdAt = DateTime.utc(2026, 7, 21, 8);

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    repositories = DriftSchemaV2Repositories(database);
    runtime = DriftAttachmentRuntime(repositories.attachments);
    await _createOwners(repositories, createdAt);
  });

  tearDown(() => database.close());

  test(
    'creates and queries metadata for every existing formal owner',
    () async {
      final owners = <AttachmentOwnerType, String>{
        AttachmentOwnerType.item: 'item-1',
        AttachmentOwnerType.maintenanceRecord: 'record-1',
        AttachmentOwnerType.workCaseUpdate: 'update-1',
        AttachmentOwnerType.workCaseClosure: 'closure-1',
        AttachmentOwnerType.milestone: 'milestone-1',
      };

      for (final entry in owners.entries) {
        final attachment = _attachment(
          id: 'attachment-${entry.key.name}',
          ownerType: entry.key,
          ownerId: entry.value,
          createdAt: createdAt,
        );
        await runtime.registerManaged(attachment);

        expect(
          (await runtime.findById(attachment.id))?.toJson(),
          attachment.toJson(),
        );
        final ownerAttachments = await runtime.listForOwner(
          entry.key,
          entry.value,
        );
        expect(ownerAttachments.map((value) => value.toJson()), [
          attachment.toJson(),
        ]);
      }

      expect(await database.select(database.attachments).get(), hasLength(5));
      expect(
        await runtime.listForOwner(AttachmentOwnerType.item, 'item-2'),
        isEmpty,
      );
    },
  );

  test(
    'preserves available missing restored and deleted metadata states',
    () async {
      final attachment = _attachment(
        id: 'attachment-lifecycle',
        ownerType: AttachmentOwnerType.item,
        ownerId: 'item-1',
        createdAt: createdAt,
      );
      await runtime.registerManaged(attachment);

      final missingAt = createdAt.add(const Duration(minutes: 1));
      await runtime.recordMissing(attachment.id, missingAt);
      final missing = await runtime.findById(attachment.id);
      expect(missing?.state, AttachmentState.missing);
      expect(missing?.missingAt, missingAt);

      final verifiedAt = createdAt.add(const Duration(minutes: 2));
      await runtime.recordAvailable(attachment.id, verifiedAt);
      final available = await runtime.findById(attachment.id);
      expect(available?.state, AttachmentState.available);
      expect(available?.verifiedAt, verifiedAt);
      expect(available?.missingAt, isNull);

      final deletedAt = createdAt.add(const Duration(minutes: 3));
      await runtime.recordStorageDeleted(attachment.id, deletedAt);
      final deleted = await runtime.findById(attachment.id);
      expect(deleted?.state, AttachmentState.deleted);
      expect(deleted?.deletedAt, deletedAt);
      final retained = await runtime.listForOwner(
        AttachmentOwnerType.item,
        'item-1',
      );
      expect(retained.single.toJson(), deleted?.toJson());

      await expectLater(
        runtime.recordMissing(
          attachment.id,
          deletedAt.add(const Duration(minutes: 1)),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(
        (await runtime.findById(attachment.id))?.state,
        AttachmentState.deleted,
      );
    },
  );

  test(
    'rejects invalid identifiers at runtime and repository boundaries',
    () async {
      const invalidIdentifiers = <String>[
        '',
        '   ',
        '/private/photo.jpg',
        r'C:\private\photo.jpg',
        '.',
        '..',
        'managed/../photo.jpg',
        'managed/%2E%2E/photo.jpg',
        'managed/%2Fphoto.jpg',
        r'managed\photo.jpg',
        'file:///private/photo.jpg',
        'content://photos/1',
        'https://example.test/photo.jpg',
        'managed/photo.jpg?token=secret',
        'managed/photo.jpg#fragment',
        'managed/photo\u0000.jpg',
      ];

      for (final (index, identifier) in invalidIdentifiers.indexed) {
        final attachment = _attachment(
          id: 'invalid-$index',
          ownerType: AttachmentOwnerType.item,
          ownerId: 'item-1',
          createdAt: createdAt,
          identifier: identifier,
        );
        await expectLater(
          runtime.registerManaged(attachment),
          throwsA(isA<RepositoryConstraintException>()),
          reason: 'Runtime must reject $identifier',
        );
        await expectLater(
          repositories.attachments.create(attachment),
          throwsA(isA<RepositoryConstraintException>()),
          reason: 'Repository must reject bypass for $identifier',
        );
      }
      expect(await database.select(database.attachments).get(), isEmpty);
    },
  );

  test('rejects unknown and missing owners without partial metadata', () async {
    final cases = <(AttachmentOwnerType, String)>[
      (AttachmentOwnerType.item, 'missing-item'),
      (AttachmentOwnerType.maintenanceRecord, 'missing-record'),
      (AttachmentOwnerType.workCaseUpdate, 'missing-update'),
      (AttachmentOwnerType.workCaseClosure, 'missing-closure'),
      (AttachmentOwnerType.milestone, 'missing-milestone'),
      (AttachmentOwnerType.unknown, 'unknown-owner'),
    ];

    for (final (index, owner) in cases.indexed) {
      await expectLater(
        runtime.registerManaged(
          _attachment(
            id: 'orphan-$index',
            ownerType: owner.$1,
            ownerId: owner.$2,
            createdAt: createdAt,
          ),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
    }
    expect(await database.select(database.attachments).get(), isEmpty);
  });

  test(
    'constraint and lifecycle failures roll back all metadata changes',
    () async {
      final original = _attachment(
        id: 'attachment-original',
        ownerType: AttachmentOwnerType.item,
        ownerId: 'item-1',
        createdAt: createdAt,
      );
      await runtime.registerManaged(original);

      await expectLater(
        runtime.registerManaged(
          _attachment(
            id: original.id,
            ownerType: AttachmentOwnerType.milestone,
            ownerId: 'milestone-1',
            createdAt: createdAt,
            identifier: 'managed/replacement.jpg',
          ),
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        (await runtime.findById(original.id))?.toJson(),
        original.toJson(),
      );
      expect(await database.select(database.attachments).get(), hasLength(1));

      await expectLater(
        runtime.recordMissing(
          original.id,
          createdAt.subtract(const Duration(seconds: 1)),
        ),
        throwsA(isA<RepositoryConstraintException>()),
      );
      expect(
        (await runtime.findById(original.id))?.toJson(),
        original.toJson(),
      );
      expect(await database.select(database.attachments).get(), hasLength(1));
    },
  );
}

Attachment _attachment({
  required String id,
  required AttachmentOwnerType ownerType,
  required String ownerId,
  required DateTime createdAt,
  String identifier = 'managed/photos/photo.jpg',
}) => Attachment(
  id: id,
  ownerType: ownerType,
  ownerId: ownerId,
  kind: AttachmentKind.photo,
  storageIdentifier: identifier,
  originalFileName: '生活照片.jpg',
  mimeType: 'image/jpeg',
  byteSize: 2048,
  capturedAt: createdAt.subtract(const Duration(minutes: 1)),
  contentHash: 'sha256:$id',
  note: 'Attachment metadata integrity fixture',
  createdAt: createdAt,
);

Future<void> _createOwners(
  DriftSchemaV2Repositories repositories,
  DateTime now,
) async {
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
  await repositories.maintenanceRecords.create(
    MaintenanceRecordRow(
      id: 'record-1',
      itemId: 'item-1',
      recordType: 'other',
      date: now,
      title: '簡單處理紀錄',
      createdAt: now,
    ),
  );
  final workCase = WorkCase(
    id: 'case-1',
    itemId: 'item-1',
    sourceType: WorkCaseSourceType.manual,
    caseType: WorkCaseType.other,
    title: '附件歸屬驗收案件',
    status: WorkCaseStatus.inProgress,
    createdAt: now,
    updatedAt: now,
  );
  await repositories.workCases.createCaseWithInitialUpdate(
    workCase,
    WorkCaseUpdate(
      id: 'update-1',
      workCaseId: workCase.id,
      occurredAt: now,
      description: '留下附件驗收進度',
      createdAt: now,
    ),
  );
  await repositories.workCaseClosures.closeCase(
    WorkCaseClosure(
      id: 'closure-1',
      workCaseId: workCase.id,
      completedAt: now.add(const Duration(minutes: 1)),
      finalResult: '驗收完成',
      completionSummary: '正式結案附件 Owner fixture',
      totalCost: 0,
      createdAt: now.add(const Duration(minutes: 1)),
    ),
  );
  await repositories.milestones.save(
    Milestone(
      id: 'milestone-1',
      itemId: 'item-1',
      title: '附件驗收階段性重點',
      kind: MilestoneKind.custom,
      triggerType: MilestoneTriggerType.manual,
      status: MilestoneStatus.pending,
      createdAt: now,
      updatedAt: now,
    ),
  );
}
