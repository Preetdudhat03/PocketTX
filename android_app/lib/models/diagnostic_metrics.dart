// ─────────────────────────────────────────────
// PocketTX – DiagnosticMetrics Model
// Symmetric with Windows Companion DiagnosticMetrics.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';

class DiagnosticMetrics extends Equatable {
  final double fps;
  final double frameTimeMs;
  final int updateRateHz;
  final double actualUpdateRateHz;
  final int memoryUsageMb;
  final int latencyMs;
  final DateTime timestamp;
  final int schemaVersion;

  const DiagnosticMetrics({
    this.fps = 0.0,
    this.frameTimeMs = 0.0,
    this.updateRateHz = 0,
    this.actualUpdateRateHz = 0.0,
    this.memoryUsageMb = 0,
    this.latencyMs = 0,
    required this.timestamp,
    this.schemaVersion = 1,
  });

  factory DiagnosticMetrics.empty() =>
      DiagnosticMetrics(timestamp: DateTime.now());

  DiagnosticMetrics copyWith({
    double? fps,
    double? frameTimeMs,
    int? updateRateHz,
    double? actualUpdateRateHz,
    int? memoryUsageMb,
    int? latencyMs,
  }) =>
      DiagnosticMetrics(
        fps: fps ?? this.fps,
        frameTimeMs: frameTimeMs ?? this.frameTimeMs,
        updateRateHz: updateRateHz ?? this.updateRateHz,
        actualUpdateRateHz: actualUpdateRateHz ?? this.actualUpdateRateHz,
        memoryUsageMb: memoryUsageMb ?? this.memoryUsageMb,
        latencyMs: latencyMs ?? this.latencyMs,
        timestamp: DateTime.now(),
        schemaVersion: schemaVersion,
      );

  @override
  List<Object?> get props => [
        fps, frameTimeMs, updateRateHz,
        actualUpdateRateHz, memoryUsageMb, latencyMs, timestamp,
      ];

  @override
  String toString() =>
      'Diag(fps:${fps.toStringAsFixed(1)} '
      'frame:${frameTimeMs.toStringAsFixed(2)}ms '
      'rate:${actualUpdateRateHz.toStringAsFixed(0)}Hz '
      'mem:${memoryUsageMb}MB)';
}
