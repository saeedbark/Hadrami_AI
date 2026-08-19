import 'package:flutter_test/flutter_test.dart';
import 'package:hadrami_nlp/src/modules/lexicon/models/dictionary_labels.dart';

void main() {
  group('WordRegion.isDefault', () {
    // Supabase serves `region` lowercased; the staging dataset uses Title Case.
    // Both must be recognised as the default, or the region chip renders on
    // ~97% of entries (regression found 2026-08-18).
    test('recognises the default region in both casings', () {
      expect(WordRegion.isDefault('general'), isTrue);
      expect(WordRegion.isDefault('General'), isTrue);
      expect(WordRegion.isDefault('  General  '), isTrue);
    });

    test('treats a blank region as default', () {
      expect(WordRegion.isDefault(''), isTrue);
      expect(WordRegion.isDefault('   '), isTrue);
    });

    test('does not swallow a real region', () {
      expect(WordRegion.isDefault('coast'), isFalse);
      expect(WordRegion.isDefault('Ghayl Ba Wazir'), isFalse);
    });
  });

  group('label lookup is case-insensitive against real Supabase values', () {
    test('region', () {
      expect(WordRegion.arabicLabelFor('coast'), 'ساحل');
      expect(WordRegion.arabicLabelFor('Coast / Wadi'), 'ساحل / وادي');
    });

    test('part of speech', () {
      expect(PartOfSpeech.arabicLabelFor('Noun'), 'اسم');
      expect(PartOfSpeech.arabicLabelFor('Noun/Verb'), 'اسم / فعل');
    });

    test('tags, which Supabase stores lowercased', () {
      expect(tagArabicLabel('daily life'), 'الحياة اليومية');
      expect(tagArabicLabel('Daily Life'), 'الحياة اليومية');
    });

    test('an unknown value falls back to the raw text', () {
      expect(tagArabicLabel('quantum tunnelling'), 'quantum tunnelling');
      expect(PartOfSpeech.arabicLabelFor('Gerund'), 'Gerund');
    });
  });
}
