import '../models/future_matter.dart';

class FutureMatterAmendmentRequest {
  FutureMatterAmendmentRequest({
    required this.id,
    required this.futureMatterId,
    required this.target,
    required this.recordedAt,
    required this.eventSource,
    required List<FutureMatterFieldChange> changes,
    this.occurredAt,
    this.sourceReferenceKind,
    this.sourceReferenceId,
  }) : changes = List.unmodifiable(changes);

  final String id;
  final String futureMatterId;
  final FutureMatterEventReference target;
  final DateTime? occurredAt;
  final DateTime recordedAt;
  final FutureMatterSource eventSource;
  final FutureMatterSourceReferenceKind? sourceReferenceKind;
  final String? sourceReferenceId;
  final List<FutureMatterFieldChange> changes;
}

abstract interface class FutureMatterAmendmentRuntime {
  Future<FutureMatterAmendmentEvent> createSupplement(
    FutureMatterAmendmentRequest request,
  );
  Future<FutureMatterAmendmentEvent> createCorrection(
    FutureMatterAmendmentRequest request,
  );
  Future<List<FutureMatterAmendmentEvent>> listAmendments(
    String futureMatterId,
  );
  Future<FutureMatterEffectiveFacts> foldEffectiveResult(
    FutureMatterEventReference target,
  );
}
