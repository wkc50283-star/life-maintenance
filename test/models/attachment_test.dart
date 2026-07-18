import 'package:flutter_test/flutter_test.dart';
import 'package:life_maintenance/models/attachment.dart';

void main() {
  test('round trips a complete photo attachment', () {
    final attachment = Attachment(
      id: 'attachment-1',
      ownerType: AttachmentOwnerType.workCaseUpdate,
      ownerId: 'update-1',
      kind: AttachmentKind.photo,
      storageIdentifier: 'attachments/2026/07/photo-1',
      originalFileName: 'IMG_0001.HEIC',
      mimeType: 'image/heic',
      byteSize: 2048000,
      capturedAt: DateTime(2026, 7, 18, 9, 30),
      contentHash: 'sha256-example',
      note: '更換零件前照片',
      createdAt: DateTime(2026, 7, 18, 9, 35),
    );

    final decoded = Attachment.fromJson(attachment.toJson());

    expect(decoded.schemaVersion, Attachment.currentSchemaVersion);
    expect(decoded.id, attachment.id);
    expect(decoded.ownerType, AttachmentOwnerType.workCaseUpdate);
    expect(decoded.ownerId, 'update-1');
    expect(decoded.kind, AttachmentKind.photo);
    expect(decoded.storageIdentifier, 'attachments/2026/07/photo-1');
    expect(decoded.originalFileName, 'IMG_0001.HEIC');
    expect(decoded.mimeType, 'image/heic');
    expect(decoded.byteSize, 2048000);
    expect(decoded.capturedAt, attachment.capturedAt);
    expect(decoded.contentHash, 'sha256-example');
    expect(decoded.state, AttachmentState.available);
    expect(decoded.isAvailable, isTrue);
    expect(decoded.isMissing, isFalse);
    expect(decoded.isDeleted, isFalse);
  });

  test('unknown owner, kind, and state use safe neutral fallbacks', () {
    final decoded = Attachment.fromJson({
      'id': 'attachment-future',
      'ownerType': 'futureOwner',
      'ownerId': 'owner-1',
      'kind': 'futureKind',
      'storageIdentifier': 'opaque-storage-id',
      'byteSize': -10,
      'state': 'futureState',
      'createdAt': '2026-07-18T10:00:00.000',
    });

    expect(decoded.ownerType, AttachmentOwnerType.unknown);
    expect(decoded.kind, AttachmentKind.other);
    expect(decoded.state, AttachmentState.unknown);
    expect(decoded.byteSize, 0);
    expect(decoded.isAvailable, isFalse);
    expect(decoded.isMissing, isFalse);
    expect(decoded.isDeleted, isFalse);
  });

  test('missing and deleted states preserve their timestamps', () {
    final createdAt = DateTime(2026, 7, 18);
    final missingAt = DateTime(2026, 7, 19);
    final deletedAt = DateTime(2026, 7, 20);
    final base = Attachment(
      id: 'attachment-2',
      ownerType: AttachmentOwnerType.maintenanceRecord,
      ownerId: 'record-1',
      kind: AttachmentKind.receipt,
      storageIdentifier: 'receipt-1',
      createdAt: createdAt,
    );

    final missing = base.copyWith(
      state: AttachmentState.missing,
      missingAt: missingAt,
    );
    final deleted = missing.copyWith(
      state: AttachmentState.deleted,
      deletedAt: deletedAt,
    );

    expect(missing.isMissing, isTrue);
    expect(missing.missingAt, missingAt);
    expect(deleted.isDeleted, isTrue);
    expect(deleted.deletedAt, deletedAt);
    expect(Attachment.fromJson(deleted.toJson()).deletedAt, deletedAt);
  });

  test('copyWith can explicitly clear optional metadata', () {
    final attachment = Attachment(
      id: 'attachment-3',
      ownerType: AttachmentOwnerType.workCaseClosure,
      ownerId: 'closure-1',
      kind: AttachmentKind.document,
      storageIdentifier: 'document-1',
      originalFileName: '完修單.pdf',
      mimeType: 'application/pdf',
      byteSize: 1024,
      capturedAt: DateTime(2026, 7, 18),
      contentHash: 'hash',
      note: '原始完修單',
      createdAt: DateTime(2026, 7, 18),
    );

    final cleared = attachment.copyWith(
      originalFileName: null,
      mimeType: null,
      byteSize: null,
      capturedAt: null,
      contentHash: null,
      note: null,
    );

    expect(cleared.originalFileName, isNull);
    expect(cleared.mimeType, isNull);
    expect(cleared.byteSize, isNull);
    expect(cleared.capturedAt, isNull);
    expect(cleared.contentHash, isNull);
    expect(cleared.note, isNull);
  });

  test('new attachments reject negative byte size', () {
    expect(
      () => Attachment(
        id: 'attachment-invalid',
        ownerType: AttachmentOwnerType.item,
        ownerId: 'item-1',
        kind: AttachmentKind.photo,
        storageIdentifier: 'photo-1',
        byteSize: -1,
        createdAt: DateTime(2026, 7, 18),
      ),
      throwsAssertionError,
    );
  });
}
