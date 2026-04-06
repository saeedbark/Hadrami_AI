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

  Future<TranslateResult> translate(String query) async {
    try {
      final data = await _getJson(
        '/translate',
        queryParameters: {'q': query},
      );
      return TranslateResult.fromJson(data);
    } catch (_) {
      return TranslateResult(
        found: false,
        hadramiWord: query,
        arabicFus7a: '',
        fullDefinition: 'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend.',
        confidence: 'error',
      );
    }
  }

  Future<SearchResult> search(String query, {int limit = 20}) async {
    try {
      final data = await _getJson(
        '/search',
        queryParameters: {'q': query, 'limit': '$limit'},
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
  }) async {
    try {
      final params = <String, String>{
        'page': '$page',
        'size': '$size',
        if (letter != null) 'letter': letter,
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

  /// Always returns a result; [AskResult.mode] == `error` when the request failed.
  /// Phrase-level MSA ↔ Hadrami translation (RAG + Gemini). [direction] is
  /// `ar_to_hadrami` or `hadrami_to_ar`.
  Future<PhraseTranslateResult> translatePhrase({
    required String text,
    required String direction,
  }) async {
    try {
      final response = await _client
          .post(
            _buildUri('/translate-phrase'),
            headers: const {'Content-Type': 'application/json'},
            body: json.encode({'text': text, 'direction': direction}),
          )
          .timeout(ApiConfig.longTimeout);
      if (response.statusCode != 200) {
        return PhraseTranslateResult(
          inputText: text,
          direction: direction,
          translatedText:
              'خطأ من الخادم (${response.statusCode}). تحقق من النص واتجاه الترجمة.',
          mode: 'error',
        );
      }
      final data =
          json.decode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return PhraseTranslateResult.fromJson(data);
    } on TimeoutException {
      return PhraseTranslateResult(
        inputText: text,
        direction: direction,
        translatedText:
            'انتهت مهلة الانتظار. جرّب مرة أخرى أو تأكد من تشغيل الـ backend.',
        mode: 'error',
      );
    } catch (_) {
      return PhraseTranslateResult(
        inputText: text,
        direction: direction,
        translatedText:
            'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend على ${ApiConfig.baseUrl}',
        mode: 'error',
      );
    }
  }

  Future<AskResult> ask(String question) async {
    try {
      final data = await _getJson(
        '/ask',
        queryParameters: {'q': question},
        timeout: ApiConfig.longTimeout,
      );
      return AskResult.fromJson(data);
    } on TimeoutException {
      return AskResult(
        question: question,
        answer:
            'انتهت مهلة الانتظار. أول طلب للخادم قد يستغرق وقتاً. جرّب مرة أخرى، أو تأكد من تشغيل الـ backend.',
        mode: 'error',
      );
    } catch (_) {
      return AskResult(
        question: question,
        answer:
            'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend على ${ApiConfig.baseUrl}',
        mode: 'error',
      );
    }
  }

  Future<bool> submitFeedback({
    required String hadramiWord,
    String suggestedFus7a = '',
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
        'hadrami_word': hadramiWord,
        'suggested_fus7a': suggestedFus7a,
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
