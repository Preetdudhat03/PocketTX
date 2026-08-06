// ─────────────────────────────────────────────
// PocketTX – Companion Service
// Primary entry service orchestrating SessionManager, RateLimiter, and UdpDiscoveryService.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'session_manager.dart';
import 'udp_discovery_service.dart';
import 'connection_state_machine.dart';
import '../../core/utils/rate_limiter.dart';
import '../../models/channel_data.dart';

class CompanionService {
  final Ref _ref;
  final RateLimiter _rateLimiter;
  final UdpDiscoveryService _discoveryService;

  CompanionService(this._ref)
      : _rateLimiter = RateLimiter(targetHz: 250),
        _discoveryService = UdpDiscoveryService();

  UdpDiscoveryService get discoveryService => _discoveryService;

  Future<List<CompanionDeviceInfo>> scanDevices() {
    _ref.read(connectionStateMachineProvider.notifier).transitionTo(ConnectionFsmState.scanning);
    return _discoveryService.scanForCompanions();
  }

  Future<bool> connectToCompanion(CompanionDeviceInfo device) {
    return _ref.read(sessionManagerProvider).startSession(
          targetHost: device.ipAddress,
          port: device.port,
        );
  }

  Future<void> disconnect() {
    return _ref.read(sessionManagerProvider).endSession();
  }

  void processChannelData(ChannelData channelData) {
    if (_rateLimiter.shouldProcess()) {
      _ref.read(sessionManagerProvider).transmitChannelData(channelData);
    }
  }
}

final companionServiceProvider = Provider<CompanionService>(
  (ref) => CompanionService(ref),
);
