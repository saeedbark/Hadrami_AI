import 'dart:async';
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:hadrami_nlp/src/configs/api_config.dart';
import 'package:hadrami_nlp/src/core/models/lexicon_section.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';

final apiServiceProvider = Provider<ApiService>((_) => ApiService());

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

  Future<dynamic> _getJson(
    String path, {
    Map<String, String>? queryParameters,
    Duration timeout = ApiConfig.defaultTimeout,
  }) async {
    final response = await _client
        .get(_buildUri(path, queryParameters))
        .timeout(timeout);
    if (response.statusCode != 200) {
      throw Exception('Server error: ${response.statusCode}');
    }
    return json.decode(utf8.decode(response.bodyBytes));
  }

  Future<dynamic> _postJsonRaw(
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

  Future<bool> _postJson(
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
    return response.statusCode == 200;
  }

  Future<SearchResult> search(
    String query, {
    int limit = 20,
    String? pos,
    String? region,
    String? tag,
  }) async {
    try {
      final data = await _getJson(
        '/search',
        queryParameters: {
          'q': query,
          'limit': '$limit',
          if (pos != null) 'pos': pos,
          if (region != null) 'region': region,
          if (tag != null) 'tag': tag,
        },
      );
      return SearchResult.fromJson(data);
    } catch (_) {
      return const SearchResult(total: 0, results: []);
    }
  }

  Future<SearchResult> listWords({
    int page = 1,
    int size = ApiConfig.defaultPageSize,
    String? letter,
    String? pos,
    String? region,
    String? tag,
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (letter != null) 'letter': letter,
        if (pos != null) 'pos': pos,
        if (region != null) 'region': region,
        if (tag != null) 'tag': tag,
      };
      final data = await _getJson('/words', queryParameters: params);
      return SearchResult.fromJson(data);
    } catch (_) {
      return const SearchResult(total: 0, results: []);
    }
  }

  Future<Map<String, dynamic>> getStats() async {
    try {
      final data = await _getJson(
        '/stats',
        timeout: const Duration(seconds: 5),
      );
      return Map<String, dynamic>.from(data);
    } catch (_) {
      return {};
    }
  }

  Future<List<LexiconSection>> getSections() async {
    try {
      final data = await _getJson(
        '/sections',
        timeout: const Duration(seconds: 5),
      ) as Map<String, dynamic>;
      final raw = data['sections'];
      if (raw is! List) return [];
      return raw
          .whereType<Map<String, dynamic>>()
          .map(LexiconSection.fromJson)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<WordEntry?> randomWord() async {
    try {
      final data = await _getJson(
        '/random',
        timeout: const Duration(seconds: 5),
      );
      return WordEntry.fromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<ChatResult> sendChatMessage({
    required String message,
    required List<Map<String, String>> history,
  }) async {
    try {
      final body = {
        'message': message,
        'history': history,
      };
      final data = await _postJsonRaw('/chat', body, timeout: ApiConfig.longTimeout);
      return ChatResult.fromJson(data);
    } on TimeoutException {
      return const ChatResult(
        reply: 'انتهت مهلة الانتظار. جرّب مرة أخرى.',
      );
    } catch (_) {
      return const ChatResult(
        reply:
            'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend على ${ApiConfig.baseUrl}',
      );
    }
  }

  Future<bool> submitFeedback({
    required String wordVocalized,
    String suggestedFusha = '',
    int wordId = 0,
    String? comment,
    String feedbackType = 'correction',
    List<String>? spellingVariants,
    String? sentencePairHadrami,
    String? sentencePairFusha,
    bool consent = false,
  }) async {
    try {
      final body = <String, dynamic>{
        'word_id': wordId,
        'word_vocalized': wordVocalized,
        'suggested_fusha': suggestedFusha,
        'comment': comment,
        'feedback_type': feedbackType,
        'consent': consent,
      };
      if (spellingVariants != null) body['spelling_variants'] = spellingVariants;
      if (sentencePairHadrami != null) {
        body['sentence_pair_hadrami'] = sentencePairHadrami;
      }
      if (sentencePairFusha != null) {
        body['sentence_pair_fusha'] = sentencePairFusha;
      }
      return await _postJson(
        '/feedback',
        body,
        timeout: const Duration(seconds: 5),
      );
    } catch (_) {
      return false;
    }
  }
}
