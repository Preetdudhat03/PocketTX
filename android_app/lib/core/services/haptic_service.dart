// ─────────────────────────────────────────────
// PocketTX – Haptic Service
// Centralized haptic feedback controller.
// ─────────────────────────────────────────────

import 'package:flutter/services.dart';

/// Centralized haptic feedback service.
/// All haptic triggers go through this service so they can be
/// globally enabled/disabled from settings.
class HapticService {
  static final HapticService _instance = HapticService._internal();
  factory HapticService() => _instance;
  HapticService._internal();

  bool _enabled = true;

  bool get isEnabled => _enabled;

  void setEnabled(bool enabled) => _enabled = enabled;

  /// Light tap — button press, toggle, selection.
  Future<void> light() async {
    if (!_enabled) return;
    try { await HapticFeedback.lightImpact(); } catch (_) {}
  }

  /// Medium tap — ARM/DISARM, profile switch.
  Future<void> medium() async {
    if (!_enabled) return;
    try { await HapticFeedback.mediumImpact(); } catch (_) {}
  }

  /// Heavy tap — critical action, error.
  Future<void> heavy() async {
    if (!_enabled) return;
    try { await HapticFeedback.heavyImpact(); } catch (_) {}
  }

  /// Selection changed — e.g. profile list scroll.
  Future<void> selection() async {
    if (!_enabled) return;
    try { await HapticFeedback.selectionClick(); } catch (_) {}
  }

  /// Vibrate — center snap confirmation on gimbal return.
  Future<void> vibrate() async {
    if (!_enabled) return;
    try { await HapticFeedback.vibrate(); } catch (_) {}
  }
}
