enum LegacyDriftImportStatus { ready, blocked, imported, alreadyImported }

class LegacyDriftImportIssue {
  const LegacyDriftImportIssue({
    required this.code,
    required this.message,
    this.storageKey,
    this.entryId,
  });

  final String code;
  final String message;
  final String? storageKey;
  final String? entryId;
}

class LegacyDriftImportReport {
  const LegacyDriftImportReport({
    required this.status,
    required this.sourceDigests,
    required this.sourceByteLengths,
    required this.sourceCounts,
    required this.validSourceCounts,
    required this.targetCounts,
    this.issues = const <LegacyDriftImportIssue>[],
  });

  final LegacyDriftImportStatus status;
  final Map<String, String> sourceDigests;
  final Map<String, int> sourceByteLengths;
  final Map<String, int> sourceCounts;
  final Map<String, int> validSourceCounts;
  final Map<String, int> targetCounts;
  final List<LegacyDriftImportIssue> issues;

  bool get isBlocked => status == LegacyDriftImportStatus.blocked;
  bool get canImport => status == LegacyDriftImportStatus.ready;
  bool get didWrite => status == LegacyDriftImportStatus.imported;
}

class LegacyDriftImportException implements Exception {
  const LegacyDriftImportException(this.report);

  final LegacyDriftImportReport report;

  @override
  String toString() =>
      'LegacyDriftImportException(${report.issues.map((issue) => issue.code).join(', ')})';
}
