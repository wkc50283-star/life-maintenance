import '../../models/attachment.dart';
import '../attachment_repository.dart';
import '../attachment_runtime.dart';
import '../repository_constraint_exception.dart';

class DriftAttachmentRuntime implements AttachmentRuntime {
  DriftAttachmentRuntime(this._attachments);

  final AttachmentRepository _attachments;

  @override
  Future<Attachment?> findById(String id) => _attachments.findById(id);

  @override
  Future<List<Attachment>> listForOwner(
    AttachmentOwnerType ownerType,
    String ownerId,
  ) => _attachments.listForOwner(ownerType, ownerId);

  @override
  Future<void> registerManaged(Attachment attachment) async {
    _validateManagedIdentifier(attachment.storageIdentifier);
    await _attachments.create(attachment);
  }

  @override
  Future<void> recordAvailable(String id, DateTime verifiedAt) =>
      _attachments.markAvailable(id, verifiedAt);

  @override
  Future<void> recordMissing(String id, DateTime missingAt) =>
      _attachments.markMissing(id, missingAt);

  @override
  Future<void> recordStorageDeleted(String id, DateTime deletedAt) =>
      _attachments.markDeleted(id, deletedAt);

  void _validateManagedIdentifier(String identifier) {
    final normalized = identifier.trim();
    final looksLikeAbsolutePath =
        normalized.startsWith('/') ||
        normalized.startsWith(r'\\') ||
        RegExp(r'^[A-Za-z]:[\\/]').hasMatch(normalized);
    final looksLikePlatformUri =
        normalized.startsWith('file:') ||
        normalized.startsWith('content:') ||
        normalized.startsWith('ph:');
    if (looksLikeAbsolutePath || looksLikePlatformUri) {
      throw const RepositoryConstraintException(
        'Attachment requires a stable managed identifier, not a platform path.',
      );
    }
  }
}
