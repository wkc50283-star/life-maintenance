import '../models/future_matter.dart';

class FutureMatterChangeRequest {
  const FutureMatterChangeRequest({
    required this.futureMatterId,
    required this.eventId,
    required this.timingMode,
    required this.occurredAt,
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

  final String futureMatterId;
  final String eventId;
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
  final DateTime occurredAt;
}

abstract interface class FutureMatterChangeRuntime {
  Future<FutureMatter?> readCurrent(String futureMatterId);

  Future<FutureMatterChangeEvent?> replace(FutureMatterChangeRequest request);

  Future<List<FutureMatterChangeEvent>> listChanges(String futureMatterId);
}
