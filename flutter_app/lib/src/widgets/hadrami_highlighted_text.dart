import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:hadrami_nlp/src/core/models/word_entry.dart';

/// Paints [spans] over [text] using Unicode code-point indices (matches Python `len` / slice).
class HadramiHighlightedText extends StatelessWidget {
  const HadramiHighlightedText({
    super.key,
    required this.text,
    required this.spans,
    required this.baseStyle,
    required this.highlightBackground,
    required this.highlightForeground,
    this.textAlign,
    this.textDirection,
  });

  final String text;
  final List<HadramiSpan> spans;
  final TextStyle baseStyle;
  final Color highlightBackground;
  final Color highlightForeground;
  final TextAlign? textAlign;
  final TextDirection? textDirection;

  @override
  Widget build(BuildContext context) {
    final runes = text.runes.toList();
    final n = runes.length;
    final sorted = [...spans]..sort((a, b) => a.start.compareTo(b.start));
    final children = <TextSpan>[];
    var cursor = 0;
    for (final sp in sorted) {
      final s = sp.start.clamp(0, n);
      final e = sp.end.clamp(0, n);
      if (s >= e) continue;
      if (cursor < s) {
        children.add(TextSpan(
          text: String.fromCharCodes(runes.sublist(cursor, s)),
          style: baseStyle,
        ));
      }
      children.add(TextSpan(
        text: String.fromCharCodes(runes.sublist(s, e)),
        style: baseStyle.copyWith(
          backgroundColor: highlightBackground,
          color: highlightForeground,
        ),
      ));
      cursor = e;
    }
    if (cursor < n) {
      children.add(TextSpan(
        text: String.fromCharCodes(runes.sublist(cursor, n)),
        style: baseStyle,
      ));
    }
    final span = TextSpan(children: children);
    // Web: SelectableText.rich + TextField triggers engine assertion
    // (targetElement == domElement / active input). Mobile/desktop keep selection.
    if (kIsWeb) {
      return Text.rich(
        span,
        textAlign: textAlign,
        textDirection: textDirection,
      );
    }
    return SelectableText.rich(
      span,
      textAlign: textAlign,
      textDirection: textDirection,
    );
  }
}
