import 'stop_point.dart';

class TripStopTime {
  final StopPoint stop;
  final int? scheduledArrival;
  final int? realtimeArrival;
  final int? arrivalDelay;
  final int? scheduledDeparture;
  final int? realtimeDeparture;
  final int? departureDelay;
  final bool isRealtime;
  final String? pickupType;
  final String? dropoffType;

  const TripStopTime({
    required this.stop,
    this.scheduledArrival,
    this.realtimeArrival,
    this.arrivalDelay,
    this.scheduledDeparture,
    this.realtimeDeparture,
    this.departureDelay,
    required this.isRealtime,
    this.pickupType,
    this.dropoffType,
  });

  factory TripStopTime.fromJson(Map<String, dynamic> json) {
    final stopJson = json['stop'];
    return TripStopTime(
      stop: stopJson is Map
          ? StopPoint.fromJson(stopJson.cast<String, dynamic>())
          : const StopPoint(id: '', name: '-', platformCode: ''),
      scheduledArrival: (json['scheduledArrival'] as num?)?.toInt(),
      realtimeArrival: (json['realtimeArrival'] as num?)?.toInt(),
      arrivalDelay: (json['arrivalDelay'] as num?)?.toInt(),
      scheduledDeparture: (json['scheduledDeparture'] as num?)?.toInt(),
      realtimeDeparture: (json['realtimeDeparture'] as num?)?.toInt(),
      departureDelay: (json['departureDelay'] as num?)?.toInt(),
      isRealtime: json['realtime'] == true,
      pickupType: json['pickupType']?.toString(),
      dropoffType: json['dropoffType']?.toString(),
    );
  }
}
