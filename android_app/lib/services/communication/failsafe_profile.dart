// ─────────────────────────────────────────────
// PocketTX – Failsafe Profile & Failsafe Engine
// Defines failsafe behavior for signal loss, timeouts, and disconnects.
// ─────────────────────────────────────────────

import '../../models/channel_data.dart';
import '../../core/events/event_bus.dart';

class FailsafeTriggeredEvent extends AppEvent {
  final String reason;
  final DateTime timestamp;

  const FailsafeTriggeredEvent(this.reason, this.timestamp);
}

class FailsafeProfile {
  final String name;
  final ChannelData safeState;

  const FailsafeProfile({
    required this.name,
    required this.safeState,
  });

  /// Default simulator failsafe profile: throttle minimum, rest center.
  factory FailsafeProfile.simulator() {
    return FailsafeProfile(
      name: 'Simulator Failsafe',
      safeState: ChannelData.idle(),
    );
  }
}
