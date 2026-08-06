// ─────────────────────────────────────────────
// PocketTX – App Lifecycle Listener
// Observes Android App Lifecycle states (paused, background, phone calls).
// Triggers clean disconnect, failsafe execution, and streaming pause.
// ─────────────────────────────────────────────

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/communication/session_manager.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';

class AppLifecycleObserver extends WidgetsBindingObserver {
  final WidgetRef ref;

  AppLifecycleObserver(this.ref);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    LoggerService().info(
      LogCategory.system,
      'LIFECYCLE_CHANGED',
      'Android Lifecycle State changed to: ${state.name.toUpperCase()}',
    );

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      LoggerService().warning(
        LogCategory.system,
        'LIFECYCLE_PAUSED',
        'App backgrounded or paused -> triggering failsafe & sending disconnect packet.',
      );
      ref.read(sessionManagerProvider).endSession(reason: 'App backgrounded (${state.name})');
    }
  }
}
