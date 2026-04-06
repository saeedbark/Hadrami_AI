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
    final aliases = row['aliases'];
    if (aliases is List<dynamic>) {
      for (final a in aliases) {
        if (a is String && a.trim().isNotEmpty) surfaces.add(a.trim());
      }
    }
  }

  final sorted = surfaces.toList()
    ..sort((a, b) => b.runes.length.compareTo(a.runes.length));

  final runes = text.runes.toList();
  final n = runes.length;
  final intervals = <List<int>>[];

  for (final surface in sorted) {
    final needle = surface.runes.toList();
    if (needle.length < 2 || needle.length > n) continue;
    outer:
    for (var i = 0; i <= n - needle.length; i++) {
      for (var j = 0; j < needle.length; j++) {
        if (runes[i + j] != needle[j]) continue outer;
      }
      intervals.add([i, i + needle.length]);
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
        final slice = String.fromCharCodes(runes.sublist(s, e));
        return HadramiSpan(start: s, end: e, surface: slice);
      })
      .toList(growable: false);
}
