import '../models/attachment.dart';

/// Formal boundary for Attachment metadata and lifecycle.
///
/// Platform paths never cross this contract. A storage adapter must first
/// convert platform-specific file access into a stable managed identifier.
abstract interface class AttachmentRuntime {
  Future<Attachment?> findById(String id);

  Future<List<Attachment>> listForOwner(
    AttachmentOwnerType ownerType,
    String ownerId,
  );

  Future<void> registerManaged(Attachment attachment);

  Future<void> recordAvailable(String id, DateTime verifiedAt);

  Future<void> recordMissing(String id, DateTime missingAt);

  /// Must be called only after managed storage confirms byte deletion.
  Future<void> recordStorageDeleted(String id, DateTime deletedAt);
}
