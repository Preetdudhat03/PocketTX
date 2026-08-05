// ─────────────────────────────────────────────
// PocketTX – App Constants
// ─────────────────────────────────────────────

abstract final class AppConstants {
  static const String appName = 'PocketTX';
  static const String appVersion = '1.0.0';
  static const int buildNumber = 1;

  // Local mode
  static const String localTestMode = 'LOCAL_TEST';
  static const String phaseLabel = 'Phase 1';

  // Profile limits
  static const int maxProfiles = 20;
  static const int defaultProfileCount = 6;

  // Log ring buffer
  static const int maxLogEntries = 200;

  // Diagnostics history (60 seconds at 10Hz = 600 samples)
  static const int diagnosticsHistorySize = 600;

  // Hive box names
  static const String profilesBox = 'profiles_box';
  static const String settingsBox = 'settings_box';
  static const String logsBox = 'logs_box';
  static const String calibrationBox = 'calibration_box';

  // SharedPreferences keys
  static const String prefActiveProfileId = 'active_profile_id';
  static const String prefThemeMode = 'theme_mode';
  static const String prefDevOverlayEnabled = 'dev_overlay_enabled';
  static const String prefUpdateRateHz = 'update_rate_hz';
  static const String prefHapticsEnabled = 'haptics_enabled';
  static const String prefStickMode = 'stick_mode';
}
