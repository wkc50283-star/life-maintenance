import 'package:drift/drift.dart';

import 'items.dart';

@DataClassName('GeneralReminderRow')
@TableIndex(
  name: 'general_reminders_item_status_idx',
  columns: {#itemId, #status},
)
class GeneralReminders extends Table {
  IntColumn get schemaVersion => integer().withDefault(const Constant(1))();

  TextColumn get id => text()();

  TextColumn get itemId => text().references(
    Items,
    #id,
    onUpdate: KeyAction.cascade,
    onDelete: KeyAction.restrict,
  )();

  TextColumn get title => text()();

  TextColumn get description => text().nullable()();

  TextColumn get reminderType => text()();

  TextColumn get status => text()();

  DateTimeColumn get createdAt => dateTime()();

  DateTimeColumn get updatedAt => dateTime()();

  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<String> get customConstraints => [
    "CHECK (trim(title) <> '')",
    "CHECK (trim(reminder_type) <> '')",
    "CHECK (trim(status) <> '')",
  ];
}
