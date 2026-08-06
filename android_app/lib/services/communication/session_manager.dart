// ─────────────────────────────────────────────
// PocketTX – Session Manager
// Primary coordinator owning Session ID, Handshake negotiation, HeartbeatMonitor, FailsafeEngine, and Reconnects.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'connection_state_machine.dart';
import 'heartbeat_monitor.dart';
import 'failsafe_engine.dart';
import 'transport_metrics.dart';
import 'transport/udp/udp_transport_channel.dart';
import '../../core/protocol/packet_types.dart';
import '../../core/protocol/packet_header.dart';
import '../../core/protocol/packet_builder.dart';
import '../../core/protocol/packet_codec.dart';
import '../../core/compatibility/protocol_version.dart';
import '../../core/services/logger_service.dart';
import '../../models/log_entry_model.dart';
import '../../models/channel_data.dart';

class SessionManager {
  final Ref _ref;

  late final UdpTransportChannel _transportChannel;
  late final HeartbeatMonitor _heartbeatMonitor;
  late final FailsafeEngine _failsafeEngine;
  late final TransportMetricsTracker _metricsTracker;

  int _sessionId = 0;
  int _sequenceNumber = 0;
  int _reconnectCount = 0;
  StreamSubscription? _packetSub;

  int get sessionId => _sessionId;
  FailsafeEngine get failsafeEngine => _failsafeEngine;
  TransportMetricsTracker get metricsTracker => _metricsTracker;

  SessionManager(this._ref) {
    _transportChannel = UdpTransportChannel();
    _failsafeEngine = FailsafeEngine();
    _metricsTracker = TransportMetricsTracker();
    _heartbeatMonitor = HeartbeatMonitor(onTimeout: _handleHeartbeatTimeout);
  }

  Future<bool> startSession({required String targetHost, int? port}) async {
    final notifier = _ref.read(connectionStateMachineProvider.notifier);
    notifier.transitionTo(ConnectionFsmState.connecting, deviceName: targetHost);

    _sessionId = Random().nextInt(0x7FFFFFFF); // 31-bit random Session ID
    _sequenceNumber = 0;
    _metricsTracker.reset();

    LoggerService().info(
      LogCategory.network,
      'SESSION_STARTING',
      'Starting session ID [$_sessionId] with Windows Companion ($targetHost)...',
    );

    final opened = await _transportChannel.open(host: targetHost, port: port);
    if (!opened) {
      notifier.transitionTo(ConnectionFsmState.disconnected);
      _failsafeEngine.triggerFailsafe('Failed to open transport socket');
      return false;
    }

    _packetSub?.cancel();
    _packetSub = _transportChannel.packetStream.listen(_handleIncomingRawPacket);

    // Send HELLO handshake packet
    final helloPacket = PacketBuilder.buildHello(
      sessionId: _sessionId,
      sequence: _sequenceNumber++,
      deviceName: 'PocketTX Android Client',
    );
    await _transportChannel.sendData(PacketCodec.encode(helloPacket));

    notifier.transitionTo(
      ConnectionFsmState.connected,
      type: ConnectionType.wifi,
      deviceName: targetHost,
      latencyMs: 5,
    );

    _failsafeEngine.clearFailsafe();
    _heartbeatMonitor.start();

    LoggerService().info(
      LogCategory.network,
      'SESSION_ESTABLISHED',
      'Session Established! ID [$_sessionId] connected to $targetHost.',
    );

    return true;
  }

  void transmitChannelData(ChannelData channelData) {
    final fsm = _ref.read(connectionStateMachineProvider);
    if (!fsm.isConnected || !_transportChannel.isConnected) {
      return;
    }

    final packet = PacketBuilder.buildChannelData(
      data: channelData,
      sessionId: _sessionId,
      sequence: _sequenceNumber++,
    );

    _transportChannel.sendData(PacketCodec.encode(packet));
    _metricsTracker.incrementTxPacket();
  }

  void _handleIncomingRawPacket(Uint8List rawBytes) {
    final packet = PacketCodec.decode(rawBytes);
    if (packet == null) return;

    // Reject stale packets from invalid sessions
    if (packet.header.sessionId != 0 && packet.header.sessionId != _sessionId) {
      return;
    }

    _metricsTracker.trackSequence(packet.header.sequence);
    _heartbeatMonitor.registerPulse();

    if (packet.header.type == PacketType.heartbeat) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final rtt = (now - packet.header.timestampMs).clamp(1, 999);
      _ref.read(connectionStateMachineProvider.notifier).updateLatency(rtt);
    }
  }

  void _handleHeartbeatTimeout() {
    LoggerService().warning(
      LogCategory.network,
      'HEARTBEAT_TIMEOUT',
      'Session [$_sessionId] heartbeat timed out -> triggering failsafe & reconnecting.',
    );

    _failsafeEngine.triggerFailsafe('Heartbeat timeout');
    _reconnectCount++;

    final notifier = _ref.read(connectionStateMachineProvider.notifier);
    notifier.transitionTo(ConnectionFsmState.reconnecting);

    // Auto-reconnect attempt
    Timer(const Duration(seconds: 2), () {
      final state = _ref.read(connectionStateMachineProvider);
      if (state.fsmState == ConnectionFsmState.reconnecting && state.deviceName != null) {
        startSession(targetHost: state.deviceName!);
      }
    });
  }

  Future<void> endSession({String reason = 'User disconnect'}) async {
    _heartbeatMonitor.stop();
    await _packetSub?.cancel();
    _packetSub = null;

    if (_transportChannel.isConnected) {
      // Send explicit Disconnect packet to Companion
      final discPacket = PacketBuilder.buildDisconnect(
        sessionId: _sessionId,
        sequence: _sequenceNumber++,
      );
      await _transportChannel.sendData(PacketCodec.encode(discPacket));
      await _transportChannel.close();
    }

    _failsafeEngine.triggerFailsafe(reason);
    _ref.read(connectionStateMachineProvider.notifier).transitionTo(
          ConnectionFsmState.disconnected,
          type: ConnectionType.none,
        );

    LoggerService().info(
      LogCategory.network,
      'SESSION_ENDED',
      'Session [$_sessionId] ended ($reason). Sent explicit disconnect packet.',
    );
    _sessionId = 0;
  }

  void dispose() {
    endSession(reason: 'Disposed');
  }
}

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(ref),
);
