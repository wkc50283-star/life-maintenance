import '../../database/app_database.dart';
import '../../models/enums.dart';
import '../../models/schedule.dart';
import '../../models/schedule_anchor_policy.dart';
import '../repository_constraint_exception.dart';
import '../schedule_repository.dart';
import 'drift_schema_v2_repositories.dart';

/// Adapts the existing runtime Schedule model to the formal Schema v2 source
/// contract. SharedPreferences is never read or written by this repository.
class DriftScheduleRuntimeRepository implements ScheduleRepository {
  DriftScheduleRuntimeRepository({
    required AppDatabase database,
    required DriftSchemaV2Repositories repositories,
  }) : _database = database,
       _repositories = repositories;

  static const String _manualReminderCardId = 'manual-expiry-reminder';

  final AppDatabase _database;
  final DriftSchemaV2Repositories _repositories;

  @override
  Future<List<Schedule>> loadSchedules() async {
    final rows = await _repositories.schedules.listAll();
    final schedules = <Schedule>[];
    for (final row in rows) {
      schedules.add(await _toRuntimeModel(row));
    }
    return schedules;
  }

  @override
  Future<void> saveSchedules(List<Schedule> schedules) async {
    final ids = schedules.map((schedule) => schedule.id).toSet();
    if (ids.length != schedules.length) {
      throw const RepositoryConstraintException(
        'Schedule ids must be unique in one transaction.',
      );
    }

    await _database.transaction(() async {
      final existingRows = await _repositories.schedules.listAll();
      final existingById = {for (final row in existingRows) row.id: row};
      final removedIds = existingById.keys.toSet().difference(ids);
      if (removedIds.isNotEmpty) {
        throw const RepositoryConstraintException(
          'Runtime Schedule updates cannot implicitly delete formal data.',
        );
      }

      for (final schedule in schedules) {
        final existing = existingById[schedule.id];
        if (existing == null) {
          await _createManualReminderSchedule(schedule);
        } else {
          await _updateSchedule(schedule, existing);
        }
      }
    });
  }

  Future<Schedule> _toRuntimeModel(ScheduleRow row) async {
    String? title;
    var cardId = row.legacyCardId;
    switch (row.sourceType) {
      case 'maintenancePlan':
        final plan = await _repositories.maintenancePlans.findById(
          row.maintenancePlanId!,
        );
        if (plan == null) {
          throw RepositoryConstraintException(
            'Schedule ${row.id} has no MaintenancePlan.',
          );
        }
        title = plan.title;
        cardId ??= plan.templateCardId ?? plan.id;
      case 'generalReminder':
        final reminder = await _repositories.generalReminders.findById(
          row.generalReminderId!,
        );
        if (reminder == null) {
          throw RepositoryConstraintException(
            'Schedule ${row.id} has no GeneralReminder.',
          );
        }
        title = reminder.title;
        cardId ??= _manualReminderCardId;
      case 'milestone':
        final milestone = await _repositories.milestones.findById(
          row.milestoneId!,
        );
        if (milestone == null) {
          throw RepositoryConstraintException(
            'Schedule ${row.id} has no Milestone.',
          );
        }
        title = milestone.title;
        cardId ??= milestone.id;
      case 'unknown':
        cardId ??= '';
      default:
        throw RepositoryConstraintException(
          'Unsupported Schedule source ${row.sourceType}.',
        );
    }

    return Schedule(
      id: row.id,
      itemId: row.itemId,
      cardId: cardId,
      cycleType: _cycleType(row.cycleType),
      interval: row.interval,
      startDate: row.startDate,
      nextDueDate: row.nextDueDate,
      title: title,
      reminderTime: row.reminderTime,
      status: _scheduleStatus(row.status),
      strictPeriodMode:
          _anchorPolicy(row.anchorPolicy) ==
          ScheduleAnchorPolicy.fixedCalendarPeriod,
    );
  }

  Future<void> _createManualReminderSchedule(Schedule schedule) async {
    if (schedule.cardId != _manualReminderCardId) {
      throw const RepositoryConstraintException(
        'A new runtime Schedule requires an explicit GeneralReminder source.',
      );
    }
    if (schedule.interval <= 0) {
      throw const RepositoryConstraintException(
        'Schedule interval must be greater than zero.',
      );
    }

    final reminderId = 'runtime-reminder-${schedule.id}';
    final title = schedule.title?.trim();
    await _repositories.generalReminders.save(
      GeneralReminderRow(
        schemaVersion: 1,
        id: reminderId,
        itemId: schedule.itemId,
        title: title?.isNotEmpty == true ? title! : '提醒事項',
        reminderType: 'expiry',
        status: schedule.status.name,
        createdAt: schedule.startDate,
        updatedAt: schedule.startDate,
      ),
    );
    await _repositories.schedules.save(
      _scheduleRow(
        schedule,
        sourceType: 'generalReminder',
        generalReminderId: reminderId,
        createdAt: schedule.startDate,
      ),
    );
  }

