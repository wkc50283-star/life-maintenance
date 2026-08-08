import '../models/future_matter.dart';

class FutureMatterCompletionRequest {
  const FutureMatterCompletionRequest({
    required this.futureMatterId,
    required this.eventId,
    required this.completedDate,
    required this.confirmedAt,
    this.completedMinuteOfDay,
  });

  final String futureMatterId;
  final String eventId;
  final FutureMatterDate completedDate;
  final int? completedMinuteOfDay;
  final DateTime confirmedAt;
}

abstract interface class FutureMatterCompletionRuntime {
  Future<FutureMatter?> readCurrent(String futureMatterId);
  Future<FutureMatterCompletedEvent> complete(
    FutureMatterCompletionRequest request,
  );
  Future<FutureMatterCompletedEvent?> findCompletedEvent(String futureMatterId);
}
