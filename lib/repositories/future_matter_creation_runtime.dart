import '../models/future_matter.dart';

class FutureMatterCreationRequest {
  const FutureMatterCreationRequest({
    required this.id,
    required this.eventId,
    required this.title,
    required this.timingMode,
    required this.createdAt,
    this.itemId,
    this.specifiedDate,
    this.specifiedMinuteOfDay,
    this.recurringIntervalValue,
    this.recurringIntervalUnit,
    this.recurringAnchorDate,
    this.recurringAnchorMinuteOfDay,
    this.conditionType,
    this.conditionMaintenanceRecordId,
    this.conditionDelayValue,
    this.conditionDelayUnit,
  });

  final String id;
  final String eventId;
  final String title;
  final String? itemId;
  final FutureMatterTimingMode timingMode;
  final FutureMatterDate? specifiedDate;
  final int? specifiedMinuteOfDay;
  final int? recurringIntervalValue;
  final FutureMatterIntervalUnit? recurringIntervalUnit;
  final FutureMatterDate? recurringAnchorDate;
  final int? recurringAnchorMinuteOfDay;
  final FutureMatterConditionType? conditionType;
  final String? conditionMaintenanceRecordId;
  final int? conditionDelayValue;
  final FutureMatterIntervalUnit? conditionDelayUnit;
  final DateTime createdAt;
}

class FutureMatterCreationResult {
  const FutureMatterCreationResult({
    required this.futureMatter,
    required this.createdEvent,
  });

  final FutureMatter futureMatter;
  final FutureMatterCreatedEvent createdEvent;
}

abstract interface class FutureMatterCreationRuntime {
  Future<FutureMatterCreationResult> create(
    FutureMatterCreationRequest request,
  );
  Future<FutureMatter?> findById(String id);
  Future<FutureMatterCreatedEvent?> findCreatedEvent(String futureMatterId);
}
