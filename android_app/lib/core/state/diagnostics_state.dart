// ─────────────────────────────────────────────
// PocketTX – Diagnostics State (Riverpod)
// Tracks metrics + 60-second rolling history.
// ─────────────────────────────────────────────

import 'dart:collection';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/diagnostic_metrics.dart';
import '../../models/device_info.dart';
import '../constants/app_constants.dart';

class DiagnosticsState {
  final DiagnosticMetrics latest;
  final UnmodifiableListView<DiagnosticMetrics> history;
  final DeviceInfo deviceInfo;
  final bool devOverlayVisible;

  DiagnosticsState({
    required this.latest,
    required List<DiagnosticMetrics> history,
    required this.deviceInfo,
    this.devOverlayVisible = false,
  }) : history = UnmodifiableListView(history);

  DiagnosticsState copyWith({
    DiagnosticMetrics? latest,
    List<DiagnosticMetrics>? history,
    DeviceInfo? deviceInfo,
    bool? devOverlayVisible,
  }) =>
      DiagnosticsState(
        latest: latest ?? this.latest,
        history: history ?? this.history.toList(),
        deviceInfo: deviceInfo ?? this.deviceInfo,
        devOverlayVisible: devOverlayVisible ?? this.devOverlayVisible,
      );
}

class DiagnosticsNotifier extends StateNotifier<DiagnosticsState> {
  final Queue<DiagnosticMetrics> _history = Queue();

  DiagnosticsNotifier()
      : super(DiagnosticsState(
          latest: DiagnosticMetrics.empty(),
          history: [],
          deviceInfo: DeviceInfo.unknown(),
        ));

  void updateMetrics(DiagnosticMetrics metrics) {
    // Maintain 60-second rolling history
    // At 10Hz, 600 samples = 60 seconds
    if (_history.length >= AppConstants.diagnosticsHistorySize) {
      _history.removeFirst();
    }
    _history.addLast(metrics);

    state = state.copyWith(
      latest: metrics,
      history: _history.toList(),
    );
  }

  void setDeviceInfo(DeviceInfo info) {
    state = state.copyWith(deviceInfo: info);
  }

  void toggleDevOverlay() {
    state = state.copyWith(devOverlayVisible: !state.devOverlayVisible);
  }

  void setDevOverlay(bool visible) {
    state = state.copyWith(devOverlayVisible: visible);
  }
}

final diagnosticsProvider =
    StateNotifierProvider<DiagnosticsNotifier, DiagnosticsState>(
  (ref) => DiagnosticsNotifier(),
);
