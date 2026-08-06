// ─────────────────────────────────────────────
// PocketTX – Transport Metrics
// Tracks telemetry metrics: Packets/sec, Latency, Packet Loss %, Dropped, Out-of-Order, and Duplicates.
// ─────────────────────────────────────────────

import '../../core/events/event_bus.dart';

class PacketLossEvent extends AppEvent {
  final int expectedSequence;
  final int receivedSequence;
  final int droppedCount;

  const PacketLossEvent({
    required this.expectedSequence,
    required this.receivedSequence,
    required this.droppedCount,
  });
}

class TransportMetricsData {
  final int packetsPerSecond;
  final int latencyMs;
  final double packetLossPercentage;
  final int droppedPackets;
  final int outOfOrderPackets;
  final int duplicatePackets;
  final int reconnectCount;

  const TransportMetricsData({
    this.packetsPerSecond = 0,
    this.latencyMs = 0,
    this.packetLossPercentage = 0.0,
    this.droppedPackets = 0,
    this.outOfOrderPackets = 0,
    this.duplicatePackets = 0,
    this.reconnectCount = 0,
  });
}

class TransportMetricsTracker {
  int _lastSeq = -1;
  int _totalExpectedPackets = 0;
  int _droppedCount = 0;
  int _outOfOrderCount = 0;
  int _duplicateCount = 0;

  int _txPacketsInLastSec = 0;
  int _txPps = 0;

  void trackSequence(int seq) {
    if (_lastSeq == -1) {
      _lastSeq = seq;
      _totalExpectedPackets = 1;
      return;
    }

    if (seq == _lastSeq) {
      _duplicateCount++;
    } else if (seq < _lastSeq) {
      _outOfOrderCount++;
    } else if (seq > _lastSeq + 1) {
      final gap = seq - (_lastSeq + 1);
      _droppedCount += gap;
      _totalExpectedPackets += (gap + 1);
      EventBus().fire(PacketLossEvent(
        expectedSequence: _lastSeq + 1,
        receivedSequence: seq,
        droppedCount: gap,
      ));
      _lastSeq = seq;
    } else {
      _totalExpectedPackets++;
      _lastSeq = seq;
    }
  }

  void incrementTxPacket() {
    _txPacketsInLastSec++;
  }

  TransportMetricsData computeSnapshot({required int currentLatencyMs, int reconnects = 0}) {
    _txPps = _txPacketsInLastSec;
    _txPacketsInLastSec = 0;

    final lossPct = _totalExpectedPackets > 0
        ? (_droppedCount / _totalExpectedPackets) * 100.0
        : 0.0;

    return TransportMetricsData(
      packetsPerSecond: _txPps,
      latencyMs: currentLatencyMs,
      packetLossPercentage: lossPct,
      droppedPackets: _droppedCount,
      outOfOrderPackets: _outOfOrderCount,
      duplicatePackets: _duplicateCount,
      reconnectCount: reconnects,
    );
  }

  void reset() {
    _lastSeq = -1;
    _totalExpectedPackets = 0;
    _droppedCount = 0;
    _outOfOrderCount = 0;
    _duplicateCount = 0;
    _txPacketsInLastSec = 0;
    _txPps = 0;
  }
}
