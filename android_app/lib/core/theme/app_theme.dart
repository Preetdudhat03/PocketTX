// ─────────────────────────────────────────────
// PocketTX – App Theme
// EdgeTX-inspired dark/light theme using FlexColorScheme.
// Primary accent: #5B8DEF
// ─────────────────────────────────────────────

import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import '../design/theme_tokens.dart';
import '../design/typography.dart';
import '../design/radius.dart';

abstract final class AppTheme {
  static const Color _primary = AppColors.primary;
  static const Color _darkBg = AppColors.darkBackground;
  static const Color _darkSurface = AppColors.darkSurface;
  static const Color _darkCard = AppColors.darkCard;

  static ThemeData get dark => FlexThemeData.dark(
        scheme: FlexScheme.custom,
        customColors: const FlexSchemeColor(
          primary: _primary,
          primaryContainer: AppColors.primaryContainer,
          secondary: AppColors.accentCyan,
          secondaryContainer: AppColors.infoContainer,
          tertiary: AppColors.accentGreen,
          tertiaryContainer: AppColors.successContainer,
          appBarColor: _darkCard,
          error: AppColors.error,
          errorContainer: AppColors.errorContainer,
        ),
        darkIsTrueBlack: true,
        surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
        blendLevel: 22,
        subThemesData: _subThemes(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: AppTypography.fontFamily,
      ).copyWith(
        scaffoldBackgroundColor: _darkBg,
        cardColor: _darkCard,
        dialogBackgroundColor: _darkCard,
        dividerColor: AppColors.darkDivider,
        colorScheme: const ColorScheme.dark(
          primary: _primary,
          secondary: AppColors.accentCyan,
          surface: _darkSurface,
          error: AppColors.error,
        ),
        textTheme: _textTheme(Brightness.dark),
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary, size: 24),
      );

  static ThemeData get light => FlexThemeData.light(
        scheme: FlexScheme.custom,
        customColors: const FlexSchemeColor(
          primary: _primary,
          primaryContainer: AppColors.primaryContainer,
          secondary: AppColors.accentCyan,
          secondaryContainer: AppColors.infoContainer,
          tertiary: AppColors.accentGreen,
          tertiaryContainer: AppColors.successContainer,
          error: AppColors.error,
          errorContainer: AppColors.errorContainer,
        ),
        subThemesData: _subThemes(),
        visualDensity: FlexColorScheme.comfortablePlatformDensity,
        fontFamily: AppTypography.fontFamily,
      ).copyWith(
        scaffoldBackgroundColor: AppColors.lightBackground,
        cardColor: AppColors.lightCard,
        dividerColor: AppColors.lightDivider,
        textTheme: _textTheme(Brightness.light),
        iconTheme: const IconThemeData(color: AppColors.lightTextPrimary, size: 24),
      );

  static FlexSubThemesData _subThemes() => FlexSubThemesData(
        interactionEffects: true,
        tintedDisabledControls: true,
        useM2StyleDividerInM3: false,
        // Cards
        cardRadius: AppRadius.card,
        // Buttons
        filledButtonRadius: AppRadius.button,
        outlinedButtonRadius: AppRadius.button,
        textButtonRadius: AppRadius.button,
        elevatedButtonRadius: AppRadius.button,
        // Inputs
        inputDecoratorRadius: AppRadius.md,
        inputDecoratorUnfocusedHasBorder: true,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        // Dialogs
        dialogRadius: AppRadius.dialog,
        // Bottom Sheet
        bottomSheetRadius: AppRadius.bottomSheet,
        // Navigation
        navigationBarIndicatorRadius: AppRadius.buttonPill,
      );

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondary =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextTheme(
      displayLarge: AppTypography.displayLgStyle(color: primary),
      headlineLarge: AppTypography.h1Style(color: primary),
      headlineMedium: AppTypography.h2Style(color: primary),
      headlineSmall: AppTypography.h3Style(color: primary),
      titleLarge: AppTypography.h4Style(color: primary),
      titleMedium: AppTypography.bodyLgStyle(color: primary),
      titleSmall: AppTypography.bodyStyle(color: primary),
      bodyLarge: AppTypography.bodyLgStyle(color: primary),
      bodyMedium: AppTypography.bodyStyle(color: primary),
      bodySmall: AppTypography.bodyStyle(color: secondary),
      labelLarge: AppTypography.labelStyle(color: primary),
      labelMedium: AppTypography.labelStyle(color: secondary),
      labelSmall: AppTypography.captionStyle(color: secondary),
    );
  }
}
