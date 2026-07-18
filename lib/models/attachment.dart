enum AttachmentOwnerType {
  item,
  maintenanceRecord,
  workCaseUpdate,
  workCaseClosure,
  milestone,
  unknown,
}

enum AttachmentKind { photo, document, receipt, other }

enum AttachmentState { available, missing, deleted, unknown }

class Attachment {
  const Attachment({
    required this.id,
    required this.ownerType,
    required this.ownerId,
    required this.kind,
    required this.storageIdentifier,
    required this.createdAt,
    this.schemaVersion = currentSchemaVersion,
    this.originalFileName,
    this.mimeType,
    this.byteSize,
    this.capturedAt,
    this.contentHash,
    this.verifiedAt,
    this.state = AttachmentState.available,
    this.missingAt,
    this.deletedAt,
    this.note,
  }) : assert(byteSize == null || byteSize >= 0);

  static const int currentSchemaVersion = 1;
  static const Object _notProvided = Object();

  final int schemaVersion;
  final String id;
  final AttachmentOwnerType ownerType;
  final String ownerId;
  final AttachmentKind kind;
  final String storageIdentifier;
  final String? originalFileName;
  final String? mimeType;
  final int? byteSize;
  final DateTime? capturedAt;
  final String? contentHash;
  final DateTime? verifiedAt;
  final AttachmentState state;
  final DateTime? missingAt;
  final DateTime? deletedAt;
  final String? note;
  final DateTime createdAt;

  bool get isAvailable => state == AttachmentState.available;
  bool get isMissing => state == AttachmentState.missing;
  bool get isDeleted => state == AttachmentState.deleted;

  factory Attachment.fromJson(Map<String, dynamic> json) {
    return Attachment(
      schemaVersion: _readSchemaVersion(json['schemaVersion']),
      id: json['id'] as String,
      ownerType: _readEnum(
        AttachmentOwnerType.values,
        json['ownerType'],
        AttachmentOwnerType.unknown,
      ),
      ownerId: json['ownerId'] as String,
      kind: _readEnum(
        AttachmentKind.values,
        json['kind'],
        AttachmentKind.other,
      ),
      storageIdentifier: json['storageIdentifier'] as String,
      originalFileName: _readNullableString(json['originalFileName']),
      mimeType: _readNullableString(json['mimeType']),
      byteSize: _readNonNegativeInt(json['byteSize']),
      capturedAt: _readNullableDate(json['capturedAt']),
      contentHash: _readNullableString(json['contentHash']),
      verifiedAt: _readNullableDate(json['verifiedAt']),
      state: _readEnum(
        AttachmentState.values,
        json['state'],
        AttachmentState.unknown,
      ),
      missingAt: _readNullableDate(json['missingAt']),
      deletedAt: _readNullableDate(json['deletedAt']),
      note: _readNullableString(json['note']),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'schemaVersion': schemaVersion,
      'id': id,
      'ownerType': ownerType.name,
      'ownerId': ownerId,
      'kind': kind.name,
      'storageIdentifier': storageIdentifier,
      'originalFileName': originalFileName,
      'mimeType': mimeType,
      'byteSize': byteSize,
      'capturedAt': capturedAt?.toIso8601String(),
      'contentHash': contentHash,
      'verifiedAt': verifiedAt?.toIso8601String(),
      'state': state.name,
      'missingAt': missingAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
      'note': note,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Attachment copyWith({
    int? schemaVersion,
    String? id,
    AttachmentOwnerType? ownerType,
    String? ownerId,
    AttachmentKind? kind,
    String? storageIdentifier,
    Object? originalFileName = _notProvided,
    Object? mimeType = _notProvided,
    Object? byteSize = _notProvided,
    Object? capturedAt = _notProvided,
    Object? contentHash = _notProvided,
    Object? verifiedAt = _notProvided,
    AttachmentState? state,
    Object? missingAt = _notProvided,
    Object? deletedAt = _notProvided,
    Object? note = _notProvided,
    DateTime? createdAt,
  }) {
    return Attachment(
      schemaVersion: schemaVersion ?? this.schemaVersion,
      id: id ?? this.id,
      ownerType: ownerType ?? this.ownerType,
      ownerId: ownerId ?? this.ownerId,
      kind: kind ?? this.kind,
      storageIdentifier: storageIdentifier ?? this.storageIdentifier,
      originalFileName: identical(originalFileName, _notProvided)
          ? this.originalFileName
          : originalFileName as String?,
      mimeType: identical(mimeType, _notProvided)
          ? this.mimeType
          : mimeType as String?,
      byteSize: identical(byteSize, _notProvided)
          ? this.byteSize
          : byteSize as int?,
      capturedAt: identical(capturedAt, _notProvided)
          ? this.capturedAt
          : capturedAt as DateTime?,
      contentHash: identical(contentHash, _notProvided)
          ? this.contentHash
          : contentHash as String?,
      verifiedAt: identical(verifiedAt, _notProvided)
          ? this.verifiedAt
          : verifiedAt as DateTime?,
      state: state ?? this.state,
      missingAt: identical(missingAt, _notProvided)
          ? this.missingAt
          : missingAt as DateTime?,
      deletedAt: identical(deletedAt, _notProvided)
          ? this.deletedAt
          : deletedAt as DateTime?,
      note: identical(note, _notProvided) ? this.note : note as String?,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

int _readSchemaVersion(Object? value) {
  if (value is int && value > 0) {
    return value;
  }
  if (value is num && value > 0) {
    return value.toInt();
  }
  return Attachment.currentSchemaVersion;
}

T _readEnum<T extends Enum>(List<T> values, Object? value, T fallback) {
  if (value is String) {
    for (final candidate in values) {
      if (candidate.name == value) {
        return candidate;
      }
    }
  }
  return fallback;
}

String? _readNullableString(Object? value) {
  return value is String ? value : null;
}

DateTime? _readNullableDate(Object? value) {
  return value is String ? DateTime.tryParse(value) : null;
}

int? _readNonNegativeInt(Object? value) {
  if (value is num) {
    final normalized = value.toInt();
    return normalized < 0 ? 0 : normalized;
  }
  return null;
}
