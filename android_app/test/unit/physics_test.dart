import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/core/physics/spring_physics.dart';
import 'package:PocketTX/core/physics/ratchet_physics.dart';
import 'package:PocketTX/core/physics/fixed_physics.dart';

void main() {
  group('SpringPhysics', () {
    test('initializes at rest position', () {
      final p = SpringPhysics();
      expect(p.position, Offset.zero);
      expect(p.isPressed, isFalse);
    });

    test('snapTo moves position immediately', () {
      final p = SpringPhysics();
      p.snapTo(const Offset(0.5, -0.3));
      expect(p.position.dx, closeTo(0.5, 0.001));
      expect(p.position.dy, closeTo(-0.3, 0.001));
      expect(p.isPressed, isTrue);
    });

    test('released position converges toward rest over time', () {
      final p = SpringPhysics();
      p.snapTo(const Offset(1.0, 1.0));
      // Simulate multiple physics frames toward release
      for (int i = 0; i < 300; i++) {
        p.update(target: null, dtSeconds: 1 / 60.0);
      }
      expect(p.position.distance, lessThan(0.01));
    });

    test('reset returns to rest position', () {
      final p = SpringPhysics();
      p.snapTo(const Offset(0.8, 0.8));
      p.reset();
      expect(p.position, Offset.zero);
      expect(p.isPressed, isFalse);
    });
  });

  group('RatchetPhysics', () {
    test('throttle holds position on release', () {
      final p = RatchetPhysics();
      p.snapTo(const Offset(0.0, 0.7)); // throttle at 0.7
      // simulate 30 frames without touch
      for (int i = 0; i < 30; i++) {
        p.update(target: null, dtSeconds: 1 / 60.0);
      }
      // Throttle Y should still be near 0.7
      expect(p.position.dy, closeTo(0.7, 0.01));
    });

    test('yaw springs back to center on release', () {
      final p = RatchetPhysics();
      p.snapTo(const Offset(1.0, 0.5)); // yaw at 1.0
      for (int i = 0; i < 200; i++) {
        p.update(target: null, dtSeconds: 1 / 60.0);
      }
      expect(p.position.dx.abs(), lessThan(0.05));
    });

    test('reset returns throttle to minimum', () {
      final p = RatchetPhysics();
      p.snapTo(const Offset(0.3, 0.8));
      p.reset();
      expect(p.position.dy, closeTo(-1.0, 0.001));
    });
  });

  group('FixedPhysics', () {
    test('holds position after release', () {
      final p = FixedPhysics();
      p.snapTo(const Offset(0.6, -0.4));
      p.update(target: null, dtSeconds: 0.1);
      p.update(target: null, dtSeconds: 0.1);
      expect(p.position.dx, closeTo(0.6, 0.001));
      expect(p.position.dy, closeTo(-0.4, 0.001));
    });

    test('reset returns to rest position', () {
      final p = FixedPhysics(restPosition: const Offset(0.0, -1.0));
      p.snapTo(const Offset(0.5, 0.5));
      p.reset();
      expect(p.position, const Offset(0.0, -1.0));
    });
  });
}
