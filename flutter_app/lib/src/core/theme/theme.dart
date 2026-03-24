import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hadrami_nlp/src/configs/app_colors.dart';
import 'package:hadrami_nlp/src/configs/app_radius.dart';

class AppTheme {
  static TextStyle _textStyle({
    required Color color,
    required double fontSize,
    FontWeight fontWeight = FontWeight.normal,
    double height = 0,
    double letterSpacing = 0,
  }) =>
      GoogleFonts.ibmPlexSansArabic(
        color: color,
        fontSize: fontSize,
        fontWeight: fontWeight,
        height: height,
        letterSpacing: letterSpacing,
      );

  static ThemeData get lightTheme {
    const colorScheme = ColorScheme.light(
      primary: AppColors.primaryLight,
      onPrimary: AppColors.onPrimaryLight,
      surface: AppColors.surfaceLight,
      onSurface: AppColors.onSurfaceLight,
      surfaceContainerLowest: AppColors.surfaceContainerLowest,
      surfaceContainerLow: AppColors.surfaceContainerLow,
      surfaceContainer: AppColors.surfaceContainer,
      inverseSurface: AppColors.inverseSurface,
      surfaceContainerHigh: AppColors.surfaceContainerHigh,
      surfaceContainerHighest: AppColors.surfaceContainerHighest,
      surfaceDim: AppColors.surfaceDim,
      primaryContainer: AppColors.primaryContainer,
      secondaryContainer: AppColors.secondaryContainer,
      errorContainer: AppColors.errorContainer,
      tertiaryContainer: AppColors.tertiaryContainer,
      secondary: AppColors.secondaryLight,
      onSecondary: AppColors.onSecondaryLight,
      error: AppColors.errorLight,
      onError: AppColors.onPrimaryLight,
      outline: AppColors.outlineLight,
    );

    final textTheme = _getTextTheme(colorScheme);

    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.background,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      useMaterial3: true,
      disabledColor: AppColors.disabledLight,
      scaffoldBackgroundColor: AppColors.background,
      dividerColor: colorScheme.outline,
      colorScheme: colorScheme,
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: colorScheme.outline.withValues(alpha: .25),
        space: 24,
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shadowColor: const Color(0x260B1F46),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      inputDecorationTheme: _getInputDecorationTheme(textTheme, colorScheme),
      textTheme: textTheme,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryLight,
        foregroundColor: AppColors.onPrimaryLight,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryLight,
          foregroundColor: AppColors.onPrimaryLight,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          textStyle: _textStyle(
            color: AppColors.onPrimaryLight,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryLight,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          side: const BorderSide(color: AppColors.primaryLight),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainer,
        labelStyle: _textStyle(
          color: AppColors.primaryLight,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        backgroundColor: AppColors.surfaceLight,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedItemColor: AppColors.primaryLight,
        unselectedItemColor: AppColors.outlineLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: _textStyle(
          color: AppColors.primaryLight,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: _textStyle(
          color: AppColors.outlineLight,
          fontSize: 11,
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceLight,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryLight),
        unselectedIconTheme: const IconThemeData(color: AppColors.outlineLight),
        indicatorColor: AppColors.primaryContainer,
      ),
    );
  }

  static ThemeData get darkTheme {
    const colorScheme = ColorScheme.dark(
      primary: AppColors.primaryDark,
      onPrimary: AppColors.onPrimaryDark,
      surface: AppColors.surfaceDark,
      onSurface: AppColors.onSurfaceDark,
      surfaceContainerLowest: AppColors.surfaceContainerLowestDark,
      surfaceContainerLow: AppColors.surfaceContainerLowDark,
      surfaceContainer: AppColors.surfaceContainerDark,
      inverseSurface: AppColors.inverseSurfaceDark,
      surfaceContainerHigh: AppColors.surfaceContainerHighDark,
      surfaceContainerHighest: AppColors.surfaceContainerHighestDark,
      surfaceDim: AppColors.surfaceDimDark,
      primaryContainer: AppColors.primaryContainerDark,
      secondaryContainer: AppColors.secondaryContainerDark,
      errorContainer: AppColors.errorContainerDark,
      tertiaryContainer: AppColors.tertiaryContainerDark,
      secondary: AppColors.secondaryDark,
      onSecondary: AppColors.onSecondaryDark,
      error: AppColors.errorDark,
      onError: AppColors.onPrimaryDark,
      outline: AppColors.outlineDark,
    );

    final textTheme = _getTextTheme(colorScheme);

    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 1,
      ),
      useMaterial3: true,
      disabledColor: AppColors.disabledDark,
      scaffoldBackgroundColor: AppColors.backgroundDark,
      dividerColor: colorScheme.surface,
      colorScheme: colorScheme,
      dividerTheme: DividerThemeData(
        thickness: 1,
        color: colorScheme.surface,
        space: 24,
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: const Color(0x260B1F46),
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: AppColors.surfaceDark,
      ),
      inputDecorationTheme: _getInputDecorationTheme(textTheme, colorScheme),
      textTheme: textTheme,
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryDark,
        foregroundColor: AppColors.onPrimaryDark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lg),
        elevation: 4,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryDark,
          foregroundColor: AppColors.onPrimaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primaryDark,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.md),
          side: const BorderSide(color: AppColors.primaryDark),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.primaryContainerDark,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sm),
      ),
      dialogTheme: DialogThemeData(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xl),
        backgroundColor: AppColors.surfaceDark,
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedItemColor: AppColors.primaryDark,
        unselectedItemColor: AppColors.outlineDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: AppColors.surfaceDark,
        selectedIconTheme: const IconThemeData(color: AppColors.primaryDark),
        unselectedIconTheme: const IconThemeData(color: AppColors.outlineDark),
        indicatorColor: AppColors.primaryContainerDark,
      ),
    );
  }

  static InputDecorationTheme _getInputDecorationTheme(
    TextTheme textTheme,
    ColorScheme colorScheme,
  ) {
    return InputDecorationTheme(
      hintStyle: textTheme.bodyLarge?.copyWith(color: colorScheme.outline),
      prefixIconColor: colorScheme.onSurface,
      suffixIconColor: colorScheme.onSurface,
      filled: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      fillColor: colorScheme.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.lg,
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.lg,
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.lg,
        borderSide:
            BorderSide(color: colorScheme.outline.withValues(alpha: .3)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.lg,
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: AppRadius.lg,
        borderSide: BorderSide(color: colorScheme.error),
      ),
    );
  }

  static TextTheme _getTextTheme(ColorScheme colorScheme) {
    return TextTheme(
      displaySmall: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 36,
        fontWeight: FontWeight.w700,
        height: 44 / 36,
      ),
      headlineLarge: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 32,
        fontWeight: FontWeight.w700,
        height: 40 / 32,
      ),
      headlineMedium: _textStyle(
        color: colorScheme.onSurface,
        fontWeight: FontWeight.w700,
        fontSize: 28,
        height: 36 / 28,
      ),
      headlineSmall: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 32 / 24,
      ),
      titleLarge: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        height: 28 / 20,
      ),
      titleMedium: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        height: 24 / 18,
      ),
      titleSmall: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w500,
        height: 20 / 16,
      ),
      bodyLarge: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 24 / 16,
      ),
      bodyMedium: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 20 / 14,
      ),
      bodySmall: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
      labelLarge: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 14,
        fontWeight: FontWeight.w500,
        height: 20 / 14,
      ),
      labelMedium: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 16 / 12,
      ),
      labelSmall: _textStyle(
        color: colorScheme.onSurface,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        height: 14 / 10,
      ),
    );
  }

  static const tabletBreakPoint = 600;
  static const desktopBreakPoint = 1200;
}

extension ResponsiveContext on BuildContext {
  bool get isMobile =>
      MediaQuery.sizeOf(this).width < AppTheme.tabletBreakPoint;
  bool get isTablet =>
      MediaQuery.sizeOf(this).width >= AppTheme.tabletBreakPoint &&
      MediaQuery.sizeOf(this).width < AppTheme.desktopBreakPoint;
  bool get isDesktop =>
      MediaQuery.sizeOf(this).width >= AppTheme.desktopBreakPoint;
}
