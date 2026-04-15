import 'package:hadrami_nlp/src/core/models/word_entry.dart';

/// Finds occurrences of lexicon Hadrami surfaces from [context] inside [text].
/// Indices are Unicode code units consistent with [HadramiHighlightedText] (rune-based).
List<HadramiSpan> hadramiSpansFromLexiconContext(
  String text,
  List<Map<String, dynamic>> context,
) {
  if (text.isEmpty || context.isEmpty) return const [];

  final surfaces = <String>{};
  for (final row in context) {
    final w = (row['hadrami_word'] as String?)?.trim();
    if (w != null && w.isNotEmpty) surfaces.add(w);
    final searchKey = (row['search_key'] as String?)?.trim();
    if (searchKey != null && searchKey.isNotEmpty) surfaces.add(searchKey);
    final aliases = row['aliases'];
    if (aliases is List<dynamic>) {
      for (final a in aliases) {
        if (a is String && a.trim().isNotEmpty) surfaces.add(a.trim());
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
