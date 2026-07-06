import '../models/trip_stop_quick_info.dart';
import '../services/transit_api_service.dart';
import '../services/graphql/graphql_queries.dart';
import '../utils/trip_details_utils.dart';
import '../utils/stop_details_utils.dart';
import 'transit_repository.dart';

class HttpTransitRepository implements TransitRepository {
  final TransitApiService _apiService;

  const HttpTransitRepository({
    required TransitApiService apiService,
  }) : _apiService = apiService;

  @override
  Future<Map<String, dynamic>?> fetchTripDetails({
    required String tripId,
    required String serviceDay,
  }) async {
    final rawData = await _apiService.fetchTripDetails(
      tripId: tripId,
      serviceDay: serviceDay,
    );
    if (rawData == null) return null;
    final tripNode = rawData['trip'];
    return tripNode is Map ? tripNode.cast<String, dynamic>() : null;
  }

  @override
  Future<TripStopQuickInfo?> fetchStopQuickInfo({
    required String stopId,
    required String fallbackName,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final rawData = await _apiService.fetchStopQuickInfo(
      stopId: stopId,
      timeout: timeout,
    );
    if (rawData == null || rawData['stop'] is! Map) {
      return null;
    }

    final stop = rawData['stop'] as Map;
    final routes = stop['routes'];
    final routeMap = <String, TripStopQuickRoute>{};
    if (routes is List) {
      for (final route in routes) {
        if (route is Map && route['gtfsId'] != null) {
          final id = route['gtfsId'].toString().trim();
          if (id.isEmpty) {
            continue;
          }
          var rawLabel = route['shortName']?.toString() ?? '';
          if (rawLabel.trim().isEmpty) {
            rawLabel = route['longName']?.toString() ?? '';
          }
          if (rawLabel.trim().isEmpty) {
            rawLabel = '-';
          }
          final label = TripDetailsUtils.plainText(rawLabel);
          if (routeMap.containsKey(label)) {
            continue;
          }
          routeMap[label] = TripStopQuickRoute(
            id: id,
            label: label,
            usesSpanFont: TripDetailsUtils.containsSpanMarkup(rawLabel),
            backgroundColor: TripDetailsUtils.hexColor(
              route['color']?.toString() ?? '0A84FF',
            ),
            textColor: TripDetailsUtils.hexColor(route['textColor']?.toString() ?? 'FFFFFF'),
          );
        }
      }
    }
    final lines = routeMap.values.toList()
      ..sort((a, b) => a.label.compareTo(b.label));

    final stopName = TripDetailsUtils.plainText(
      stop['name']?.toString().trim().isNotEmpty == true
          ? stop['name'].toString()
          : fallbackName,
    );

    return TripStopQuickInfo(
      stopId: stopId,
      stopName: stopName,
      lines: lines,
    );
  }

  @override
Future<List<Map<String, dynamic>>?> fetchStopDetails({
  required List<String> stopIds,
  required DateTime selectedDate,
}) async {
  // 1. Adat-előkészítés (Átköltözött a szervizből!)
  final budapestMidnight = StopDetailsUtils.budapestMidnightUtc(
    selectedDate.year, selectedDate.month, selectedDate.day,
  );
  final startEpoch = budapestMidnight.millisecondsSinceEpoch ~/ 1000 - const Duration(hours: 3).inSeconds;
  final expandedIds = StopDetailsUtils.expandStopIdVariants(stopIds);
  final query = buildStopDetailsQuery(expandedIds);
  
  final variables = {
    'startTime': startEpoch,
    'number': 2147483647,
    'timeRange': const Duration(hours: 27).inSeconds,
  };

  // 2. Nyers hívás a szerviz felé
  final data = await _apiService.fetchStopDetailsRaw(query: query, variables: variables);
  if (data == null) return null;

  // 3. Válasz kicsomagolása (Átköltözött a szervizből!)
  final stops = <Map<String, dynamic>>[];
  for (var i = 0; i < expandedIds.length; i++) {
    final item = data['stop$i'];
    if (item is Map) {
      stops.add(item.cast<String, dynamic>());
    }
  }
  return stops;
}

  @override
  Future<Map<String, dynamic>?> fetchRoutePlans({
    required String fromPlace,
    required String toPlace,
    required DateTime dateTime,
    String? nextPageCursor,
  }) {
    final dateString =
        '${dateTime.year.toString().padLeft(4, '0')}-${dateTime.month.toString().padLeft(2, '0')}-${dateTime.day.toString().padLeft(2, '0')}';
    final timeString =
        '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';

    final variables = <String, dynamic>{
      'arriveBy': false,
      'banned': <String, dynamic>{},
      'bikeReluctance': 1.0,
      'carReluctance': 1.0,
      'date': dateString,
      'fromPlace': fromPlace,
      'modes': const [
        {'mode': 'RAIL'},
        {'mode': 'RAIL_REPLACEMENT_BUS'},
        {'mode': 'SUBURBAN_RAILWAY'},
        {'mode': 'TRAMTRAIN'},
        {'mode': 'SUBWAY'},
        {'mode': 'TRAM'},
        {'mode': 'TROLLEYBUS'},
        {'mode': 'BUS'},
        {'mode': 'FERRY'},
        {'mode': 'COACH'},
      ],
      'numItineraries': 15,
      'preferred': <String, dynamic>{},
      'time': timeString,
      'toPlace': toPlace,
      'unpreferred': <String, dynamic>{},
      'walkReluctance': 1.0,
      'walkSpeed': 1.3888888888888888,
      'wheelchair': false,
      'minTransferTime': 0,
      'transitPassFilter': <String>[],
      'comfortLevels': <String>[],
      'searchParameters': <String>[],
      'distributionChannel': 'ERTEKESITESI_CSATORNA#INTERNET',
      'distributionSubChannel': 'ERTEKESITESI_ALCSATORNA#EMMA',
      'pageCursor': nextPageCursor ?? '',
    };

    return _apiService.fetchRoutePlans(
      query: planQuery,
      variables: variables,
    );
  }
}
