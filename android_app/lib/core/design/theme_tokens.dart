// ─────────────────────────────────────────────
// PocketTX Design System – Theme Tokens
// Primary accent: #5B8DEF (PocketTX Blue)
// Dark-first design with full light mode support
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ──────────────────────────────────
  static const Color primary = Color(0xFF5B8DEF);
  static const Color primaryLight = Color(0xFF7EAAFF);
  static const Color primaryDark = Color(0xFF3A6DD4);
  static const Color primaryContainer = Color(0x1A5B8DEF); // 10% opacity

  // ── Accent ─────────────────────────────────
  static const Color accentGreen = Color(0xFF4ADE80);
  static const Color accentAmber = Color(0xFFFBBF24);
  static const Color accentRed = Color(0xFFF87171);
  static const Color accentCyan = Color(0xFF22D3EE);
  static const Color accentPurple = Color(0xFFA78BFA);
  static const Color accentOrange = Color(0xFFFB923C);

  // ── Dark Surfaces ───────────────────────────
  static const Color darkBackground = Color(0xFF0A0C10);
  static const Color darkSurface = Color(0xFF111318);
  static const Color darkCard = Color(0xFF161B24);
  static const Color darkCardElevated = Color(0xFF1C2230);
  static const Color darkBorder = Color(0xFF1E2536);
  static const Color darkBorderSubtle = Color(0xFF161C28);
  static const Color darkDivider = Color(0xFF1A2030);

  // ── Dark Text ──────────────────────────────
  static const Color darkTextPrimary = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF8B97B0);
  static const Color darkTextTertiary = Color(0xFF4D5A70);
  static const Color darkTextDisabled = Color(0xFF2D3748);

  // ── Light Surfaces ──────────────────────────
  static const Color lightBackground = Color(0xFFF4F6FB);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightCardElevated = Color(0xFFF8FAFF);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightBorderSubtle = Color(0xFFEEF2F7);
  static const Color lightDivider = Color(0xFFE8EDF5);

  // ── Light Text ─────────────────────────────
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextTertiary = Color(0xFF94A3B8);
  static const Color lightTextDisabled = Color(0xFFCBD5E1);

  // ── Semantic ────────────────────────────────
  static const Color success = accentGreen;
  static const Color successContainer = Color(0x1A4ADE80);
  static const Color warning = accentAmber;
  static const Color warningContainer = Color(0x1AFBBF24);
  static const Color error = accentRed;
  static const Color errorContainer = Color(0x1AF87171);
  static const Color info = accentCyan;
  static const Color infoContainer = Color(0x1A22D3EE);

  // ── Channel Colors ──────────────────────────
  static const Color ch1Roll = accentCyan;
  static const Color ch2Pitch = accentGreen;
  static const Color ch3Throttle = accentAmber;
  static const Color ch4Yaw = accentPurple;
  static const Color ch5Aux1 = primary;
  static const Color ch6Aux2 = accentOrange;
  static const Color ch7Aux3 = Color(0xFFEC4899);
  static const Color ch8Aux4 = Color(0xFF14B8A6);

  static const List<Color> channelColors = [
    ch1Roll, ch2Pitch, ch3Throttle, ch4Yaw,
    ch5Aux1, ch6Aux2, ch7Aux3, ch8Aux4,
  ];

  // ── Transparency ────────────────────────────
  static const Color transparent = Colors.transparent;
  static Color primaryOverlay(double opacity) =>
      primary.withValues(alpha: opacity);
  static Color darkOverlay(double opacity) =>
      Colors.black.withValues(alpha: opacity);
}

// ── Token Extension ─────────────────────────────
extension ThemeTokens on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get surface => isDark ? AppColors.darkSurface : AppColors.lightSurface;
  Color get cardBg => isDark ? AppColors.darkCard : AppColors.lightCard;
  Color get cardElevatedBg =>
      isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated;
  Color get border => isDark ? AppColors.darkBorder : AppColors.lightBorder;
  Color get borderSubtle =>
      isDark ? AppColors.darkBorderSubtle : AppColors.lightBorderSubtle;
  Color get textPrimary =>
      isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;
  Color get textTertiary =>
      isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary;
  Color get textDisabled =>
      isDark ? AppColors.darkTextDisabled : AppColors.lightTextDisabled;
  Color get background =>
      isDark ? AppColors.darkBackground : AppColors.lightBackground;
  Color get divider =>
      isDark ? AppColors.darkDivider : AppColors.lightDivider;
}
