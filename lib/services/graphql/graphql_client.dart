import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../constants/search_api.dart';

class GraphqlResponse {
  final int statusCode;
  final String rawBody;
  final Map<String, dynamic>? json;

  const GraphqlResponse({
    required this.statusCode,
    required this.rawBody,
    required this.json,
  });

  bool get isSuccess => statusCode == 200;
}

class GraphqlClient {
  const GraphqlClient();

  Future<GraphqlResponse> execute({
    required String query,
    Map<String, dynamic>? variables,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    final payload = <String, dynamic>{'query': query};
    if (variables != null) {
      payload['variables'] = variables;
    }

    final response = await http
        .post(
          Uri.parse(planApiUrl),
          headers: apiRequestHeaders,
          body: jsonEncode(payload),
        )
        .timeout(timeout);

    Map<String, dynamic>? decoded;
    try {
      final dynamic parsed = jsonDecode(response.body);
      if (parsed is Map) {
        decoded = parsed.cast<String, dynamic>();
      }
    } catch (_) {
      decoded = null;
    }

    return GraphqlResponse(
      statusCode: response.statusCode,
      rawBody: response.body,
      json: decoded,
    );
  }
}
