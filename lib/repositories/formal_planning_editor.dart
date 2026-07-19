import '../app/app_composition_root.dart';
import '../database/app_database.dart';
import '../models/maintenance_plan.dart';
import '../models/milestone.dart';

/// Presentation-facing write boundary for the formal planning repositories.
///
/// It deliberately exposes plain edit values instead of Drift rows. All writes
/// still pass through the repositories already owned by [AppCompositionRoot].
class FormalPlanningEditor {
  FormalPlanningEditor._(this._root);

  final AppCompositionRoot _root;

  static FormalPlanningEditor? from(AppRuntimeDependencies dependencies) {
    return dependencies is AppCompositionRoot
        ? FormalPlanningEditor._(dependencies)
        : null;
  }

  Future<List<EditableCategory>> loadCategories() async => [
    for (final row in await _root.driftRepositories.itemCategories.listAll())
      EditableCategory(
        id: row.id,
        systemCode: row.systemCode,
        customName: row.customName,
        displayName: row.displayName,
        sortOrder: row.sortOrder,
        status: row.status,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        archivedAt: row.archivedAt,
      ),
  ];

  Future<List<EditableItem>> loadItems() async => [
    for (final row in await _root.driftRepositories.items.listAll())
      EditableItem(
        id: row.id,
        name: row.name,
        categoryId: row.categoryId,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        purchaseDate: row.purchaseDate,
        warrantyEndDate: row.warrantyEndDate,
        expectedLifeYears: row.expectedLifeYears,
        location: row.location,
        note: row.note,
        status: row.status,
        archivedAt: row.archivedAt,
      ),
  ];

  Future<EditableItem?> findItem(String id) async {
    final row = await _root.driftRepositories.items.findById(id);
    if (row == null) return null;
    return EditableItem(
      id: row.id,
      name: row.name,
      categoryId: row.categoryId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      purchaseDate: row.purchaseDate,
      warrantyEndDate: row.warrantyEndDate,
      expectedLifeYears: row.expectedLifeYears,
      location: row.location,
      note: row.note,
      status: row.status,
      archivedAt: row.archivedAt,
    );
  }

  Future<void> saveCategory(EditableCategory value) {
    return _root.driftRepositories.itemCategories.save(
      ItemCategoryRow(
        id: value.id,
        systemCode: _textOrNull(value.systemCode),
        customName: _textOrNull(value.customName),
        displayName: value.displayName.trim(),
        sortOrder: value.sortOrder,
        status: value.status,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        archivedAt: value.archivedAt,
      ),
    );
  }

  Future<void> saveItem(EditableItem value) {
    return _root.driftRepositories.items.save(
      ItemRow(
        id: value.id,
        name: value.name.trim(),
        categoryId: value.categoryId,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        purchaseDate: value.purchaseDate,
        warrantyEndDate: value.warrantyEndDate,
        expectedLifeYears: value.expectedLifeYears,
        location: _textOrNull(value.location),
        note: _textOrNull(value.note),
        status: value.status,
        archivedAt: value.archivedAt,
      ),
    );
  }

  Future<List<MaintenancePlan>> loadPlans(String itemId) =>
      _root.driftRepositories.maintenancePlans.listForItem(itemId);

  Future<void> savePlan(MaintenancePlan value) =>
      _root.driftRepositories.maintenancePlans.save(value);

  Future<List<EditableReminder>> loadReminders(String itemId) async => [
    for (final row
        in await _root.driftRepositories.generalReminders.listForItem(itemId))
      EditableReminder(
        id: row.id,
        itemId: row.itemId,
        title: row.title,
        description: row.description,
        reminderType: row.reminderType,
        status: row.status,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        archivedAt: row.archivedAt,
      ),
  ];

  Future<void> saveReminder(EditableReminder value) {
    return _root.driftRepositories.generalReminders.save(
      GeneralReminderRow(
        schemaVersion: 1,
        id: value.id,
        itemId: value.itemId,
        title: value.title.trim(),
        description: _textOrNull(value.description),
        reminderType: value.reminderType,
        status: value.status,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        archivedAt: value.archivedAt,
      ),
    );
  }

