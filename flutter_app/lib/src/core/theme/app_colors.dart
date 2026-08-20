import 'package:flutter/material.dart';

class AppColors {
  // ----- LIGHT -----
  static const Color primaryLight = Color(0xFFB5471F);
  static const Color onPrimaryLight = Color(0xFFFFFFFF);
  static const Color secondaryLight = Color(0xFFD49B2A);
  static const Color onSecondaryLight = Color(0xFF2A1F0A);
  static const Color errorLight = Color(0xFFC0392B);
  static const Color successLight = Color(0xFF2E8B5C);
  static const Color background = Color(0xFFFAF6EE);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onSurfaceLight = Color(0xFF2D241B);
  static const Color outlineLight = Color(0xFFB8A98F);
  static const Color disabledLight = Color(0xFFEDE6D8);

  static const Color surfaceContainerLowest = Color(0xFFFFFFFF);
  static const Color surfaceContainerLow = Color(0xFFF5EFE3);
  static const Color surfaceContainer = Color(0xFFEFE7D6);
  static const Color surfaceContainerHigh = Color(0xFFE7DCC6);
  static const Color surfaceContainerHighest = Color(0xFFDDD0B6);
  static const Color surfaceDim = Color(0xFFD0C2A6);
  static const Color inverseSurface = Color(0xFF2D241B);
  static const Color primaryContainer = Color(0xFFFADBC9);
  static const Color secondaryContainer = Color(0xFFFAEAC1);
  static const Color errorContainer = Color(0xFFFAD7D2);
  static const Color tertiaryContainer = Color(0xFFE8DCC6);

  // ----- DARK -----
  static const Color primaryDark = Color(0xFFE0805A);
  static const Color onPrimaryDark = Color(0xFF3A1605);
  static const Color secondaryDark = Color(0xFFE8B847);
  static const Color onSecondaryDark = Color(0xFF2A1F0A);
  static const Color errorDark = Color(0xFFE57373);
  static const Color successDark = Color(0xFF7BC59C);
  static const Color backgroundDark = Color(0xFF1A140F);
  static const Color surfaceDark = Color(0xFF221C16);
  static const Color onSurfaceDark = Color(0xFFECE3D5);
  static const Color outlineDark = Color(0xFF6B5F4F);
  static const Color disabledDark = Color(0xFF3A312A);

  static const Color surfaceContainerLowestDark = Color(0xFF120D09);
  static const Color surfaceContainerLowDark = Color(0xFF1E1813);
  static const Color surfaceContainerDark = Color(0xFF26201A);
  static const Color surfaceContainerHighDark = Color(0xFF302820);
  static const Color surfaceContainerHighestDark = Color(0xFF3A3128);
  static const Color surfaceDimDark = Color(0xFF2A231D);
  static const Color inverseSurfaceDark = Color(0xFFECE3D5);
  static const Color primaryContainerDark = Color(0xFF6B2D14);
  static const Color secondaryContainerDark = Color(0xFF4A3A14);
  static const Color errorContainerDark = Color(0xFF6E1F17);
  static const Color tertiaryContainerDark = Color(0xFF3A2E1E);

  static const Color accent = Color(0xFFB5471F);
  static const Color gold = Color(0xFFE8B847);

  static Color hadramiLexiconHighlightBackground(Brightness brightness) {
    switch (brightness) {
      case Brightness.dark:
        return gold.withValues(alpha: 0.34);
      case Brightness.light:
        return gold.withValues(alpha: 0.42);
    }
  }
}
