import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/attachment.dart';
import '../../models/enums.dart';
import '../../models/maintenance_plan.dart';
import '../../models/maintenance_plan_enums.dart';
import '../../models/maintenance_plan_step.dart';
import '../../models/milestone.dart';
import '../../models/milestone_enums.dart';
import '../../models/work_case_closure.dart';

extension MaintenancePlanToCompanion on MaintenancePlan {
  MaintenancePlansCompanion toDriftCompanion() {
    return MaintenancePlansCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      itemId: Value(itemId),
      templateCardId: Value(templateCardId),
      title: Value(title),
      planType: Value(planType.name),
      description: Value(description),
      riskLevel: Value(riskLevel.name),
      estimatedMinutes: Value(estimatedMinutes),
      requiredPhotos: Value(requiredPhotos),
      requiredNote: Value(requiredNote),
      safetyNotice: Value(safetyNotice),
      status: Value(status.name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      archivedAt: Value(archivedAt),
    );
  }
}

extension MaintenancePlanStepToCompanion on MaintenancePlanStep {
  MaintenancePlanStepsCompanion toDriftCompanion(String planId) {
    return MaintenancePlanStepsCompanion(
      id: Value(id),
      maintenancePlanId: Value(planId),
      stepOrder: Value(order),
      title: Value(title),
      description: Value(description.isEmpty ? null : description),
      isRequired: Value(isRequired),
      photoRequired: Value(photoRequired),
      noteRequired: Value(noteRequired),
    );
  }
}

extension MaintenancePlanRowToModel on MaintenancePlanRow {
  MaintenancePlan toModel(List<MaintenancePlanStepRow> stepRows) {
    return MaintenancePlan(
      schemaVersion: schemaVersion,
      id: id,
      itemId: itemId,
      templateCardId: templateCardId,
      title: title,
      planType: _enumByName(
        MaintenancePlanType.values,
        planType,
        MaintenancePlanType.custom,
      ),
      description: description,
      riskLevel: _enumByName(RiskLevel.values, riskLevel, RiskLevel.unknown),
      estimatedMinutes: estimatedMinutes,
      requiredPhotos: requiredPhotos,
      requiredNote: requiredNote,
      safetyNotice: safetyNotice,
      status: _enumByName(
        MaintenancePlanStatus.values,
        status,
        MaintenancePlanStatus.archived,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      archivedAt: archivedAt,
      steps: stepRows
          .map(
            (row) => MaintenancePlanStep(
              id: row.id,
              order: row.stepOrder,
              title: row.title,
              description: row.description ?? '',
              isRequired: row.isRequired,
              photoRequired: row.photoRequired,
              noteRequired: row.noteRequired,
            ),
          )
          .toList(growable: false),
    );
  }
}

extension MilestoneToCompanion on Milestone {
  MilestonesCompanion toDriftCompanion() {
    return MilestonesCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      itemId: Value(itemId),
      title: Value(title),
      description: Value(description),
      kind: Value(kind.name),
      triggerType: Value(triggerType.name),
      sourcePlanId: Value(sourcePlanId),
      thresholdValue: Value(thresholdValue),
      thresholdUnit: Value(thresholdUnit),
      triggerDate: Value(triggerDate),
      dependencyMilestoneId: Value(dependencyMilestoneId),
      lifeStageCode: Value(lifeStageCode),
      status: Value(status.name),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      reachedAt: Value(reachedAt),
      acknowledgedAt: Value(acknowledgedAt),
      startedAt: Value(startedAt),
      completedAt: Value(completedAt),
      canceledAt: Value(canceledAt),
      archivedAt: Value(archivedAt),
      workCaseId: Value(workCaseId),
      cancellationReason: Value(cancellationReason),
    );
  }
}

