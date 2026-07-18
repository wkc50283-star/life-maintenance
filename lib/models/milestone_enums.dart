enum MilestoneKind {
  majorService,
  deepInspection,
  replacementEvaluation,
  renewal,
  careTransition,
  custom,
}

enum MilestoneTriggerType {
  usageYears,
  mileage,
  usageValue,
  completionCount,
  specificDate,
  dependencyCompleted,
  lifeStage,
  anomalyCount,
  manual,
  unknown,
}

enum MilestoneStatus {
  pending,
  reached,
  acknowledged,
  inProgress,
  completed,
  canceled,
  archived,
}
