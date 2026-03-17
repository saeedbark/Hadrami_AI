import 'package:flutter/foundation.dart';
import '../models/word_entry.dart';
import '../services/api_service.dart';

enum AppStatus { idle, loading, success, error }

class AppProvider extends ChangeNotifier {
  // ── State ───────────────────────────────────────────────────────────────
  AppStatus _status = AppStatus.idle;
  String _searchQuery = '';
  List<WordEntry> _searchResults = [];
  int _searchTotal = 0;
  TranslateResult? _translateResult;
  List<WordEntry> _wordList = [];
  int _wordListTotal = 0;
  int _currentPage = 1;
  AppStats? _stats;
  WordEntry? _randomWord;
  String? _errorMessage;
  List<WordEntry> _favorites = [];
  List<WordEntry> _history = [];

  // ── Getters ─────────────────────────────────────────────────────────────
  AppStatus get status => _status;
  String get searchQuery => _searchQuery;
  List<WordEntry> get searchResults => _searchResults;
  int get searchTotal => _searchTotal;
  TranslateResult? get translateResult => _translateResult;
  List<WordEntry> get wordList => _wordList;
  int get wordListTotal => _wordListTotal;
  int get currentPage => _currentPage;
  AppStats? get stats => _stats;
  WordEntry? get randomWord => _randomWord;
  String? get errorMessage => _errorMessage;
  List<WordEntry> get favorites => _favorites;
  List<WordEntry> get history => _history;
  bool get isLoading => _status == AppStatus.loading;

  // ── Translate ────────────────────────────────────────────────────────────
  Future<void> translate(String query) async {
    if (query.trim().isEmpty) return;
    _status = AppStatus.loading;
    _searchQuery = query;
    _translateResult = null;
    notifyListeners();

    final result = await ApiService.translate(query);
    _translateResult = result;
    _status = result.confidence == 'error' ? AppStatus.error : AppStatus.success;

    // Add to history
    if (result.found) {
      final entry = WordEntry(
        id: 0,
        hadramiWord: result.hadramiWord,
        arabicFus7a: result.arabicFus7a,
        fullDefinition: result.fullDefinition,
      );
      _addToHistory(entry);
    }
    notifyListeners();
  }

  // ── Search ───────────────────────────────────────────────────────────────
  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      _searchTotal = 0;
      notifyListeners();
      return;
    }
    _status = AppStatus.loading;
    _searchQuery = query;
    notifyListeners();

    final result = await ApiService.search(query);
    _searchResults = result.results;
    _searchTotal = result.total;
    _status = AppStatus.success;
    notifyListeners();
  }

  // ── Load word list ───────────────────────────────────────────────────────
  Future<void> loadWords({int page = 1, String? letter}) async {
    _status = AppStatus.loading;
    _currentPage = page;
    notifyListeners();

    final result = await ApiService.listWords(page: page, size: 30, letter: letter);
    if (page == 1) {
      _wordList = result.results;
    } else {
      _wordList.addAll(result.results);
    }
    _wordListTotal = result.total;
    _status = AppStatus.success;
    notifyListeners();
  }

  // ── Load more ────────────────────────────────────────────────────────────
  Future<void> loadMore() async {
    if (_wordList.length >= _wordListTotal) return;
    await loadWords(page: _currentPage + 1);
  }

  // ── Load stats ───────────────────────────────────────────────────────────
  Future<void> loadStats() async {
    final data = await ApiService.getStats();
    if (data.isNotEmpty) {
      _stats = AppStats.fromJson(data);
      notifyListeners();
    }
  }

  // ── Random word ──────────────────────────────────────────────────────────
  Future<void> loadRandomWord() async {
    _randomWord = await ApiService.randomWord();
    notifyListeners();
  }

  // ── Favorites ────────────────────────────────────────────────────────────
  void toggleFavorite(WordEntry entry) {
    final idx = _favorites.indexWhere((e) => e.hadramiWord == entry.hadramiWord);
    if (idx >= 0) {
      _favorites.removeAt(idx);
    } else {
      _favorites.insert(0, entry);
    }
    notifyListeners();
  }

  bool isFavorite(WordEntry entry) =>
      _favorites.any((e) => e.hadramiWord == entry.hadramiWord);

  // ── History ──────────────────────────────────────────────────────────────
  void _addToHistory(WordEntry entry) {
    _history.removeWhere((e) => e.hadramiWord == entry.hadramiWord);
    _history.insert(0, entry);
    if (_history.length > 50) _history = _history.take(50).toList();
  }

  void clearHistory() {
    _history.clear();
    notifyListeners();
  }

  // ── Submit feedback ──────────────────────────────────────────────────────
  Future<bool> submitFeedback({
    required int wordId,
    required String hadramiWord,
    required String suggestedFus7a,
    String? comment,
  }) async {
    return ApiService.submitFeedback(
      wordId: wordId,
      hadramiWord: hadramiWord,
      suggestedFus7a: suggestedFus7a,
      comment: comment,
    );
  }

  void clearSearch() {
    _searchQuery = '';
    _searchResults = [];
    _searchTotal = 0;
    _translateResult = null;
    _status = AppStatus.idle;
    notifyListeners();
  }
}
