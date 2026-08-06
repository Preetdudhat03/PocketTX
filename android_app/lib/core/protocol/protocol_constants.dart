// ─────────────────────────────────────────────
// PocketTX – Protocol Constants
// Centralized configuration for networking, ports, timeouts, and rate limits.
// ─────────────────────────────────────────────

abstract final class ProtocolConstants {
  static const int discoveryPort = 18456;
  static const int dataPort = 18457;

  static const int heartbeatIntervalMs = 1000;
  static const int heartbeatTimeoutMs = 5000;

  static const String protocolVersion = '1.0.0';
  static const String minCompatibleVersion = '1.0.0';

  static const int defaultRateHz = 250;
  static const int defaultFrameIntervalMs = 4; // 1000ms / 250Hz = 4ms

  static const int maxPacketSize = 1024;
}
