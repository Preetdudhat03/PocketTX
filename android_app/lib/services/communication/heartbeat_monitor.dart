// ─────────────────────────────────────────────
// PocketTX – Heartbeat Monitor
// Standalone monitor tracking incoming heartbeat pulses and triggering timeouts.
// ─────────────────────────────────────────────

import 'dart:async';
import '../../core/protocol/protocol_constants.dart';
import '../../core/services/logger_service.dart';
import '../../models/log_entry_model.dart';

class HeartbeatMonitor {
  Timer? _timer;
  int _lastPulseTimeMs = 0;
  final void Function() onTimeout;

  HeartbeatMonitor({required this.onTimeout});

  void start() {
    stop();
    _lastPulseTimeMs = DateTime.now().millisecondsSinceEpoch;
    _timer = Timer.periodic(
      const Duration(milliseconds: ProtocolConstants.heartbeatIntervalMs),
      (_) => _checkTimeout(),
    );
  }

  void registerPulse() {
    _lastPulseTimeMs = DateTime.now().millisecondsSinceEpoch;
  }

  void _checkTimeout() {
    if (_lastPulseTimeMs == 0) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    final elapsed = now - _lastPulseTimeMs;

    if (elapsed >= ProtocolConstants.heartbeatTimeoutMs) {
      LoggerService().warning(
        LogCategory.network,
        'HEARTBEAT_TIMEOUT',
        'No companion heartbeat received for ${elapsed}ms (timeout=${ProtocolConstants.heartbeatTimeoutMs}ms).',
      );
      stop();
      onTimeout();
    }
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    _lastPulseTimeMs = 0;
  }
}
