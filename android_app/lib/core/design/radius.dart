// ─────────────────────────────────────────────
// PocketTX Design System – Border Radius Tokens
// ─────────────────────────────────────────────

import 'package:flutter/painting.dart';

abstract final class AppRadius {
  static const double none = 0.0;
  static const double xs = 4.0;
  static const double sm = 6.0;
  static const double md = 8.0;
  static const double lg = 12.0;
  static const double xl = 16.0;
  static const double xl2 = 20.0;
  static const double xl3 = 24.0;
  static const double full = 9999.0;

  // Semantic aliases
  static const double card = lg;
  static const double cardLg = xl;
  static const double button = md;
  static const double buttonPill = full;
  static const double chip = sm;
  static const double bottomSheet = xl3;
  static const double dialog = xl;
  static const double gimbalTrack = full;
  static const double channelBar = full;
  static const double badge = full;
  static const double switchTrack = full;

  // BorderRadius helpers
  static const BorderRadius cardBorder = BorderRadius.all(Radius.circular(card));
  static const BorderRadius cardLgBorder = BorderRadius.all(Radius.circular(cardLg));
  static const BorderRadius buttonBorder = BorderRadius.all(Radius.circular(button));
  static const BorderRadius pillBorder = BorderRadius.all(Radius.circular(full));
  static const BorderRadius topSheet = BorderRadius.only(
    topLeft: Radius.circular(bottomSheet),
    topRight: Radius.circular(bottomSheet),
  );
}
