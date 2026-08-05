// ─────────────────────────────────────────────
// PocketTX – IStickPhysics Interface
// Decouples gimbal physics behavior from UI rendering.
// ─────────────────────────────────────────────

import 'dart:ui';

/// Abstract interface for 2D stick physics behavior.
/// The gimbal widget calls [update] every physics tick and reads [position].
abstract interface class IStickPhysics {
  /// Current 2D stick position (-1.0 to +1.0 on both axes).
  Offset get position;

  /// Whether the stick is currently being touched.
  bool get isPressed;

  /// Update the physics state.
  ///
  /// [target]    Desired position (from touch input), or null if released.
  /// [dtSeconds] Elapsed time in seconds since last update.
  void update({Offset? target, required double dtSeconds});

  /// Force the stick to a specific position instantly (e.g. on touch begin).
  void snapTo(Offset position);

  /// Reset to resting position (center or bottom for throttle).
  void reset();
}
