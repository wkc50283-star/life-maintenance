import 'legacy_relation_audit_report.dart';
import 'migration_readiness_report.dart';

enum MigrationAdmissionBlocker {
  unreadableSourceData,
  incompleteOrMismatchedBackup,
  invalidLegacyEntries,
  duplicateLegacyIds,
  danglingLegacyRelations,
  nonEmptyDriftTarget,
}

class MigrationAdmissionReport {
  MigrationAdmissionReport({
    required this.readinessReport,
    required this.relationAuditReport,
    required Set<MigrationAdmissionBlocker> blockers,
  }) : blockers = Set<MigrationAdmissionBlocker>.unmodifiable(blockers);

  final MigrationReadinessReport readinessReport;
  final LegacyRelationAuditReport relationAuditReport;
  final Set<MigrationAdmissionBlocker> blockers;

  bool get isAdmittedForDryRun => blockers.isEmpty;

  bool get isBlocked => !isAdmittedForDryRun;
}
