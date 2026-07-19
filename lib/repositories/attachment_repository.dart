import '../models/attachment.dart';

abstract interface class AttachmentRepository {
  Future<Attachment?> findById(String id);

  Future<List<Attachment>> listForOwner(
    AttachmentOwnerType ownerType,
    String ownerId,
  );

  Future<void> create(Attachment attachment);

  Future<void> markAvailable(String id, DateTime verifiedAt);

  Future<void> markMissing(String id, DateTime missingAt);

  /// Records deletion only after the managed storage layer removed the bytes.
  Future<void> markDeleted(String id, DateTime deletedAt);
}
