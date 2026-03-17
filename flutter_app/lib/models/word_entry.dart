// ── WordEntry model ─────────────────────────────────────────────────────────
class WordEntry {
  final int id;
  final String hadramiWord;
  final String arabicFus7a;
  final String fullDefinition;

  const WordEntry({
    required this.id,
    required this.hadramiWord,
    required this.arabicFus7a,
    required this.fullDefinition,
  });

  factory WordEntry.fromJson(Map<String, dynamic> json) => WordEntry(
        id: json['id'] ?? 0,
        hadramiWord: json['hadrami_word'] ?? '',
        arabicFus7a: json['arabic_fus7a'] ?? '',
        fullDefinition: json['full_definition'] ?? '',
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'hadrami_word': hadramiWord,
        'arabic_fus7a': arabicFus7a,
        'full_definition': fullDefinition,
      };
}

// ── TranslateResult model ───────────────────────────────────────────────────
class TranslateResult {
  final bool found;
  final String hadramiWord;
  final String arabicFus7a;
  final String fullDefinition;
  final String confidence; // "exact" | "partial" | "not_found" | "error"

  const TranslateResult({
    required this.found,
    required this.hadramiWord,
    required this.arabicFus7a,
    required this.fullDefinition,
    required this.confidence,
  });

  factory TranslateResult.fromJson(Map<String, dynamic> json) => TranslateResult(
        found: json['found'] ?? false,
        hadramiWord: json['hadrami_word'] ?? '',
        arabicFus7a: json['arabic_fus7a'] ?? '',
        fullDefinition: json['full_definition'] ?? '',
        confidence: json['confidence'] ?? 'not_found',
      );
}

// ── SearchResult model ──────────────────────────────────────────────────────
class SearchResult {
  final int total;
  final List<WordEntry> results;

  const SearchResult({required this.total, required this.results});

  factory SearchResult.fromJson(Map<String, dynamic> json) => SearchResult(
        total: json['total'] ?? 0,
        results: (json['results'] as List? ?? [])
            .map((e) => WordEntry.fromJson(e))
            .toList(),
      );
}

// ── AskResult model (RAG Q&A) ──────────────────────────────────────────────
class AskResult {
  final String question;
  final String answer;
  final String mode; // "simple" | "local_ollama" | "gemini" | "fallback"
  final List<Map<String, dynamic>> context;

  const AskResult({
    required this.question,
    required this.answer,
    required this.mode,
    required this.context,
  });

  factory AskResult.fromJson(Map<String, dynamic> json) => AskResult(
        question: json['question'] ?? '',
        answer: json['answer'] ?? '',
        mode: json['mode'] ?? 'simple',
        context: (json['context'] as List<dynamic>? ?? [])
            .map((e) => Map<String, dynamic>.from(e as Map))
            .toList(),
      );
}

// ── AppStats model ──────────────────────────────────────────────────────────
class AppStats {
  final int totalWords;
  final int translated;
  final int pending;
  final double completionPercent;

  const AppStats({
    required this.totalWords,
    required this.translated,
    required this.pending,
    required this.completionPercent,
  });

  factory AppStats.fromJson(Map<String, dynamic> json) => AppStats(
        totalWords: json['total_words'] ?? 0,
        translated: json['translated'] ?? 0,
        pending: json['pending'] ?? 0,
        completionPercent: (json['completion_percent'] ?? 0.0).toDouble(),
      );
}
