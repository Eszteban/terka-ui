import 'dart:async';
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
    return data is Map ? data.cast<String, dynamic>() : null;
  }

  /// Fetches route details for [routeId].
  Future<Map<String, dynamic>?> fetchRouteDetails({
    required String routeId,
  }) async {
    final response = await _graphqlClient.execute(
      query: routeDetailsQuery,
      variables: {'id': routeId},
    );
    if (!response.isSuccess || response.json == null) {
      return null;
    }
    final data = response.json!['data'];
    return data is Map ? data.cast<String, dynamic>() : null;
  }

  /// Fetches quick stop info for [stopId].
  Future<Map<String, dynamic>?> fetchStopQuickInfo({
    required String stopId,
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
    return data is Map ? data.cast<String, dynamic>() : null;
  }

  /// Fetches stop details for multiple stops and maps the GraphQL multi-stop query response back.
  Future<Map<String, dynamic>?> fetchStopDetailsRaw({
  required String query,
  required Map<String, dynamic> variables,
}) async {
  final response = await _graphqlClient.execute(
    query: query,
    variables: variables,
  );
  return (response.isSuccess && response.json != null) ? response.json!['data'] : null;
}

  /// Paginated search to load more plan responses.
  Future<Map<String, dynamic>?> fetchRoutePlans({
    required String query,
    required Map<String, dynamic> variables,
  }) async {
    final response = await _graphqlClient.execute(
      query: query,
      variables: variables,
    );
    if (!response.isSuccess) {
      return null;
    }
    return response.json;
  }
}
