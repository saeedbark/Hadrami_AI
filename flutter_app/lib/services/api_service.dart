import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/word_entry.dart';

class ApiService {
  // Change this to your computer's IP when testing on real device
  // For emulator: use 10.0.2.2
  // For real device: use your computer's IP e.g. 192.168.1.100
static const String baseUrl = 'http://localhost:8000';
  static final _client = http.Client();

  // ── Translate a single word ─────────────────────────────────────────────
  static Future<TranslateResult> translate(String query) async {
    try {
      final uri = Uri.parse('$baseUrl/translate?q=${Uri.encodeComponent(query)}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return TranslateResult.fromJson(data);
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return TranslateResult(
        found: false,
        hadramiWord: query,
        arabicFus7a: '',
        fullDefinition: 'تعذّر الاتصال بالخادم. تأكد من تشغيل الـ backend.',
        confidence: 'error',
      );
    }
  }

  // ── Search words ────────────────────────────────────────────────────────
  static Future<SearchResult> search(String query, {int limit = 20}) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/search?q=${Uri.encodeComponent(query)}&limit=$limit');
      final response = await _client.get(uri).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SearchResult.fromJson(data);
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return SearchResult(total: 0, results: []);
    }
  }

  // ── List words with pagination ──────────────────────────────────────────
  static Future<SearchResult> listWords({
    int page = 1,
    int size = 20,
    String? letter,
  }) async {
    try {
      String url = '$baseUrl/words?page=$page&size=$size';
      if (letter != null) url += '&letter=${Uri.encodeComponent(letter)}';
      
      final response = await _client
          .get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return SearchResult.fromJson(data);
      }
      throw Exception('Server error: ${response.statusCode}');
    } catch (e) {
      return SearchResult(total: 0, results: []);
    }
  }

  // ── Get stats ───────────────────────────────────────────────────────────
  static Future<Map<String, dynamic>> getStats() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/stats'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        return json.decode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {}
    return {};
  }

  // ── Random word ─────────────────────────────────────────────────────────
  static Future<WordEntry?> randomWord() async {
    try {
      final response = await _client
          .get(Uri.parse('$baseUrl/random'))
          .timeout(const Duration(seconds: 5));
      
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return WordEntry.fromJson(data);
      }
    } catch (_) {}
    return null;
  }

  // ── Ask (RAG Q&A) ────────────────────────────────────────────────────────
  static Future<AskResult?> ask(String question) async {
    try {
      final uri = Uri.parse(
          '$baseUrl/ask?q=${Uri.encodeComponent(question)}');
      final response = await _client.get(uri).timeout(const Duration(seconds: 30));
      if (response.statusCode == 200) {
        final data = json.decode(utf8.decode(response.bodyBytes));
        return AskResult.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  // ── Submit feedback ─────────────────────────────────────────────────────
  static Future<bool> submitFeedback({
    required int wordId,
    required String hadramiWord,
    required String suggestedFus7a,
    String? comment,
  }) async {
    try {
      final response = await _client
          .post(
            Uri.parse('$baseUrl/feedback'),
            headers: {'Content-Type': 'application/json'},
            body: json.encode({
              'word_id': wordId,
              'hadrami_word': hadramiWord,
              'suggested_fus7a': suggestedFus7a,
              'comment': comment,
            }),
          )
          .timeout(const Duration(seconds: 5));
      
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
