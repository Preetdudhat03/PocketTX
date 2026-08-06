// ─────────────────────────────────────────────
// PocketTX – Failsafe Engine
// Active engine enforcing failsafe state upon signal loss or disconnect.
// ─────────────────────────────────────────────

import 'failsafe_profile.dart';
import '../../models/channel_data.dart';
import '../../core/events/event_bus.dart';
import '../../core/services/logger_service.dart';
import '../../models/log_entry_model.dart';

class FailsafeEngine {
  FailsafeProfile _profile = FailsafeProfile.simulator();
  bool _isFailsafeActive = false;

  bool get isFailsafeActive => _isFailsafeActive;
  FailsafeProfile get currentProfile => _profile;

  void setProfile(FailsafeProfile profile) {
    _profile = profile;
  }

  /// Triggers failsafe, resetting channels to safe neutral/min throttle.
  ChannelData triggerFailsafe(String reason) {
    _isFailsafeActive = true;
    final now = DateTime.now();

    LoggerService().warning(
      LogCategory.system,
      'FAILSAFE_TRIGGERED',
      'Failsafe activated [$reason] -> resetting channels to ${_profile.name} defaults.',
    );

    EventBus().fire(FailsafeTriggeredEvent(reason, now));
    return _profile.safeState;
  }

  void clearFailsafe() {
    if (_isFailsafeActive) {
      _isFailsafeActive = false;
      LoggerService().info(
        LogCategory.system,
        'FAILSAFE_CLEARED',
        'Failsafe cleared -> normal transmitter control restored.',
      );
    }
  }
}
