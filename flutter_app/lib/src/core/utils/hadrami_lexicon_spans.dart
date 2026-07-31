import 'package:hadrami_nlp/src/core/models/word_entry.dart';

/// Collects highlight-able Hadrami surface forms from a list of dictionary
/// entries (as returned by `/ask`, `/chat`, `/convert-phrase`).
///
/// The production schema exposes:
///   * `word_vocalized`   — canonical headword with diacritics
///   * `word_clean`       — stripped form used for case-insensitive matching
///   * `synonyms`         — dialectal synonyms (list\<String>)
///   * `phonetic_variants`— orthographic/phonetic variants (list\<String>)
///
/// Any shorter-than-2-rune string is dropped to avoid highlighting single
/// letters (ا, و, ف…) that collide with MSA function words.
List<HadramiSpan> hadramiSpansFromLexiconContext(
  String text,
  List<Map<String, dynamic>> context,
) {
  if (text.isEmpty || context.isEmpty) return const [];

  final surfaces = <String>{};
  for (final row in context) {
    void tryAdd(dynamic raw) {
      if (raw is String) {
        final s = raw.trim();
        if (s.isNotEmpty) surfaces.add(s);
      }
    }

    tryAdd(row['word_vocalized']);
    tryAdd(row['word_clean']);
    for (final listKey in const ['synonyms', 'phonetic_variants']) {
      final v = row[listKey];
      if (v is List) {
        for (final item in v) {
          tryAdd(item);
        }
      }
    }
  }

  final sorted = surfaces.toList()
    ..sort((a, b) => b.runes.length.compareTo(a.runes.length));

  final originalRunes = text.runes.toList();
  final normalizedText = _normalizedRunesWithMap(originalRunes);
  final runes = normalizedText.runes;
  final n = runes.length;
  final intervals = <List<int>>[];

  for (final surface in sorted) {
    final needle = _normalizeArabic(surface).runes.toList();
    if (needle.length < 2 || needle.length > n) continue;
    outer:
    for (var i = 0; i <= n - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (runes[i + j] != needle[j]) continue outer;
      }
      final start = normalizedText.runeToOriginalIndex[i];
      final end =
          normalizedText.runeToOriginalIndex[i + needle.length - 1] + 1;
      intervals.add([start, end]);
    }
  }

  if (intervals.isEmpty) return const [];

  intervals.sort((a, b) => a[0].compareTo(b[0]));
  final merged = <List<int>>[List<int>.from(intervals.first)];
  for (var k = 1; k < intervals.length; k++) {
    final cur = intervals[k];
    final last = merged.last;
    if (cur[0] <= last[1]) {
      if (cur[1] > last[1]) last[1] = cur[1];
    } else {
      merged.add(List<int>.from(cur));
    }
  }

  return merged
      .map((iv) {
        final s = iv[0];
        final e = iv[1];
        final slice = String.fromCharCodes(originalRunes.sublist(s, e));
        return HadramiSpan(start: s, end: e, surface: slice);
      })
      .toList(growable: false);
}

String _normalizeArabic(String input) {
  final buffer = StringBuffer();
  for (final rune in input.runes) {
    final ch = String.fromCharCode(rune);
    if (_isCombiningMark(rune) || ch == 'ـ') continue;
    if (ch == 'أ' || ch == 'إ' || ch == 'آ' || ch == 'ٱ') {
      buffer.write('ا');
      continue;
    }
    if (ch == 'ى') {
      buffer.write('ي');
      continue;
    }
    buffer.write(ch);
  }
  return buffer.toString();
}

bool _isCombiningMark(int rune) =>
    (rune >= 0x064B && rune <= 0x065F) || rune == 0x0670;

class _NormalizedRunes {
  const _NormalizedRunes(this.runes, this.runeToOriginalIndex);

  final List<int> runes;
  final List<int> runeToOriginalIndex;
}

_NormalizedRunes _normalizedRunesWithMap(List<int> originalRunes) {
  final normalized = <int>[];
  final mapping = <int>[];
  for (var i = 0; i < originalRunes.length; i++) {
    final normalizedText = _normalizeArabic(String.fromCharCode(originalRunes[i]));
    if (normalizedText.isEmpty) continue;
    for (final rune in normalizedText.runes) {
      normalized.add(rune);
      mapping.add(i);
    }
  }
  return _NormalizedRunes(normalized, mapping);
}
