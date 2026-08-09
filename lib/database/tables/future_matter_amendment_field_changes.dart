import 'package:drift/drift.dart';

import 'future_matter_amendment_events.dart';

@DataClassName('FutureMatterAmendmentFieldChangeRow')
class FutureMatterAmendmentFieldChanges extends Table {
  TextColumn get eventId => text().references(
    FutureMatterAmendmentEvents,
    #id,
    onUpdate: KeyAction.restrict,
    onDelete: KeyAction.cascade,
  )();
  TextColumn get fieldKey => text()();
  TextColumn get valueType => text()();
  TextColumn get oldState => text()();
  TextColumn get newState => text()();
  TextColumn get oldTextValue => text().nullable()();
  TextColumn get newTextValue => text().nullable()();
  IntColumn get oldIntegerValue => integer().nullable()();
  IntColumn get newIntegerValue => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {eventId, fieldKey};

  @override
  List<String> get customConstraints => [
    "CHECK (field_key IN ('completedDate', 'completedMinuteOfDay', 'note', 'attachments', 'cost', 'relatedPeople'))",
    "CHECK (value_type IN ('futureMatterDate', 'minuteOfDay', 'text', 'attachmentCollection', 'money', 'relatedPeopleCollection'))",
    "CHECK (old_state IN ('absent', 'null', 'value') AND new_state IN ('absent', 'null', 'value'))",
    "CHECK ((field_key = 'completedDate' AND value_type = 'futureMatterDate') OR (field_key = 'completedMinuteOfDay' AND value_type = 'minuteOfDay') OR (field_key = 'note' AND value_type = 'text') OR (field_key = 'attachments' AND value_type = 'attachmentCollection') OR (field_key = 'cost' AND value_type = 'money') OR (field_key = 'relatedPeople' AND value_type = 'relatedPeopleCollection'))",
    "CHECK (old_text_value IS NULL OR value_type IN ('futureMatterDate', 'text'))",
    "CHECK (new_text_value IS NULL OR value_type IN ('futureMatterDate', 'text'))",
    "CHECK (old_integer_value IS NULL OR value_type = 'minuteOfDay')",
    "CHECK (new_integer_value IS NULL OR value_type = 'minuteOfDay')",
    'CHECK (old_integer_value IS NULL OR old_integer_value BETWEEN 0 AND 1439)',
    'CHECK (new_integer_value IS NULL OR new_integer_value BETWEEN 0 AND 1439)',
    "CHECK (old_text_value IS NULL OR value_type <> 'futureMatterDate' OR (length(old_text_value) = 10 AND old_text_value GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(old_text_value, '+0 days') = old_text_value))",
    "CHECK (new_text_value IS NULL OR value_type <> 'futureMatterDate' OR (length(new_text_value) = 10 AND new_text_value GLOB '[0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]' AND date(new_text_value, '+0 days') = new_text_value))",
  ];
}
