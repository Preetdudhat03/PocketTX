import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('enforces 250Hz rate processing window', () {
      final limiter = RateLimiter(targetHz: 250); // 4000us window

      // T0: First tick should pass
      expect(limiter.shouldProcess(1000000), isTrue);

      // T0 + 1000us: Immediate second tick within 4000us window should be rate-limited (false)
      expect(limiter.shouldProcess(1001000), isFalse);

      // T0 + 4000us: Next tick after 4000us should pass
      expect(limiter.shouldProcess(1004000), isTrue);
    });

    test('resets rate limiter timer correctly', () {
      final limiter = RateLimiter(targetHz: 250);
      expect(limiter.shouldProcess(1000000), isTrue);
      limiter.reset();
      expect(limiter.shouldProcess(1000100), isTrue);
    });
  });
}
