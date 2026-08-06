// ─────────────────────────────────────────────
// PocketTX – Dependency Injection
// Riverpod provider overrides & singleton wiring.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/calibration_repository.dart';
import '../../repositories/log_repository.dart';
import '../services/logger_service.dart';
import '../services/haptic_service.dart';

/// Provides access to all singletons. Riverpod providers wrap these.
class DependencyInjection {
  static final profileRepository = ProfileRepository();
  static final settingsRepository = SettingsRepository();
  static final calibrationRepository = CalibrationRepository();
  static final logRepository = LogRepository();
  static final loggerService = LoggerService();
  static final hapticService = HapticService();
}

// ── Repository Providers ───────────────────────
final profileRepositoryProvider = Provider<ProfileRepository>(
  (_) => DependencyInjection.profileRepository,
);

final settingsRepositoryProvider = Provider<SettingsRepository>(
  (_) => DependencyInjection.settingsRepository,
);

final calibrationRepositoryProvider = Provider<CalibrationRepository>(
  (_) => DependencyInjection.calibrationRepository,
);

final logRepositoryProvider = Provider<LogRepository>(
  (_) => DependencyInjection.logRepository,
);

// ── Service Providers ──────────────────────────
final loggerServiceProvider = Provider<LoggerService>(
  (_) => DependencyInjection.loggerService,
);

final hapticServiceProvider = Provider<HapticService>(
  (_) => DependencyInjection.hapticService,
);

