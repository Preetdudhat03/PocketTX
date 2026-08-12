// ─────────────────────────────────────────────
// PocketTX – RatchetPhysics
// Throttle stays at released position (free-stay).
// Only Y axis is controlled (throttle).
// Used for the throttle axis in Mode 2.
// ─────────────────────────────────────────────

import 'dart:ui';
import 'i_stick_physics.dart';
import '../services/haptic_service.dart';

/// Implements free-stay (ratchet) physics for the throttle axis and spring return for yaw.
///
/// Features a tactile 50% hover detent notch on throttle and spring return on yaw.
class RatchetPhysics implements IStickPhysics {
  final double yawStiffness;
  final double yawDamping;

  Offset _position;
  double _yawVelocity;
  bool _isPressed;
  bool _hoverDetentFired = false;
  double _lastThrottle = -1.0;

  RatchetPhysics({
    this.yawStiffness = 320.0,
    this.yawDamping = 32.0,
    Offset initialPosition = const Offset(0.0, -1.0), // throttle starts at bottom (-1.0)
  })  : _position = initialPosition,
        _yawVelocity = 0.0,
        _isPressed = false,
        _lastThrottle = initialPosition.dy;

  @override
  Offset get position => _position;

  @override
  bool get isPressed => _isPressed;

  @override
  void update({Offset? target, required double dtSeconds}) {
    if (target != null) {
      _isPressed = true;
      final newThrottle = target.dy.clamp(-1.0, 1.0);

      // Detect crossing 50% hover detent (0.0 / 1500us)
      if (!_hoverDetentFired &&
          ((_lastThrottle < -0.05 && newThrottle >= 0.0) ||
           (_lastThrottle > 0.05 && newThrottle <= 0.0))) {
        _hoverDetentFired = true;
        HapticService().selection();
      } else if ((newThrottle - 0.0).abs() > 0.08) {
        _hoverDetentFired = false;
      }
      _lastThrottle = newThrottle;

      _position = Offset(
        target.dx.clamp(-1.0, 1.0),
        newThrottle,
      );
      _yawVelocity = 0.0;
    } else {
      _isPressed = false;
      // Throttle Y holds position (free-stay)
      // Yaw X springs back to center (0.0)
      final yawDisplacement = _position.dx;
      final yawSpring = -yawDisplacement * yawStiffness;
      final yawDamp = -_yawVelocity * yawDamping;
      _yawVelocity += (yawSpring + yawDamp) * dtSeconds;
      final newYaw = (_position.dx + _yawVelocity * dtSeconds).clamp(-1.0, 1.0);

      _position = Offset(
        (newYaw.abs() < 0.0008 && _yawVelocity.abs() < 0.001) ? 0.0 : newYaw,
        _position.dy,
      );
    }
  }

  @override
  void snapTo(Offset position) {
    _position = Offset(
      position.dx.clamp(-1.0, 1.0),
      position.dy.clamp(-1.0, 1.0),
    );
    _lastThrottle = _position.dy;
    _yawVelocity = 0.0;
    _isPressed = true;
    _hoverDetentFired = false;
  }

  @override
  void reset() {
    _position = const Offset(0.0, -1.0); // throttle to minimum
    _lastThrottle = -1.0;
    _yawVelocity = 0.0;
    _isPressed = false;
    _hoverDetentFired = false;
  }
}
