// ─────────────────────────────────────────────
// PocketTX – Protocol Constants
// Centralized configuration for networking, ports, timeouts, and rate limits.
// ─────────────────────────────────────────────

abstract final class ProtocolConstants {
  static const int discoveryPort = 18456; // UDP Discovery / Broadcast beaconing
  static const int dataPort = 18457;      // UDP Controller Data & Heartbeat stream
  static const int tcpPort = 18458;       // TCP Wired/USB (ADB reverse tunnel)

  static const int heartbeatIntervalMs = 1000;
  static const int heartbeatTimeoutMs = 5000;

  static const String protocolVersion = '1.0.0';
  static const String minCompatibleVersion = '1.0.0';

  static const int defaultRateHz = 250;
  static const int defaultFrameIntervalMs = 4; // 1000ms / 250Hz = 4ms

  static const int maxPacketSize = 1024;
}
