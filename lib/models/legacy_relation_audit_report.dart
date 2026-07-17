class LegacyDatasetAudit {
  const LegacyDatasetAudit({
    required this.storageKey,
    required this.rawEntryCount,
    required this.validEntryCount,
    required this.invalidEntryCount,
    required this.duplicateIds,
  });

  final String storageKey;
  final int rawEntryCount;
  final int validEntryCount;
  final int invalidEntryCount;
  final Set<String> duplicateIds;

  bool get isStructurallyValid =>
      invalidEntryCount == 0 && duplicateIds.isEmpty;
}

class LegacyRelationIssue {
  const LegacyRelationIssue({
    required this.datasetKey,
    required this.entryId,
    required this.fieldName,
    required this.missingReferenceId,
  });

  final String datasetKey;
  final String entryId;
  final String fieldName;
  final String missingReferenceId;
}

class LegacyRelationAuditReport {
  LegacyRelationAuditReport({
    required Map<String, LegacyDatasetAudit> datasets,
    required List<LegacyRelationIssue> relationIssues,
  }) : datasets = Map<String, LegacyDatasetAudit>.unmodifiable(datasets),
       relationIssues = List<LegacyRelationIssue>.unmodifiable(relationIssues);

  final Map<String, LegacyDatasetAudit> datasets;
  final List<LegacyRelationIssue> relationIssues;

  bool get allDatasetsStructurallyValid =>
      datasets.values.every((dataset) => dataset.isStructurallyValid);

  bool get allRelationsValid => relationIssues.isEmpty;

  bool get isReadyForMigration =>
      allDatasetsStructurallyValid && allRelationsValid;
}
