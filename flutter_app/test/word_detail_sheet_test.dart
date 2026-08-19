import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/word_entry.dart';
import 'package:hadrami_nlp/src/modules/lexicon/widgets/word_detail_sheet.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

const _entry = WordEntry(
  id: 1,
  wordVocalized: 'إِثّم',
  definition: 'تعريف',
  fushaEquivalent: 'إثم',
);

Future<void> _pump(WidgetTester tester, WordEntry entry) async {
  await tester.pumpWidget(ProviderScope(
    child: MaterialApp(home: Scaffold(body: WordDetailSheet(entry: entry))),
  ));
  await tester.pumpAndSettle();
}

void main() {
  // Regression (2026-08-18): the chip was hidden with `region != 'General'`,
  // but Supabase serves `general` lowercased, so it rendered on ~97% of rows.
  testWidgets('region chip is hidden for the default region, either casing',
      (tester) async {
    await _pump(tester, _entry.copyWith(region: 'General'));
    expect(find.text('عام'), findsNothing);

    await _pump(tester, _entry.copyWith(region: 'general'));
    expect(find.text('عام'), findsNothing);
  });

  testWidgets('a real region is still shown', (tester) async {
    await _pump(tester, _entry.copyWith(region: 'coast'));
    expect(find.text('ساحل'), findsOneWidget);
  });
}
