// ─────────────────────────────────────────────
// PocketTX – App Initializer
// Orchestrates startup: storage, defaults, device info.
// ─────────────────────────────────────────────

import 'package:device_info_plus/device_info_plus.dart';
import '../../models/device_info.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';
import '../../repositories/profile_repository.dart';
import '../../repositories/settings_repository.dart';
import '../../repositories/calibration_repository.dart';
import '../../repositories/log_repository.dart';
import '../../models/app_settings.dart';

class AppInitResult {
  final AppSettings settings;
  final DeviceInfo deviceInfo;
  final bool success;
  final String? errorMessage;

  const AppInitResult({
    required this.settings,
    required this.deviceInfo,
    this.success = true,
    this.errorMessage,
  });
}

class AppInitializer {
  final _log = LoggerService();

  Future<AppInitResult> initialize() async {
    _log.info(LogCategory.system, 'AppInitializer.initialize', 'Starting PocketTX initialization');

    try {
      // 1. Init repositories
      await ProfileRepository().init();
      await SettingsRepository().init();
      await CalibrationRepository().init();
      await LogRepository().init();

      // 2. Load settings (or defaults)
      final settings = await SettingsRepository().load();
      _log.info(LogCategory.system, 'AppInitializer.settings',
          'Loaded settings: theme=${settings.themeMode.name}, rate=${settings.updateRateHz}Hz');

      // 3. Ensure default profiles exist
      await ProfileRepository().loadAll();
      _log.info(LogCategory.system, 'AppInitializer.profiles', 'Profiles ready');

      // 4. Collect device info
      final deviceInfo = await _collectDeviceInfo();
      _log.info(LogCategory.system, 'AppInitializer.device',
          'Device: ${deviceInfo.displayName}, ${deviceInfo.androidVersion}');

      _log.info(LogCategory.system, 'AppInitializer.complete', 'Initialization complete ✓');

      return AppInitResult(settings: settings, deviceInfo: deviceInfo);
    } catch (e, st) {
      _log.error(LogCategory.system, 'AppInitializer.error',
          'Init failed: $e', metadata: {'stackTrace': st.toString()});
      return AppInitResult(
        settings: const AppSettings(),
        deviceInfo: DeviceInfo.unknown(),
        success: false,
        errorMessage: e.toString(),
      );
    }
  }

  Future<DeviceInfo> _collectDeviceInfo() async {
    try {
      final plugin = DeviceInfoPlugin();
      final android = await plugin.androidInfo;
      return DeviceInfo(
        manufacturer: android.manufacturer,
        model: android.model,
        androidVersion: android.version.release,
        sdkInt: android.version.sdkInt,
        isPhysicalDevice: android.isPhysicalDevice,
      );
    } catch (_) {
      return DeviceInfo.unknown();
    }
  }
}
