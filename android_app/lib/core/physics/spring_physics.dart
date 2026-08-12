// ─────────────────────────────────────────────
// PocketTX – SpringPhysics
// Smooth spring-return to center on release.
// Used for Yaw, Pitch, Roll axes.
// ─────────────────────────────────────────────

import 'dart:ui';
import 'dart:math' as math;
import 'i_stick_physics.dart';
import '../services/haptic_service.dart';

/// Implements high-precision physical spring-return physics for RC transmitter gimbals (Pitch, Roll, Yaw).
///
/// Simulates physical gimbal spring tension, mechanical inertia, and damping.
class SpringPhysics implements IStickPhysics {
  final Offset restPosition;
  final double stiffness;   // Mechanical spring tension (default: 320)
  final double damping;     // Damping coefficient (default: 32)
  final double mass;        // Stick mass (default: 1.0)

  Offset _position;
  Offset _velocity;
  bool _isPressed;
  bool _centerHapticFired = false;

  SpringPhysics({
    this.restPosition = Offset.zero,
    this.stiffness = 320.0,
    double? damping,
    this.mass = 1.0,
  })  : _position = restPosition,
        _velocity = Offset.zero,
        _isPressed = false,
        damping = damping ?? 32.0;

  @override
  Offset get position => _position;

  @override
  bool get isPressed => _isPressed;

  @override
  void update({Offset? target, required double dtSeconds}) {
    if (target != null) {
      _isPressed = true;
      _centerHapticFired = false;
      // Direct 1:1 touch response
      _position = Offset(
        target.dx.clamp(-1.0, 1.0),
        target.dy.clamp(-1.0, 1.0),
      );
      _velocity = Offset.zero;
    } else {
      _isPressed = false;
      // Physical spring acceleration: F = -k*x - c*v
      final displacement = _position - restPosition;
      final springForce = -displacement * stiffness;
      final dampingForce = -_velocity * damping;
      final acceleration = (springForce + dampingForce) / mass;

      _velocity += acceleration * dtSeconds;
      final newPos = _position + _velocity * dtSeconds;

      // Detect center crossing for tactile haptic snap feedback
      if (!_centerHapticFired &&
          (_position.distance > 0.05) &&
          (newPos.distance <= 0.05)) {
        _centerHapticFired = true;
        HapticService().light();
      }

      // Clamp to [-1, 1] on both axes
      _position = Offset(
        newPos.dx.clamp(-1.0, 1.0),
        newPos.dy.clamp(-1.0, 1.0),
      );

      // Snap to rest when very close to eliminate micro-jitter
      if ((_position - restPosition).distance < 0.0008 &&
          _velocity.distance < 0.001) {
        _position = restPosition;
        _velocity = Offset.zero;
      }
    }
  }

  @override
  void snapTo(Offset position) {
    _position = Offset(
      position.dx.clamp(-1.0, 1.0),
      position.dy.clamp(-1.0, 1.0),
    );
    _velocity = Offset.zero;
    _isPressed = true;
    _centerHapticFired = false;
  }

  @override
  void reset() {
    _position = restPosition;
    _velocity = Offset.zero;
    _isPressed = false;
    _centerHapticFired = false;
  }
}
