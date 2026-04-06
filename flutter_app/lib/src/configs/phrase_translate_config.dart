/// Must match backend [PHRASE_TRANSLATE_MAX_CHARS] / long-hint thresholds.
class PhraseTranslateConfig {
  PhraseTranslateConfig._();

  static const int minLength = 2;
  static const int maxLength = 3000;
  /// Above this, the UI suggests splitting input for better quality.
  static const int softRecommendLength = 400;
  /// Above this, a chunking warning is shown.
  static const int chunkWarningLength = 800;
}
