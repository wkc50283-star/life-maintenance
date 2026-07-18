import 'package:drift/drift.dart';

import '../../models/attachment.dart';

@DataClassName('AttachmentRow')
@TableIndex(name: 'attachments_owner_status_idx', columns: {#ownerType, #ownerId, #state})
@TableIndex(name: 'attachments_hash_idx', columns: {#contentHash})
class Attachments extends Table {
  IntColumn get schemaVersion => integer().withDefault(const Constant(Attachment.currentSchemaVersion))();
  TextColumn get id => text()();
  TextColumn get ownerType => text()();
  TextColumn get ownerId => text()();
  TextColumn get kind => text()();
  TextColumn get storageIdentifier => text()();
  TextColumn get originalFileName => text().nullable()();
  TextColumn get mimeType => text().nullable()();
  IntColumn get byteSize => integer().nullable()();
  DateTimeColumn get capturedAt => dateTime().nullable()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get state => text().withDefault(const Constant('available'))();
  DateTimeColumn get verifiedAt => dateTime().nullable()();
  DateTimeColumn get missingAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(owner_id) <> '')",
    "CHECK (trim(storage_identifier) <> '')",
    "CHECK (owner_type IN ('item', 'maintenanceRecord', 'workCaseUpdate', 'workCaseClosure', 'milestone', 'unknown'))",
    "CHECK (state IN ('available', 'missing', 'deleted', 'unknown'))",
    'CHECK (byte_size IS NULL OR byte_size >= 0)',
    "CHECK (state <> 'missing' OR missing_at IS NOT NULL)",
    "CHECK (state <> 'deleted' OR deleted_at IS NOT NULL)",
  ];
}
