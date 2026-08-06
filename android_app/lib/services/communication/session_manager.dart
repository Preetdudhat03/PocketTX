// ─────────────────────────────────────────────
// PocketTX – Session Manager
// Active connection session controller orchestrating handshakes, continuous channel stream,
// heartbeats, sequence validation, and metrics tracking.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:math';
import 'dart:typed_data';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/compatibility/protocol_version.dart';
import '../../core/protocol/packet_builder.dart';
import '../../core/protocol/packet_codec.dart';
import '../../core/protocol/protocol_constants.dart';
import '../../core/services/logger_service.dart';
import '../../core/state/channel_state.dart';
import '../../models/channel_data.dart';
import '../../models/log_entry_model.dart';
import 'connection_state_machine.dart';
import 'failsafe_engine.dart';
import 'heartbeat_monitor.dart';
import 'transport_metrics.dart';
import 'transport/udp/udp_transport_channel.dart';

class SessionManager {
  final Ref _ref;
  late final UdpTransportChannel _transportChannel;
  late final FailsafeEngine _failsafeEngine;
  late final TransportMetricsTracker _metricsTracker;
  late final HeartbeatMonitor _heartbeatMonitor;

  int _sessionId = 0;
  int _sequenceNumber = 0;
  StreamSubscription? _packetSub;
  Timer? _transmissionTimer;

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

    String realDeviceName = 'PocketTX Phone';
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      realDeviceName = '${androidInfo.manufacturer.toUpperCase()} ${androidInfo.model}';
    } catch (_) {}

    final helloPacket = PacketBuilder.buildHello(
      sessionId: _sessionId,
      sequence: _sequenceNumber++,
      deviceName: realDeviceName,
    );
    final encodedHello = PacketCodec.encode(helloPacket);

    // Strict Handshake Verification: Wait for ACK response from Windows Companion
    final completer = Completer<bool>();
    StreamSubscription? ackSubscription;
    ackSubscription = _transportChannel.packetStream.listen((rawBytes) {
      final packet = PacketCodec.decode(rawBytes);
      if (packet != null && (packet.header.type == PacketType.ack || packet.header.type == PacketType.hello)) {
        if (!completer.isCompleted) {
          completer.complete(true);
        }
      }
    });

    await _transportChannel.sendData(encodedHello);

    final ackReceived = await completer.future.timeout(
      const Duration(milliseconds: 2000),
      onTimeout: () => false,
    );
    await ackSubscription.cancel();

    if (!ackReceived) {
      notifier.transitionTo(ConnectionFsmState.disconnected);
      await _transportChannel.close();
      LoggerService().warning(
        LogCategory.network,
        'SESSION_HANDSHAKE_FAILED',
        'No ACK response received from Windows Companion ($targetHost). Host unreachable.',
      );
      return false;
    }

    notifier.transitionTo(
      ConnectionFsmState.connected,
      type: targetHost == '127.0.0.1' ? ConnectionType.usb : ConnectionType.wifi,
      deviceName: targetHost,
      latencyMs: targetHost == '127.0.0.1' ? 1 : 5,
    );

    _failsafeEngine.clearFailsafe();
    _heartbeatMonitor.start();

    // Auto-start continuous 100Hz background UDP channel packet transmission timer
    _transmissionTimer?.cancel();
    _transmissionTimer = Timer.periodic(const Duration(milliseconds: 10), (_) {
      final currentChannels = _ref.read(channelStateProvider);
      transmitChannelData(currentChannels);
    });

    LoggerService().info(
      LogCategory.network,
      'SESSION_ESTABLISHED',
      'Session Established! ID [$_sessionId] streaming continuous telemetry to $targetHost.',
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
      'Heartbeat timeout detected from Windows Companion!',
    );
    _failsafeEngine.triggerFailsafe('Heartbeat timeout');
  }

  Future<void> endSession() async {
    _transmissionTimer?.cancel();
    _transmissionTimer = null;

    if (_transportChannel.isConnected) {
      final disconnectPacket = PacketBuilder.buildDisconnect(
        sessionId: _sessionId,
        sequence: _sequenceNumber++,
      );
      await _transportChannel.sendData(PacketCodec.encode(disconnectPacket));
      await _transportChannel.close();
    }

    _heartbeatMonitor.stop();
    _packetSub?.cancel();

    _ref.read(connectionStateMachineProvider.notifier).transitionTo(ConnectionFsmState.disconnected);
    LoggerService().info(
      LogCategory.network,
      'SESSION_ENDED',
      'Session ID [$_sessionId] cleanly terminated.',
    );
  }

  void dispose() {
    endSession();
    _transportChannel.dispose();
    _heartbeatMonitor.stop();
  }
}

final sessionManagerProvider = Provider<SessionManager>(
  (ref) => SessionManager(ref),
);
