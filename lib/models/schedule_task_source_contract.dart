enum ScheduleSourceType {
  maintenancePlan,
  generalReminder,
  milestone,
  unknown,
}

enum TaskSourceType {
  scheduledMaintenance,
  scheduledReminder,
  milestone,
  manual,
  unknown,
}

enum SourceContractViolation {
  missingItemId,
  missingMaintenancePlanId,
  unexpectedMaintenancePlanId,
  missingGeneralReminderId,
  unexpectedGeneralReminderId,
  missingMilestoneId,
  unexpectedMilestoneId,
  missingScheduleId,
  unexpectedScheduleId,
  scheduleSourceMismatch,
  itemMismatch,
  maintenancePlanItemMismatch,
  milestoneItemMismatch,
  unknownSource,
}

class SourceContractValidation {
  SourceContractValidation(Iterable<SourceContractViolation> violations)
      : violations = Set<SourceContractViolation>.unmodifiable(violations);

  final Set<SourceContractViolation> violations;

  bool get isValid => violations.isEmpty;
}

class ScheduleSourceReference {
  const ScheduleSourceReference({
    required this.itemId,
    required this.sourceType,
    this.maintenancePlanId,
    this.generalReminderId,
    this.milestoneId,
  });

  final String itemId;
  final ScheduleSourceType sourceType;
  final String? maintenancePlanId;
  final String? generalReminderId;
  final String? milestoneId;

  SourceContractValidation validate({
    String? maintenancePlanItemId,
    String? milestoneItemId,
  }) {
    final violations = <SourceContractViolation>{};

    if (itemId.trim().isEmpty) {
      violations.add(SourceContractViolation.missingItemId);
    }

    switch (sourceType) {
      case ScheduleSourceType.maintenancePlan:
        if (!_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.missingMaintenancePlanId);
        }
        if (_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.unexpectedGeneralReminderId);
        }
        if (_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.unexpectedMilestoneId);
        }
        if (maintenancePlanItemId != null && maintenancePlanItemId != itemId) {
          violations.add(SourceContractViolation.maintenancePlanItemMismatch);
        }
      case ScheduleSourceType.generalReminder:
        if (!_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.missingGeneralReminderId);
        }
        if (_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.unexpectedMaintenancePlanId);
        }
        if (_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.unexpectedMilestoneId);
        }
      case ScheduleSourceType.milestone:
        if (!_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.missingMilestoneId);
        }
        if (_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.unexpectedMaintenancePlanId);
        }
        if (_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.unexpectedGeneralReminderId);
        }
        if (milestoneItemId != null && milestoneItemId != itemId) {
          violations.add(SourceContractViolation.milestoneItemMismatch);
        }
      case ScheduleSourceType.unknown:
        violations.add(SourceContractViolation.unknownSource);
    }

    return SourceContractValidation(violations);
  }
}

class TaskSourceReference {
  const TaskSourceReference({
    required this.itemId,
    required this.sourceType,
    this.scheduleId,
    this.maintenancePlanId,
    this.generalReminderId,
    this.milestoneId,
  });

  final String itemId;
  final TaskSourceType sourceType;
  final String? scheduleId;
  final String? maintenancePlanId;
  final String? generalReminderId;
  final String? milestoneId;

  SourceContractValidation validate({
    ScheduleSourceReference? schedule,
    String? maintenancePlanItemId,
    String? milestoneItemId,
  }) {
    final violations = <SourceContractViolation>{};

    if (itemId.trim().isEmpty) {
      violations.add(SourceContractViolation.missingItemId);
    }

    switch (sourceType) {
      case TaskSourceType.scheduledMaintenance:
        _requireSchedule(violations);
        if (!_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.missingMaintenancePlanId);
        }
        if (_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.unexpectedGeneralReminderId);
        }
        if (_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.unexpectedMilestoneId);
        }
        if (maintenancePlanItemId != null && maintenancePlanItemId != itemId) {
          violations.add(SourceContractViolation.maintenancePlanItemMismatch);
        }
        _validateSchedule(
          violations,
          schedule,
          expectedType: ScheduleSourceType.maintenancePlan,
          expectedSourceId: maintenancePlanId,
          actualSourceId: schedule?.maintenancePlanId,
        );
      case TaskSourceType.scheduledReminder:
        _requireSchedule(violations);
        if (!_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.missingGeneralReminderId);
        }
        if (_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.unexpectedMaintenancePlanId);
        }
        if (_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.unexpectedMilestoneId);
        }
        _validateSchedule(
          violations,
          schedule,
          expectedType: ScheduleSourceType.generalReminder,
          expectedSourceId: generalReminderId,
          actualSourceId: schedule?.generalReminderId,
        );
      case TaskSourceType.milestone:
        if (!_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.missingMilestoneId);
        }
        if (_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.unexpectedMaintenancePlanId);
        }
        if (_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.unexpectedGeneralReminderId);
        }
        if (milestoneItemId != null && milestoneItemId != itemId) {
          violations.add(SourceContractViolation.milestoneItemMismatch);
        }
        if (_hasValue(scheduleId)) {
          _validateSchedule(
            violations,
            schedule,
            expectedType: ScheduleSourceType.milestone,
            expectedSourceId: milestoneId,
            actualSourceId: schedule?.milestoneId,
          );
        }
      case TaskSourceType.manual:
        if (_hasValue(scheduleId)) {
          violations.add(SourceContractViolation.unexpectedScheduleId);
        }
        if (_hasValue(maintenancePlanId)) {
          violations.add(SourceContractViolation.unexpectedMaintenancePlanId);
        }
        if (_hasValue(generalReminderId)) {
          violations.add(SourceContractViolation.unexpectedGeneralReminderId);
        }
        if (_hasValue(milestoneId)) {
          violations.add(SourceContractViolation.unexpectedMilestoneId);
        }
      case TaskSourceType.unknown:
        violations.add(SourceContractViolation.unknownSource);
    }

    return SourceContractValidation(violations);
  }

  void _requireSchedule(Set<SourceContractViolation> violations) {
    if (!_hasValue(scheduleId)) {
      violations.add(SourceContractViolation.missingScheduleId);
    }
  }

  void _validateSchedule(
    Set<SourceContractViolation> violations,
    ScheduleSourceReference? schedule, {
    required ScheduleSourceType expectedType,
    required String? expectedSourceId,
    required String? actualSourceId,
  }) {
    if (schedule == null) {
      if (_hasValue(scheduleId)) {
        violations.add(SourceContractViolation.scheduleSourceMismatch);
      }
      return;
    }

    if (schedule.itemId != itemId) {
      violations.add(SourceContractViolation.itemMismatch);
    }
    if (schedule.sourceType != expectedType ||
        expectedSourceId != actualSourceId) {
      violations.add(SourceContractViolation.scheduleSourceMismatch);
    }
  }
}

bool _hasValue(String? value) => value != null && value.trim().isNotEmpty;
