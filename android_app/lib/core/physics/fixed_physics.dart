// ─────────────────────────────────────────────
// PocketTX – FixedPhysics
// Stick holds exact position — no spring, no return.
// Useful for aux channels or testing.
// ─────────────────────────────────────────────

import 'dart:ui';
import 'i_stick_physics.dart';

/// Stick stays exactly where placed. No physics simulation.
class FixedPhysics implements IStickPhysics {
  Offset _position;
  bool _isPressed;
  final Offset restPosition;

  FixedPhysics({this.restPosition = Offset.zero})
      : _position = restPosition,
        _isPressed = false;

  @override
  Offset get position => _position;

  @override
  bool get isPressed => _isPressed;

  @override
  void update({Offset? target, required double dtSeconds}) {
    if (target != null) {
      _isPressed = true;
      _position = Offset(
        target.dx.clamp(-1.0, 1.0),
        target.dy.clamp(-1.0, 1.0),
      );
    } else {
      _isPressed = false;
      // No movement — stays in last position
    }
  }

  @override
  void snapTo(Offset position) {
    _position = Offset(
      position.dx.clamp(-1.0, 1.0),
      position.dy.clamp(-1.0, 1.0),
    );
    _isPressed = true;
  }

  @override
  void reset() {
    _position = restPosition;
    _isPressed = false;
  }
}
