import '../models/migration_admission_report.dart';
import 'legacy_relation_audit_service.dart';
import 'migration_readiness_service.dart';

class MigrationAdmissionService {
  const MigrationAdmissionService({
    required MigrationReadinessService readinessService,
    required LegacyRelationAuditService relationAuditService,
  }) : _readinessService = readinessService,
       _relationAuditService = relationAuditService;

  final MigrationReadinessService _readinessService;
  final LegacyRelationAuditService _relationAuditService;

  Future<MigrationAdmissionReport> inspect() async {
    final readinessReport = await _readinessService.inspect();
    final relationAuditReport = await _relationAuditService.inspect();
    final blockers = <MigrationAdmissionBlocker>{};

    if (!readinessReport.allSourceDataReadable) {
      blockers.add(MigrationAdmissionBlocker.unreadableSourceData);
    }
    if (!readinessReport.allExistingSourcesBackedUp) {
      blockers.add(MigrationAdmissionBlocker.incompleteOrMismatchedBackup);
    }
    if (relationAuditReport.datasets.values.any(
      (dataset) => dataset.invalidEntryCount > 0,
    )) {
      blockers.add(MigrationAdmissionBlocker.invalidLegacyEntries);
    }
    if (relationAuditReport.datasets.values.any(
      (dataset) => dataset.duplicateIds.isNotEmpty,
    )) {
      blockers.add(MigrationAdmissionBlocker.duplicateLegacyIds);
    }
    if (!relationAuditReport.allRelationsValid) {
      blockers.add(MigrationAdmissionBlocker.danglingLegacyRelations);
    }
    if (!readinessReport.driftIsEmpty) {
      blockers.add(MigrationAdmissionBlocker.nonEmptyDriftTarget);
    }

    return MigrationAdmissionReport(
      readinessReport: readinessReport,
      relationAuditReport: relationAuditReport,
      blockers: blockers,
    );
  }
}
