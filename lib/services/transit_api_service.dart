import 'dart:async';
import '../models/trip_stop_quick_info.dart';
import '../utils/trip_details_utils.dart';
import '../utils/stop_details_utils.dart';
import 'graphql/graphql_client.dart';
import 'graphql/graphql_queries.dart';

class TransitApiService {
  final GraphqlClient _graphqlClient;

  const TransitApiService({GraphqlClient graphqlClient = const GraphqlClient()})
      : _graphqlClient = graphqlClient;

  /// Fetches trip details for [tripId] and [serviceDay].
  Future<Map<String, dynamic>?> fetchTripDetails({
    required String tripId,
    required String serviceDay,
  }) async {
    final response = await _graphqlClient.execute(
      query: tripDetailsQuery,
      variables: {'tripId': tripId, 'serviceDay': serviceDay},
    );
    if (!response.isSuccess || response.json == null) {
      return null;
    }
    final data = response.json!['data'];
    if (data is Map && data['trip'] is Map) {
      return (data['trip'] as Map).cast<String, dynamic>();
    }
    return null;
  }

  /// Fetches quick stop info for [stopId] and parses it into [TripStopQuickInfo].
  Future<TripStopQuickInfo?> fetchStopQuickInfo({
    required String stopId,
    required String fallbackName,
    Duration timeout = const Duration(seconds: 10),
  }) async {
    final response = await _graphqlClient.execute(
      query: stopQuickInfoQuery,
      variables: {'stopId': stopId},
      timeout: timeout,
    );
    if (!response.isSuccess || response.json == null) {
      return null;
    }
    final data = response.json!['data'];
    if (data is! Map || data['stop'] is! Map) {
      return null;
    }
    final stop = data['stop'] as Map;
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

  /// Fetches stop details for multiple stops and maps the GraphQL multi-stop query response back.
  Future<List<Map<String, dynamic>>?> fetchStopDetails({
    required List<String> stopIds,
    required DateTime selectedDate,
  }) async {
    final budapestMidnight = StopDetailsUtils.budapestMidnightUtc(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
    );
    final startEpoch = budapestMidnight.millisecondsSinceEpoch ~/ 1000 -
        const Duration(hours: 3).inSeconds; // _serviceWindowOffsetHours = 3


    final expandedIds = StopDetailsUtils.expandStopIdVariants(stopIds);
    final query = buildStopDetailsQuery(expandedIds);
    final variables = {
      'startTime': startEpoch,
      'number': 2147483647,
      'timeRange': const Duration(hours: 27).inSeconds, // _serviceWindowRangeHours = 27
    };

    final response = await _graphqlClient.execute(
      query: query,
      variables: variables,
    );
    if (!response.isSuccess || response.json == null) {
      return null;
    }
    final data = response.json!['data'];
    if (data is! Map) {
      return null;
    }
    final stops = <Map<String, dynamic>>[];
    for (var i = 0; i < expandedIds.length; i++) {
      final item = data['stop$i'];
      if (item is Map) {
        stops.add(item.cast<String, dynamic>());
      }
    }
    return stops;
  }

  /// Paginated search to load more plan responses.
  Future<Map<String, dynamic>?> loadMorePlans({
    required String query,
    required Map<String, dynamic> variables,
    required String? nextPageCursor,
  }) async {
    final vars = Map<String, dynamic>.from(variables);
    vars['pageCursor'] = nextPageCursor;

    final response = await _graphqlClient.execute(
      query: query,
      variables: vars,
    );
    if (!response.isSuccess) {
      return null;
    }
    return response.json;
  }
}