extension MilestoneRowToModel on MilestoneRow {
  Milestone toModel() {
    return Milestone(
      schemaVersion: schemaVersion,
      id: id,
      itemId: itemId,
      title: title,
      description: description,
      kind: _enumByName(MilestoneKind.values, kind, MilestoneKind.custom),
      triggerType: _enumByName(
        MilestoneTriggerType.values,
        triggerType,
        MilestoneTriggerType.unknown,
      ),
      sourcePlanId: sourcePlanId,
      thresholdValue: thresholdValue,
      thresholdUnit: thresholdUnit,
      triggerDate: triggerDate,
      dependencyMilestoneId: dependencyMilestoneId,
      lifeStageCode: lifeStageCode,
      status: _enumByName(
        MilestoneStatus.values,
        status,
        MilestoneStatus.archived,
      ),
      createdAt: createdAt,
      updatedAt: updatedAt,
      reachedAt: reachedAt,
      acknowledgedAt: acknowledgedAt,
      startedAt: startedAt,
      completedAt: completedAt,
      canceledAt: canceledAt,
      archivedAt: archivedAt,
      workCaseId: workCaseId,
      cancellationReason: cancellationReason,
    );
  }
}

extension WorkCaseClosureToCompanion on WorkCaseClosure {
  WorkCaseClosuresCompanion toDriftCompanion() {
    return WorkCaseClosuresCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      workCaseId: Value(workCaseId),
      completedAt: Value(completedAt),
      finalResult: Value(finalResult),
      completionSummary: Value(completionSummary),
      totalCost: Value(totalCost),
      followUpNotes: Value(followUpNotes),
      followUpType: Value(followUpType.name),
      nextScheduleId: Value(nextScheduleId),
      nextReminderTaskId: Value(nextReminderTaskId),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }
}

extension WorkCaseClosureRowToModel on WorkCaseClosureRow {
  WorkCaseClosure toModel() {
    return WorkCaseClosure(
      schemaVersion: schemaVersion,
      id: id,
      workCaseId: workCaseId,
      completedAt: completedAt,
      finalResult: finalResult,
      completionSummary: completionSummary,
      totalCost: totalCost,
      followUpNotes: followUpNotes,
      followUpType: _enumByName(
        WorkCaseFollowUpType.values,
        followUpType,
        WorkCaseFollowUpType.unknown,
      ),
      nextScheduleId: nextScheduleId,
      nextReminderTaskId: nextReminderTaskId,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

extension AttachmentToCompanion on Attachment {
  AttachmentsCompanion toDriftCompanion() {
    return AttachmentsCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      ownerType: Value(ownerType.name),
      ownerId: Value(ownerId),
      kind: Value(kind.name),
      storageIdentifier: Value(storageIdentifier),
      originalFileName: Value(originalFileName),
      mimeType: Value(mimeType),
      byteSize: Value(byteSize),
      capturedAt: Value(capturedAt),
      contentHash: Value(contentHash),
      state: Value(state.name),
      verifiedAt: Value(verifiedAt),
      missingAt: Value(missingAt),
      deletedAt: Value(deletedAt),
      note: Value(note),
      createdAt: Value(createdAt),
    );
  }
}

extension AttachmentRowToModel on AttachmentRow {
  Attachment toModel() {
    return Attachment(
      schemaVersion: schemaVersion,
      id: id,
      ownerType: _enumByName(
        AttachmentOwnerType.values,
        ownerType,
        AttachmentOwnerType.unknown,
      ),
      ownerId: ownerId,
      kind: _enumByName(AttachmentKind.values, kind, AttachmentKind.other),
      storageIdentifier: storageIdentifier,
      originalFileName: originalFileName,
      mimeType: mimeType,
      byteSize: byteSize,
      capturedAt: capturedAt,
      contentHash: contentHash,
      state: _enumByName(
        AttachmentState.values,
        state,
        AttachmentState.unknown,
      ),
      verifiedAt: verifiedAt,
      missingAt: missingAt,
      deletedAt: deletedAt,
      note: note,
      createdAt: createdAt,
    );
  }
}

T _enumByName<T extends Enum>(List<T> values, String name, T fallback) {
  for (final value in values) {
    if (value.name == name) {
      return value;
    }
  }
  return fallback;
}
