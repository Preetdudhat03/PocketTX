// ─────────────────────────────────────────────
// PocketTX – Bootstrap
// Entry point for async app startup before runApp.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_ce_flutter/hive_flutter.dart';
import 'app_initializer.dart';

class Bootstrap {
  /// Run all pre-app startup tasks. Call before runApp().
  static Future<AppInitResult> run() async {
    // 1. Lock to landscape for transmitter layout
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // 2. Set system UI style (immersive mode)
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Color(0x00000000),
      systemNavigationBarColor: Color(0xFF0A0C10),
      statusBarBrightness: Brightness.dark,
      statusBarIconBrightness: Brightness.light,
    ));
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

    // 3. Initialize Hive
    await Hive.initFlutter();

    // 4. Run app initializer (storage, settings, profiles, device info)
    return AppInitializer().initialize();
  }
}
