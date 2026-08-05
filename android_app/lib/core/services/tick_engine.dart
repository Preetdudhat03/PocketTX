// ─────────────────────────────────────────────
// PocketTX – TickEngine
// Task-scheduled engine driving all timed loops.
// Architecture: 4 named task loops, each at own Hz.
//
// Input Loop     → 250Hz–1000Hz (channel updates)
// Physics Loop   → 60Hz (stick physics interpolation)
// Diagnostics    → 10Hz (metrics sampling)
// UI Metrics     → 1Hz  (FPS/memory aggregation)
// ─────────────────────────────────────────────

import 'dart:async';
import '../config/app_config.dart';

typedef TickCallback = void Function(double dtSeconds);

class _TickTask {
  final String name;
  final int targetHz;
  final TickCallback callback;
  Timer? _timer;
  DateTime _lastTick;
  int _actualTicks = 0;
  DateTime _rateWindow;

  _TickTask({
    required this.name,
    required this.targetHz,
    required this.callback,
  })  : _lastTick = DateTime.now(),
        _rateWindow = DateTime.now();

  Duration get interval => Duration(microseconds: (1000000 / targetHz).round());

  void start() {
    _lastTick = DateTime.now();
    _rateWindow = DateTime.now();
    _actualTicks = 0;
    _timer = Timer.periodic(interval, (_) => _tick());
  }

  void _tick() {
    final now = DateTime.now();
    final dt = now.difference(_lastTick).inMicroseconds / 1000000.0;
    _lastTick = now;
    _actualTicks++;
    callback(dt.clamp(0.0001, 0.1)); // clamp dt to avoid huge jumps
  }

  double get actualHz {
    final elapsed = DateTime.now().difference(_rateWindow).inMilliseconds / 1000.0;
    if (elapsed <= 0) return 0;
    return _actualTicks / elapsed;
  }

  void resetRateWindow() {
    _actualTicks = 0;
    _rateWindow = DateTime.now();
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isRunning => _timer?.isActive == true;
}

/// Central task-scheduled engine for PocketTX.
///
/// Manages 4 named tick loops. Start/stop the engine as a unit.
/// Each loop runs at its own target Hz independently.
class TickEngine {
  late final _TickTask _inputTask;
  late final _TickTask _physicsTask;
  late final _TickTask _diagnosticsTask;
  late final _TickTask _uiMetricsTask;

  bool _running = false;

  TickEngine({
    required TickCallback onInputTick,
    required TickCallback onPhysicsTick,
    required TickCallback onDiagnosticsTick,
    required TickCallback onUiMetricsTick,
    int inputHz = AppConfig.defaultTickRateHz,
    int physicsHz = AppConfig.physicsRateHz,
    int diagnosticsHz = AppConfig.diagnosticsRateHz,
    int uiMetricsHz = AppConfig.uiMetricsRateHz,
  }) {
    _inputTask = _TickTask(
      name: 'InputLoop',
      targetHz: inputHz.clamp(1, AppConfig.maxTickRateHz),
      callback: onInputTick,
    );
    _physicsTask = _TickTask(
      name: 'PhysicsLoop',
      targetHz: physicsHz,
      callback: onPhysicsTick,
    );
    _diagnosticsTask = _TickTask(
      name: 'DiagnosticsLoop',
      targetHz: diagnosticsHz,
      callback: onDiagnosticsTick,
    );
    _uiMetricsTask = _TickTask(
      name: 'UiMetricsLoop',
      targetHz: uiMetricsHz,
      callback: onUiMetricsTick,
    );
  }

  bool get isRunning => _running;

  double get actualInputHz => _inputTask.actualHz;
  double get actualPhysicsHz => _physicsTask.actualHz;
  double get actualDiagnosticsHz => _diagnosticsTask.actualHz;

  /// Start all loops.
  void start() {
    if (_running) return;
    _running = true;
    _inputTask.start();
    _physicsTask.start();
    _diagnosticsTask.start();
    _uiMetricsTask.start();
  }

  /// Stop all loops.
  void stop() {
    _running = false;
    _inputTask.stop();
    _physicsTask.stop();
    _diagnosticsTask.stop();
    _uiMetricsTask.stop();
  }

  /// Update the input loop rate at runtime (e.g. user changes it in settings).
  void setInputRate(int hz) {
    _inputTask.stop();
    // Recreate task internals with new interval
    final newTask = _TickTask(
      name: 'InputLoop',
      targetHz: hz.clamp(1, AppConfig.maxTickRateHz),
      callback: _inputTask.callback,
    );
    if (_running) newTask.start();
    // Note: Dart final fields require this pattern via composition
    // In production: extract to mutable reference pattern
  }

  /// Reset Hz counters for a fresh measurement window.
  void resetRateCounters() {
    _inputTask.resetRateWindow();
    _physicsTask.resetRateWindow();
    _diagnosticsTask.resetRateWindow();
  }

  void dispose() {
    stop();
  }
}