  Future<void> _updateSchedule(Schedule schedule, ScheduleRow existing) async {
    if (schedule.itemId != existing.itemId) {
      throw const RepositoryConstraintException(
        'A Schedule cannot move to another Item.',
      );
    }
    if (_sameRuntimeSchedule(schedule, await _toRuntimeModel(existing))) {
      return;
    }
    final now = DateTime.now();
    if (existing.sourceType == 'generalReminder') {
      final reminder = await _repositories.generalReminders.findById(
        existing.generalReminderId!,
      );
      if (reminder == null) {
        throw RepositoryConstraintException(
          'Schedule ${schedule.id} has no GeneralReminder.',
        );
      }
      final title = schedule.title?.trim();
      await _repositories.generalReminders.save(
        reminder.copyWith(
          title: title?.isNotEmpty == true ? title! : reminder.title,
          status: schedule.status.name,
          updatedAt: now,
        ),
      );
    }

    await _repositories.schedules.save(
      _scheduleRow(
        schedule,
        sourceType: existing.sourceType,
        maintenancePlanId: existing.maintenancePlanId,
        generalReminderId: existing.generalReminderId,
        milestoneId: existing.milestoneId,
        createdAt: existing.createdAt,
        existingAnchorPolicy: existing.anchorPolicy,
        endedAt: schedule.status == ScheduleStatus.ended
            ? existing.endedAt ?? now
            : null,
        updatedAt: now,
      ),
    );
  }

  ScheduleRow _scheduleRow(
    Schedule schedule, {
    required String sourceType,
    required DateTime createdAt,
    String? maintenancePlanId,
    String? generalReminderId,
    String? milestoneId,
    String? existingAnchorPolicy,
    DateTime? endedAt,
    DateTime? updatedAt,
  }) {
    final anchorPolicy = schedule.cycleType == CycleType.custom
        ? ScheduleAnchorPolicy.userDefined.name
        : existingAnchorPolicy == 'completionBased'
        ? ScheduleAnchorPolicy.completionBased.name
        : ScheduleAnchorPolicy.fixedCalendarPeriod.name;
    return ScheduleRow(
      id: schedule.id,
      itemId: schedule.itemId,
      sourceType: sourceType,
      maintenancePlanId: maintenancePlanId,
      generalReminderId: generalReminderId,
      milestoneId: milestoneId,
      legacyCardId: schedule.cardId,
      cycleType: schedule.cycleType.name,
      interval: schedule.interval,
      startDate: schedule.startDate,
      nextDueDate: schedule.nextDueDate,
      reminderTime: schedule.reminderTime,
      status: schedule.status.name,
      anchorPolicy: anchorPolicy,
      userDefinedNextDate: anchorPolicy == 'userDefined'
          ? schedule.nextDueDate
          : null,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      endedAt: endedAt,
    );
  }
}

bool _sameRuntimeSchedule(Schedule left, Schedule right) =>
    left.id == right.id &&
    left.itemId == right.itemId &&
    left.cardId == right.cardId &&
    left.cycleType == right.cycleType &&
    left.interval == right.interval &&
    left.startDate == right.startDate &&
    left.nextDueDate == right.nextDueDate &&
    left.title == right.title &&
    left.reminderTime == right.reminderTime &&
    left.status == right.status &&
    left.strictPeriodMode == right.strictPeriodMode;

CycleType _cycleType(String value) {
  try {
    return CycleType.values.byName(value);
  } catch (_) {
    throw RepositoryConstraintException('Unsupported cycle type $value.');
  }
}

ScheduleStatus _scheduleStatus(String value) {
  try {
    return ScheduleStatus.values.byName(value);
  } catch (_) {
    throw RepositoryConstraintException('Unsupported Schedule status $value.');
  }
}

ScheduleAnchorPolicy _anchorPolicy(String value) {
  try {
    return ScheduleAnchorPolicy.values.byName(value);
  } catch (_) {
    throw RepositoryConstraintException(
      'Unsupported Schedule anchor policy $value.',
    );
  }
}
