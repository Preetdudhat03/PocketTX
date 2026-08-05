// ─────────────────────────────────────────────
// PocketTX – RatchetPhysics
// Throttle stays at released position (free-stay).
// Only Y axis is controlled (throttle).
// Used for the throttle axis in Mode 2.
// ─────────────────────────────────────────────

import 'dart:ui';
import 'i_stick_physics.dart';

/// Implements free-stay (ratchet) physics for the throttle axis.
///
/// On release, the stick holds its last Y position (throttle level).
/// X axis (Yaw) uses spring return independently.
class RatchetPhysics implements IStickPhysics {
  final double yawStiffness;
  final double yawDamping;

  Offset _position;
  double _yawVelocity;
  bool _isPressed;

  RatchetPhysics({
    this.yawStiffness = 200.0,
    this.yawDamping = 28.0,
    Offset initialPosition = const Offset(0.0, -1.0), // throttle starts at bottom
  })  : _position = initialPosition,
        _yawVelocity = 0.0,
        _isPressed = false;

  @override
  Offset get position => _position;

  @override
  bool get isPressed => _isPressed;

  @override
  void update({Offset? target, required double dtSeconds}) {
    if (target != null) {
      _isPressed = true;
      // Follow finger directly: both throttle (Y) and yaw (X) follow touch
      _position = Offset(
        target.dx.clamp(-1.0, 1.0),
        target.dy.clamp(-1.0, 1.0),
      );
      _yawVelocity = 0.0;
    } else {
      _isPressed = false;
      // Throttle Y: hold position (free-stay, no spring)
      // Yaw X: spring back to center
      final yawDisplacement = _position.dx;
      final yawSpring = -yawDisplacement * yawStiffness;
      final yawDamp = -_yawVelocity * yawDamping;
      _yawVelocity += (yawSpring + yawDamp) * dtSeconds;
      final newYaw = (_position.dx + _yawVelocity * dtSeconds).clamp(-1.0, 1.0);

      _position = Offset(
        (newYaw.abs() < 0.001 && _yawVelocity.abs() < 0.001) ? 0.0 : newYaw,
        _position.dy, // throttle unchanged
      );
    }
  }

  @override
  void snapTo(Offset position) {
    _position = Offset(
      position.dx.clamp(-1.0, 1.0),
      position.dy.clamp(-1.0, 1.0),
    );
    _yawVelocity = 0.0;
    _isPressed = true;
  }

  @override
  void reset() {
    _position = const Offset(0.0, -1.0); // throttle to minimum
    _yawVelocity = 0.0;
    _isPressed = false;
  }
}
