import 'package:drift/drift.dart';

import 'future_matter_amendment_events.dart';

@DataClassName('FutureMatterAmendmentMoneyValueRow')
class FutureMatterAmendmentMoneyValues extends Table {
  TextColumn get eventId => text().references(
    FutureMatterAmendmentEvents,
    #id,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get valueSide => text()();
  IntColumn get amountMinor => integer()();
  TextColumn get currency => text()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, valueSide};

  @override
  List<String> get customConstraints => [
    "CHECK (value_side IN ('old', 'new'))",
    'CHECK (amount_minor >= 0)',
    "CHECK (length(currency) = 3 AND currency GLOB '[A-Z][A-Z][A-Z]')",
  ];
}
