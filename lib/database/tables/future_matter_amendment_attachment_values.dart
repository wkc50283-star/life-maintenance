import 'package:drift/drift.dart';

import 'future_matter_amendment_events.dart';

@DataClassName('FutureMatterAmendmentAttachmentValueRow')
class FutureMatterAmendmentAttachmentValues extends Table {
  TextColumn get eventId => text().references(
    FutureMatterAmendmentEvents,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get valueSide => text()();
  TextColumn get attachmentId => text()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, valueSide, attachmentId};

  @override
  List<String> get customConstraints => [
    "CHECK (value_side IN ('old', 'new'))",
  ];
}
