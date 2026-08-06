// ─────────────────────────────────────────────
// PocketTX – ChannelData Model
// Symmetric with Windows Companion ChannelData.
// Holds normalized + PWM values for 8 channels.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';
import '../core/constants/channel_constants.dart';

/// Immutable snapshot of all 8 RC channel values.
/// Schema version: 1 (see ModelVersions.channelData)
class ChannelData extends Equatable {
  final List<double> normalized; // 8 values, -1.0 to +1.0
  final List<int> pwm;           // 8 values, 1000us to 2000us
  final DateTime timestamp;
  final int schemaVersion;

  const ChannelData._({
    required this.normalized,
    required this.pwm,
    required this.timestamp,
    this.schemaVersion = 1,
  });

  /// Creates a ChannelData with all channels at center/idle.
  factory ChannelData.idle() {
    final List<double> norm = List.filled(ChannelConstants.channelCount, 0.0);
    // Throttle starts at min, not center
    norm[ChannelConstants.chThrottle] = -1.0;
    return ChannelData._(
      normalized: List.unmodifiable(norm),
      pwm: List.unmodifiable(norm.map(ChannelConstants.normalizedToPwm).toList()),
      timestamp: DateTime.now(),
    );
  }

  /// Creates ChannelData from normalized values list.
  factory ChannelData.fromNormalized(List<double> normalized) {
    assert(normalized.length == ChannelConstants.channelCount);
    final clamped = normalized
        .map((v) => v.clamp(ChannelConstants.normalizedMin, ChannelConstants.normalizedMax))
        .toList();
    return ChannelData._(
      normalized: List.unmodifiable(clamped),
      pwm: List.unmodifiable(clamped.map(ChannelConstants.normalizedToPwm).toList()),
      timestamp: DateTime.now(),
    );
  }

  /// Creates ChannelData from PWM values list.
  factory ChannelData.fromPwm(List<int> pwm) {
    assert(pwm.length == ChannelConstants.channelCount);
    final clampedPwm = pwm.map((p) => p.clamp(1000, 2000)).toList();
    final norm = clampedPwm.map(ChannelConstants.pwmToNormalized).toList();
    return ChannelData._(
      normalized: List.unmodifiable(norm),
      pwm: List.unmodifiable(clampedPwm),
      timestamp: DateTime.now(),
    );
  }

  /// Returns a copy with updated [index] channel value.
  ChannelData withChannel(int index, double normalizedValue) {
    assert(index >= 0 && index < ChannelConstants.channelCount);
    final updated = List<double>.from(normalized);
    updated[index] = normalizedValue.clamp(-1.0, 1.0);
    return ChannelData.fromNormalized(updated);
  }

  double get roll => normalized[ChannelConstants.chRoll];
  double get pitch => normalized[ChannelConstants.chPitch];
  double get throttle => normalized[ChannelConstants.chThrottle];
  double get yaw => normalized[ChannelConstants.chYaw];
  double get aux1 => normalized[ChannelConstants.chAux1];
  double get aux2 => normalized[ChannelConstants.chAux2];
  double get aux3 => normalized[ChannelConstants.chAux3];
  double get aux4 => normalized[ChannelConstants.chAux4];

  int get rollPwm => pwm[ChannelConstants.chRoll];
  int get pitchPwm => pwm[ChannelConstants.chPitch];
  int get throttlePwm => pwm[ChannelConstants.chThrottle];
  int get yawPwm => pwm[ChannelConstants.chYaw];

  Map<String, dynamic> toJson() => {
        'normalized': normalized,
        'pwm': pwm,
        'timestamp': timestamp.toIso8601String(),
        'schemaVersion': schemaVersion,
      };

  @override
  List<Object?> get props => [normalized, pwm, timestamp];

  @override
  String toString() =>
      'ChannelData(R:${roll.toStringAsFixed(2)} '
      'P:${pitch.toStringAsFixed(2)} '
      'T:${throttle.toStringAsFixed(2)} '
      'Y:${yaw.toStringAsFixed(2)})';
}
