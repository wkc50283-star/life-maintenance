import 'package:drift/drift.dart';

import 'future_matter_amendment_events.dart';

@DataClassName('FutureMatterAmendmentRelatedPersonRow')
class FutureMatterAmendmentRelatedPeople extends Table {
  TextColumn get id => text()();
  TextColumn get eventId => text().references(
    FutureMatterAmendmentEvents,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get valueSide => text()();
  TextColumn get displayName => text()();
  TextColumn get relationNote => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (value_side IN ('old', 'new'))",
    "CHECK (trim(display_name) <> '')",
  ];
}
