import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:hadrami_nlp/src/app.dart';

void main() {
  testWidgets('App boots and shows navigation labels', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: HadramiApp(),
      ),
    );
    await tester.pump();
    expect(find.text('الرئيسية'), findsWidgets);
  });
}
