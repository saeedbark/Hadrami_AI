import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hadrami_nlp/src/modules/chat/widgets/hadrami_highlighted_text.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';

/// Reads back the concatenated text of the rendered rich span, so we can prove
/// the painted output still equals the source string. The widget renders
/// `SelectableText.rich` off-web and `Text.rich` on web, so accept either.
String _rendered(WidgetTester tester) {
  final selectable = find.byType(SelectableText);
  if (selectable.evaluate().isNotEmpty) {
    return tester.widget<SelectableText>(selectable).textSpan!.toPlainText();
  }
  return tester.widget<Text>(find.byType(Text)).textSpan!.toPlainText();
}

Future<void> _pump(WidgetTester tester, String text, List<HadramiSpan> spans) {
  return tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: HadramiHighlightedText(
        text: text,
        spans: spans,
        baseStyle: const TextStyle(fontSize: 14),
        highlightBackground: const Color(0xFFFFF3CD),
        highlightForeground: const Color(0xFF000000),
      ),
    ),
  ));
}

void main() {
  testWidgets('non-overlapping spans preserve the text exactly', (t) async {
    await _pump(t, 'كلمة حضرمية هنا', const [HadramiSpan(start: 6, end: 12)]);
    expect(_rendered(t), 'كلمة حضرمية هنا');
  });

  testWidgets('overlapping spans do not duplicate characters', (t) async {
    // /convert-phrase builds spans from model output without merging overlaps.
    await _pump(t, 'كلمة حضرمية هنا', const [
      HadramiSpan(start: 0, end: 8),
      HadramiSpan(start: 5, end: 12),
    ]);
    expect(_rendered(t), 'كلمة حضرمية هنا');
  });

  testWidgets('a fully contained span is absorbed', (t) async {
    await _pump(t, 'كلمة حضرمية هنا', const [
      HadramiSpan(start: 0, end: 11),
      HadramiSpan(start: 2, end: 6),
    ]);
    expect(_rendered(t), 'كلمة حضرمية هنا');
  });

  testWidgets('out-of-range spans are clamped, not thrown', (t) async {
    await _pump(t, 'كلمة', const [HadramiSpan(start: 2, end: 999)]);
    expect(_rendered(t), 'كلمة');
  });
}
