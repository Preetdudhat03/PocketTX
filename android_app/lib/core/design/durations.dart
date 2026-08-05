// ─────────────────────────────────────────────
// PocketTX Design System – Animation Durations
// ─────────────────────────────────────────────

abstract final class AppDurations {
  // Instant feedback
  static const Duration instant = Duration(milliseconds: 0);

  // Micro interactions
  static const Duration fastest = Duration(milliseconds: 75);
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration normal = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration slower = Duration(milliseconds: 500);
  static const Duration slowest = Duration(milliseconds: 700);

  // Page transitions
  static const Duration pageEnter = Duration(milliseconds: 280);
  static const Duration pageExit = Duration(milliseconds: 200);

  // Semantic aliases
  static const Duration buttonFeedback = fastest;
  static const Duration tooltipShow = slow;
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration statusBadge = normal;
  static const Duration cardHover = fast;
  static const Duration gimbalReturn = medium; // spring return feel
  static const Duration channelBarUpdate = fastest;
  static const Duration overlayFade = normal;
  static const Duration drawerSlide = medium;
  static const Duration dialogScale = fast;
  static const Duration devOverlayFade = fast;

  // Physics loop targets (not Duration-based, but exposed for consistency)
  static const int tickEngineHz = 250; // default update rate
  static const int physicsHz = 60;
  static const int diagnosticsHz = 10;
  static const int uiMetricsHz = 1;
}
