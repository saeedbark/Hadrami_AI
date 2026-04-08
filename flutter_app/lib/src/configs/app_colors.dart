import 'package:flutter/material.dart';

class AppColors {
  static const Color primaryLight = Color(0xFF1B4F72);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  /// Warm accent aligned with primary (desert / manuscript gold, not pure yellow).
  static const Color secondaryLight = Color(0xFFC9A227);
  static const Color onSecondaryLight = Color(0xFF1A1A1A);
  static const Color errorLight = Color(0xFFCE2C2C);
  static const Color successLight = Color(0xFF2E8B7A);
  static const Color background = Color(0xFFF7F9FC);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF1A1A1A);
  static const Color outlineLight = Color(0xFFC5CED6);
  static const Color disabledLight = Color(0xFFF0F0F0);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF3F6FA);
  static const Color surfaceContainer = Color(0xFFE8EEF4);
  static const Color surfaceContainerHigh = Color(0xFFDDE5EE);
  static const Color surfaceContainerHighest = Color(0xFFD0DAE6);
  static const Color surfaceDim = Color(0xFFC5D0DC);
  static const Color inverseSurface = Color(0xFF2C333A);
  static const Color primaryContainer = Color(0xFFD4E8F4);
  static const Color secondaryContainer = Color(0xFFF5EDD8);
  static const Color errorContainer = Color(0xFFFEEBEC);
  static const Color tertiaryContainer = Color(0xFFE8F2F8);

  static const Color primaryDark = Color(0xFF5DADE2);
  static const Color onPrimaryDark = Color(0xFF002233);
  static const Color secondaryDark = Color(0xFFE8C547);
  static const Color onSecondaryDark = Color(0xFF1A1404);
  static const Color errorDark = Color(0xFFCF6679);
  static const Color successDark = Color(0xFF5FD4B8);
  static const Color backgroundDark = Color(0xFF12151A);
  static const Color surfaceDark = Color(0xFF1A1F26);
  static const Color onSurfaceDark = Color(0xFFE8EAED);
  static const Color outlineDark = Color(0xFF5A6570);
  static const Color disabledDark = Color(0xFF3A3A3A);

  static const Color surfaceContainerLowestDark = Color(0xFF0E1114);
  static const Color surfaceContainerLowDark = Color(0xFF161B22);
  static const Color surfaceContainerDark = Color(0xFF1E252E);
  static const Color surfaceContainerHighDark = Color(0xFF262E38);
  static const Color surfaceContainerHighestDark = Color(0xFF2E3844);
  static const Color surfaceDimDark = Color(0xFF222830);
  static const Color inverseSurfaceDark = Color(0xFFE2E6EB);
  static const Color primaryContainerDark = Color(0xFF1E4A66);
  static const Color secondaryContainerDark = Color(0xFF3D3518);
  static const Color errorContainerDark = Color(0xFFB00020);
  static const Color tertiaryContainerDark = Color(0xFF243240);

  static const Color accent = Color(0xFF1A5276);
  static const Color gold = Color(0xFFE8C547);

  /// Yellow tint behind Hadrami lexicon words (Ask + phrase translation results).
  static Color hadramiLexiconHighlightBackground(Brightness brightness) {
    switch (brightness) {
      case Brightness.dark:
        return gold.withValues(alpha: 0.32);
      case Brightness.light:
        return gold.withValues(alpha: 0.40);
    }
  }
}
