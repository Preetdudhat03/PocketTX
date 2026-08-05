// ─────────────────────────────────────────────
// PocketTX – Entry Point
// Minimal main.dart: delegates startup to Bootstrap.
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/bootstrap/bootstrap.dart';
import 'core/bootstrap/app_initializer.dart';
import 'core/state/app_state.dart';
import 'core/state/theme_state.dart';
import 'core/state/diagnostics_state.dart';
import 'core/services/haptic_service.dart';
import 'models/app_settings.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Run all pre-app startup
  final initResult = await Bootstrap.run();

  runApp(
    ProviderScope(
      overrides: const [],
      child: _AppBootstrapper(
        initResult: initResult,
      ),
    ),
  );
}

/// Injects initialization results into Riverpod state before rendering the app.
class _AppBootstrapper extends ConsumerStatefulWidget {
  final AppInitResult initResult;
  const _AppBootstrapper({required this.initResult});

  @override
  ConsumerState<_AppBootstrapper> createState() => _AppBootstrapperState();
}

class _AppBootstrapperState extends ConsumerState<_AppBootstrapper> {
  @override
  void initState() {
    super.initState();
    // Inject settings into state after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = widget.initResult.settings;
      ref.read(appStateProvider.notifier).initialize(settings);
      ref.read(themeStateProvider.notifier).setMode(settings.themeMode);
      ref.read(diagnosticsProvider.notifier).setDeviceInfo(widget.initResult.deviceInfo);
      HapticService().setEnabled(settings.hapticsEnabled);
    });
  }

  @override
  Widget build(BuildContext context) => const PocketTxApp();
}
