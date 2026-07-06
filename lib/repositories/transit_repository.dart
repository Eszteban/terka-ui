import '../models/trip_stop_quick_info.dart';

abstract class TransitRepository {
  Future<Map<String, dynamic>?> fetchTripDetails({
    required String tripId,
    required String serviceDay,
  });

  Future<TripStopQuickInfo?> fetchStopQuickInfo({
    required String stopId,
    required String fallbackName,
    Duration timeout = const Duration(seconds: 10),
  });

  Future<List<Map<String, dynamic>>?> fetchStopDetails({
    required List<String> stopIds,
    required DateTime selectedDate,
  });

  Future<Map<String, dynamic>?> fetchRoutePlans({
    required String fromPlace,
    required String toPlace,
    required DateTime dateTime,
    String? nextPageCursor,
  });
}
