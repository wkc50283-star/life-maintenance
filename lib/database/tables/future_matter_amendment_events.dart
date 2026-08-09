import 'package:drift/drift.dart';

import 'future_matters.dart';

@DataClassName('FutureMatterAmendmentEventRow')
@TableIndex(
  name: 'future_matter_amendment_events_matter_order_idx',
  columns: {#futureMatterId, #recordedAt, #id},
)
@TableIndex(
  name: 'future_matter_amendment_events_target_idx',
  columns: {#targetEventKind, #targetEventId},
)
@TableIndex(
  name: 'future_matter_amendment_events_source_reference_idx',
  columns: {#sourceReferenceKind, #sourceReferenceId},
)
class FutureMatterAmendmentEvents extends Table {
  TextColumn get id => text()();
  TextColumn get futureMatterId => text().references(
    FutureMatters,
    #id,
    onUpdate: KeyAction.restrict,
    onDelete: KeyAction.restrict,
  )();
  TextColumn get eventType => text()();
  TextColumn get targetEventKind => text()();
  TextColumn get targetEventId => text()();
  DateTimeColumn get occurredAt => dateTime().nullable()();
  DateTimeColumn get recordedAt => dateTime()();
  TextColumn get eventSource => text()();
  TextColumn get sourceReferenceKind => text().nullable()();
  TextColumn get sourceReferenceId => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (event_type IN ('supplement', 'correction'))",
    "CHECK (target_event_kind IN ('created', 'change', 'completed', 'supplement', 'correction'))",
    "CHECK (trim(target_event_id) <> '')",
    "CHECK (event_source IN ('manual', 'ai', 'backfill', 'system'))",
    "CHECK ((source_reference_kind IS NULL AND source_reference_id IS NULL) OR (source_reference_kind IN ('futureMatterCreatedEvent', 'futureMatterChangeEvent', 'futureMatterCompletedEvent', 'futureMatterAmendmentEvent', 'maintenanceRecord') AND source_reference_id IS NOT NULL AND trim(source_reference_id) <> ''))",
  ];
}