  Future<List<Milestone>> loadMilestones(String itemId) =>
      _root.driftRepositories.milestones.listForItem(itemId);

  Future<void> saveMilestone(Milestone value) =>
      _root.driftRepositories.milestones.save(value);

  Future<List<EditableSchedule>> loadSchedules(String itemId) async => [
    for (final row in await _root.driftRepositories.schedules.listForItem(
      itemId,
    ))
      EditableSchedule(
        id: row.id,
        itemId: row.itemId,
        sourceType: row.sourceType,
        sourceId:
            row.maintenancePlanId ??
            row.generalReminderId ??
            row.milestoneId ??
            '',
        cycleType: row.cycleType,
        interval: row.interval,
        startDate: row.startDate,
        nextDueDate: row.nextDueDate,
        reminderTime: row.reminderTime,
        status: row.status,
        anchorPolicy: row.anchorPolicy,
        userDefinedNextDate: row.userDefinedNextDate,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
        endedAt: row.endedAt,
      ),
  ];

  Future<void> saveSchedule(EditableSchedule value) {
    return _root.driftRepositories.schedules.save(
      ScheduleRow(
        id: value.id,
        itemId: value.itemId,
        sourceType: value.sourceType,
        maintenancePlanId: value.sourceType == 'maintenancePlan'
            ? value.sourceId
            : null,
        generalReminderId: value.sourceType == 'generalReminder'
            ? value.sourceId
            : null,
        milestoneId: value.sourceType == 'milestone' ? value.sourceId : null,
        cycleType: value.cycleType,
        interval: value.interval,
        startDate: value.startDate,
        nextDueDate: value.nextDueDate,
        reminderTime: _textOrNull(value.reminderTime),
        status: value.status,
        anchorPolicy: value.anchorPolicy,
        userDefinedNextDate: value.userDefinedNextDate,
        createdAt: value.createdAt,
        updatedAt: value.updatedAt,
        endedAt: value.endedAt,
      ),
    );
  }
}

class EditableCategory {
  const EditableCategory({
    required this.id,
    required this.displayName,
    required this.sortOrder,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.systemCode,
    this.customName,
    this.archivedAt,
  });

  final String id;
  final String? systemCode;
  final String? customName;
  final String displayName;
  final int sortOrder;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class EditableItem {
  const EditableItem({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.createdAt,
    required this.updatedAt,
    required this.status,
    this.purchaseDate,
    this.warrantyEndDate,
    this.expectedLifeYears,
    this.location,
    this.note,
    this.archivedAt,
  });

  final String id;
  final String name;
  final String categoryId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? purchaseDate;
  final DateTime? warrantyEndDate;
  final int? expectedLifeYears;
  final String? location;
  final String? note;
  final String status;
  final DateTime? archivedAt;
}

class EditableReminder {
  const EditableReminder({
    required this.id,
    required this.itemId,
    required this.title,
    required this.reminderType,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.description,
    this.archivedAt,
  });

  final String id;
  final String itemId;
  final String title;
  final String? description;
  final String reminderType;
  final String status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? archivedAt;
}

class EditableSchedule {
  const EditableSchedule({
    required this.id,
    required this.itemId,
    required this.sourceType,
    required this.sourceId,
    required this.cycleType,
    required this.interval,
    required this.startDate,
    required this.nextDueDate,
    required this.status,
    required this.anchorPolicy,
    required this.createdAt,
    required this.updatedAt,
    this.reminderTime,
    this.userDefinedNextDate,
    this.endedAt,
  });

  final String id;
  final String itemId;
  final String sourceType;
  final String sourceId;
  final String cycleType;
  final int interval;
  final DateTime startDate;
  final DateTime nextDueDate;
  final String? reminderTime;
  final String status;
  final String anchorPolicy;
  final DateTime? userDefinedNextDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? endedAt;
}

String? _textOrNull(String? value) {
  final text = value?.trim();
  return text == null || text.isEmpty ? null : text;
}
