// ─────────────────────────────────────────────
// PocketTX – Rate Limiter
// Standalone frequency rate limiter for packet transmission (250Hz default = 4ms interval).
// ─────────────────────────────────────────────

class RateLimiter {
  final int targetHz;
  final int _intervalMicroseconds;
  int _lastTickMicroseconds = 0;

  RateLimiter({this.targetHz = 250})
      : _intervalMicroseconds = (1000000 / targetHz).round();

  /// Returns true if enough time has passed to send the next packet.
  bool shouldProcess([int? nowMicroseconds]) {
    final now = nowMicroseconds ?? DateTime.now().microsecondsSinceEpoch;
    if (_lastTickMicroseconds == 0 || (now - _lastTickMicroseconds >= _intervalMicroseconds)) {
      _lastTickMicroseconds = now;
      return true;
    }
    return false;
  }

  void reset() {
    _lastTickMicroseconds = 0;
  }
}
