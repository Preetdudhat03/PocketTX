// ─────────────────────────────────────────────
// PocketTX – Model Versions
// Tracks schema version for each model type.
// Enables safe migration when models evolve.
// ─────────────────────────────────────────────

/// Model schema versions — increment when a model's serialized structure changes.
/// Used to detect and migrate stale persisted data in Phase 2+.
abstract final class ModelVersions {
  static const int channelData = 1;
  static const int controllerProfile = 1;
  static const int calibrationData = 1;
  static const int appSettings = 1;
  static const int diagnosticMetrics = 1;
  static const int logEntry = 1;
  static const int deviceInfo = 1;

  /// Returns true if the stored [storedVersion] matches the current schema version.
  static bool isCurrent(int storedVersion, int currentVersion) =>
      storedVersion == currentVersion;

  /// Returns true if a migration is needed.
  static bool needsMigration(int storedVersion, int currentVersion) =>
      storedVersion < currentVersion;
}

/// SimulatorType – used to select target simulator or ground truth in diagnostics.
/// Must remain symmetric with Windows Companion SimulatorType enum.
enum SimulatorType {
  none,
  velocidrone,
  fpvSkydive,
  picaSim,
  liftoff,
  orqa,
}
