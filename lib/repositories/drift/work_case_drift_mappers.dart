import 'package:drift/drift.dart';

import '../../database/app_database.dart';
import '../../models/work_case.dart';
import '../../models/work_case_update.dart';

extension WorkCaseToCompanion on WorkCase {
  WorkCasesCompanion toCompanion() {
    return WorkCasesCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      itemId: Value(itemId),
      sourceType: Value(sourceType),
      sourceId: Value(sourceId),
      caseType: Value(caseType),
      title: Value(title),
      description: Value(description),
      occurredAt: Value(occurredAt),
      startedAt: Value(startedAt),
      status: Value(status),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      closedAt: Value(closedAt),
      canceledAt: Value(canceledAt),
      closeResult: Value(closeResult),
      cancellationReason: Value(cancellationReason),
    );
  }
}

extension WorkCaseRowToModel on WorkCaseRow {
  WorkCase toModel() {
    return WorkCase(
      schemaVersion: schemaVersion,
      id: id,
      itemId: itemId,
      sourceType: sourceType,
      sourceId: sourceId,
      caseType: caseType,
      title: title,
      description: description,
      occurredAt: occurredAt,
      startedAt: startedAt,
      status: status,
      createdAt: createdAt,
      updatedAt: updatedAt,
      closedAt: closedAt,
      canceledAt: canceledAt,
      closeResult: closeResult,
      cancellationReason: cancellationReason,
    );
  }
}

extension WorkCaseUpdateToCompanion on WorkCaseUpdate {
  WorkCaseUpdatesCompanion toCompanion() {
    return WorkCaseUpdatesCompanion(
      schemaVersion: Value(schemaVersion),
      id: Value(id),
      workCaseId: Value(workCaseId),
      occurredAt: Value(occurredAt),
      description: Value(description),
      contactOrVendor: Value(contactOrVendor),
      result: Value(result),
      cost: Value(cost),
      partsOrItems: Value(partsOrItems),
      photoIdentifiers: Value(photoIdentifiers),
      waitingReason: Value(waitingReason),
      note: Value(note),
      nextAction: Value(nextAction),
      createdAt: Value(createdAt),
    );
  }
}

extension WorkCaseUpdateRowToModel on WorkCaseUpdateRow {
  WorkCaseUpdate toModel() {
    return WorkCaseUpdate(
      schemaVersion: schemaVersion,
      id: id,
      workCaseId: workCaseId,
      occurredAt: occurredAt,
      description: description,
      contactOrVendor: contactOrVendor,
      result: result,
      cost: cost,
      partsOrItems: partsOrItems,
      photoIdentifiers: photoIdentifiers,
      waitingReason: waitingReason,
      note: note,
      nextAction: nextAction,
      createdAt: createdAt,
    );
  }
}
