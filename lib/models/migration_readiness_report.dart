class MigrationDatasetSnapshot {
  const MigrationDatasetSnapshot({
    required this.sourceKey,
    required this.backupKey,
    required this.sourceExists,
    required this.backupExists,
    required this.sourceIsValidList,
    required this.backupIsValidList,
    required this.sourceCount,
    required this.backupCount,
    required this.rawValuesMatch,
  });

  final String sourceKey;
  final String backupKey;
  final bool sourceExists;
  final bool backupExists;
  final bool sourceIsValidList;
  final bool backupIsValidList;
  final int? sourceCount;
  final int? backupCount;
  final bool? rawValuesMatch;

  bool get isReady =>
      sourceExists &&
      backupExists &&
      sourceIsValidList &&
      backupIsValidList &&
      rawValuesMatch == true;
}

class MigrationReadinessReport {
  const MigrationReadinessReport({
    required this.datasets,
    required this.driftWorkCaseCount,
    required this.driftWorkCaseUpdateCount,
  });

  final List<MigrationDatasetSnapshot> datasets;
  final int driftWorkCaseCount;
  final int driftWorkCaseUpdateCount;

  bool get allSourceDataReadable =>
      datasets.every((dataset) => !dataset.sourceExists || dataset.sourceIsValidList);

  bool get allExistingSourcesBackedUp => datasets.every(
    (dataset) =>
        !dataset.sourceExists ||
        (dataset.backupExists && dataset.rawValuesMatch == true),
  );

  bool get driftIsEmpty =>
      driftWorkCaseCount == 0 && driftWorkCaseUpdateCount == 0;
}
