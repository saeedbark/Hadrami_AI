import 'dart:convert';

import 'package:hadrami_nlp/src/core/network/api_config.dart';
import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'api_service.g.dart';

// Every other provider in the codebase is @riverpod-generated; this was the
// one hand-written exception (see docs/... Riverpod guide, section on
// consistency vs. boilerplate reduction). Converting it keeps the codegen
// convention uniform across services/.
@Riverpod(keepAlive: true)
ApiService apiService(ApiServiceRef ref) => ApiService();

class ApiService {
  final _client = http.Client();

  Uri _buildUri(String path, [Map<String, String>? queryParameters]) {
    final base = Uri.parse(ApiConfig.baseUrl);

    return Uri(
      scheme: base.scheme,
      host: base.host,
      port: base.hasPort ? base.port : null,
      path: path,
      queryParameters: queryParameters,
    );
  }

  Future<dynamic> getJson(
    String path, {
    Map<String, String>? queryParameters,
    Duration timeout = ApiConfig.defaultTimeout,
  }) async {
    final response = await _client
        .get(
          _buildUri(path, queryParameters),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> postJson(
    String path,
    Map<String, dynamic> body, {
    Duration timeout = ApiConfig.defaultTimeout,
  }) async {
    final response = await _client
        .post(
          _buildUri(path),
          headers: const {'Content-Type': 'application/json'},
          body: json.encode(body),
        )
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return json.decode(utf8.decode(response.bodyBytes));
  }
}
