// ─────────────────────────────────────────────
// PocketTX – App Config
// ─────────────────────────────────────────────

abstract final class AppConfig {
  // Build flags
  static const bool isDebug = bool.fromEnvironment('dart.vm.product') == false;
  static const bool enableDevOverlay = isDebug;

  // Phase 1: local-only mode
  static const bool networkEnabled = false;
  static const bool bluetoothEnabled = false;
  static const bool usbEnabled = false;
  static const bool wifiEnabled = false;

  // Phase 2 readiness flag (does NOT activate anything)
  static const bool phase2InterfacesStubbed = true;

  // Performance
  static const int defaultTickRateHz = 250;
  static const int maxTickRateHz = 1000;
  static const int physicsRateHz = 60;
  static const int diagnosticsRateHz = 10;
  static const int uiMetricsRateHz = 1;

  // Memory
  static const int targetMaxMemoryMB = 120;
}
