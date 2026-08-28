import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/search_api.dart';
import 'graphql/graphql_client.dart';
import 'graphql/graphql_queries.dart';

class SearchApiService {
  final http.Client _httpClient;
  final GraphqlClient _graphqlClient;

  SearchApiService({
    http.Client? httpClient,
    GraphqlClient graphqlClient = const GraphqlClient(),
  })  : _httpClient = httpClient ?? http.Client(),
        _graphqlClient = graphqlClient;

  /// Fetches raw GeoJSON station features for the given [query].
  Future<Map<String, dynamic>?> fetchStationsRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final baseStationUri = Uri.parse(searchApiUrl);
      final stationUri = baseStationUri.replace(queryParameters: {
        ...baseStationUri.queryParameters,
        'q': query,
        'limit': '10',
        'lang': 'hu',
      });

      final response = await _httpClient
          .get(stationUri, headers: apiRequestHeaders)
          .timeout(timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic body = jsonDecode(response.body);
      return body is Map ? body.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches raw GeoJSON Photon address features for the given [query].
  Future<Map<String, dynamic>?> fetchAddressesRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final basePhotonUri = Uri.parse(photonApiUrl);
      final photonUri = basePhotonUri.replace(queryParameters: {
        ...basePhotonUri.queryParameters,
        'limit': '10',
        'q': query,
        'location_bias_scale': '0.1',
        'osm_tag': '!place:region',
        'zoom': '12',
        'bbox': '16,45.273,23,48.7',
        'lang': 'hu',
      });

      final response = await _httpClient
          .get(photonUri, headers: apiRequestHeaders)
          .timeout(timeout);

      if (response.statusCode != 200) {
        return null;
      }

      final dynamic body = jsonDecode(response.body);
      return body is Map ? body.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }

  /// Fetches raw GraphQL transit route / line data for the given [query].
  Future<Map<String, dynamic>?> fetchLinesRaw(
    String query, {
    Duration timeout = const Duration(seconds: 5),
  }) async {
    try {
      final response = await _graphqlClient.execute(
        query: searchRoutesQuery,
        variables: {'name': query},
      ).timeout(timeout);

      if (!response.isSuccess || response.json == null) {
        return null;
      }

      final data = response.json!['data'];
      return data is Map ? data.cast<String, dynamic>() : null;
    } catch (_) {
      return null;
    }
  }
}
