// ─────────────────────────────────────────────
// PocketTX Design System – Spacing Tokens
// Zero magic numbers. All spacing from this file.
// ─────────────────────────────────────────────

abstract final class AppSpacing {
  // Base unit: 4dp grid
  static const double xs2 = 2.0;
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 12.0;
  static const double base = 16.0;
  static const double lg = 20.0;
  static const double xl = 24.0;
  static const double xl2 = 32.0;
  static const double xl3 = 40.0;
  static const double xl4 = 48.0;
  static const double xl5 = 56.0;
  static const double xl6 = 64.0;
  static const double xl7 = 80.0;
  static const double xl8 = 96.0;
  static const double xl9 = 128.0;

  // Semantic aliases
  static const double cardPadding = base;
  static const double cardPaddingLg = xl;
  static const double sectionGap = xl2;
  static const double screenPadding = base;
  static const double gimbalPadding = xl;
  static const double buttonHeight = 48.0; // accessibility minimum
  static const double touchTarget = 48.0; // WCAG 2.5.5 minimum
  static const double iconSize = 24.0;
  static const double iconSizeSm = 18.0;
  static const double iconSizeLg = 32.0;
  static const double channelBarHeight = 6.0;
  static const double channelBarHeightLg = 8.0;
  static const double gimbalSize = 0.0;
  static const double gimbalSizeSm = 160.0;
  static const double statusDotSize = 8.0;
}
