// ─────────────────────────────────────────────
// PocketTX – SpringPhysics
// Smooth spring-return to center on release.
// Used for Yaw, Pitch, Roll axes.
// ─────────────────────────────────────────────

import 'dart:ui';
import 'dart:math';
import 'i_stick_physics.dart';

/// Implements spring-return physics for self-centering sticks (Pitch, Roll, Yaw).
///
/// When released, the stick returns to [restPosition] using a critically-damped
/// spring for smooth, overshoots-free return at any speed setting.
class SpringPhysics implements IStickPhysics {
  final Offset restPosition;
  final double stiffness;   // higher = faster return (default: 280)
  final double damping;     // critical damping: 2 * sqrt(stiffness) (default: ~33)
  final double mass;        // virtual mass (default: 1.0)

  Offset _position;
  Offset _velocity;
  bool _isPressed;

  SpringPhysics({
    this.restPosition = Offset.zero,
    this.stiffness = 280.0,
    double? damping,
    this.mass = 1.0,
  })  : _position = restPosition,
        _velocity = Offset.zero,
        _isPressed = false,
        damping = damping ?? 2.0 * sqrt(280.0);

  @override
  Offset get position => _position;

  @override
  bool get isPressed => _isPressed;

  @override
  void update({Offset? target, required double dtSeconds}) {
    if (target != null) {
      _isPressed = true;
      // While touched: directly follow finger with light lag for feel
      _position = Offset.lerp(_position, target, (1.0 - pow(0.01, dtSeconds)).clamp(0.0, 1.0))!;
      _velocity = Offset.zero;
    } else {
      _isPressed = false;
      // Released: simulate spring toward restPosition
      final displacement = _position - restPosition;
      final springForce = -displacement * stiffness;
      final dampingForce = -_velocity * damping;
      final acceleration = (springForce + dampingForce) / mass;

      _velocity += acceleration * dtSeconds;
      final newPos = _position + _velocity * dtSeconds;

      // Clamp to [-1, 1] on both axes
      _position = Offset(
        newPos.dx.clamp(-1.0, 1.0),
        newPos.dy.clamp(-1.0, 1.0),
      );

      // Snap to rest when very close to avoid micro-jitter
      if ((_position - restPosition).distance < 0.001 &&
          _velocity.distance < 0.001) {
        _position = restPosition;
        _velocity = Offset.zero;
      }
    }
  }

  @override
  void snapTo(Offset position) {
    _position = position;
    _velocity = Offset.zero;
    _isPressed = true;
  }

  @override
  void reset() {
    _position = restPosition;
    _velocity = Offset.zero;
    _isPressed = false;
  }
}
