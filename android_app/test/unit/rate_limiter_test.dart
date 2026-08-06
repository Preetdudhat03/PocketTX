import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/core/utils/rate_limiter.dart';

void main() {
  group('RateLimiter', () {
    test('enforces 250Hz rate processing window', () {
      final limiter = RateLimiter(targetHz: 250);

      // First tick should pass
      expect(limiter.shouldProcess(), isTrue);

      // Immediate second tick should be rate-limited (false)
      expect(limiter.shouldProcess(), isFalse);
    });

    test('resets rate limiter timer correctly', () {
      final limiter = RateLimiter(targetHz: 250);
      expect(limiter.shouldProcess(), isTrue);
      limiter.reset();
      expect(limiter.shouldProcess(), isTrue);
    });
  });
}
