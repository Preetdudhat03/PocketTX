// ─────────────────────────────────────────────
// PocketTX – CalibrationData Model
// Stores per-axis calibration for all 4 stick axes.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';

/// Calibration settings for a single stick axis.
class AxisCalibration extends Equatable {
  final double center;  // normalized center position (typically 0.0)
  final double min;     // normalized minimum (-1.0)
  final double max;     // normalized maximum (+1.0)
  final bool reversed;  // invert axis output
  final double trim;    // trim offset applied after calibration (-0.1 to +0.1)

  const AxisCalibration({
    this.center = 0.0,
    this.min = -1.0,
    this.max = 1.0,
    this.reversed = false,
    this.trim = 0.0,
  });

  /// Apply calibration to a raw normalized input value.
  double apply(double rawNormalized) {
    // Scale to calibrated range
    double value = rawNormalized.clamp(min, max);

    // Apply center offset
    if (value > center) {
      value = (value - center) / (max - center);
    } else {
      value = (value - center) / (center - min);
    }

    // Apply trim
    value = (value + trim).clamp(-1.0, 1.0);

    // Apply reverse
    return reversed ? -value : value;
  }

  AxisCalibration copyWith({
    double? center,
    double? min,
    double? max,
    bool? reversed,
    double? trim,
  }) =>
      AxisCalibration(
        center: center ?? this.center,
        min: min ?? this.min,
        max: max ?? this.max,
        reversed: reversed ?? this.reversed,
        trim: trim ?? this.trim,
      );

  Map<String, dynamic> toJson() => {
        'center': center,
        'min': min,
        'max': max,
        'reversed': reversed,
        'trim': trim,
      };

  factory AxisCalibration.fromJson(Map<String, dynamic> json) =>
      AxisCalibration(
        center: (json['center'] as num?)?.toDouble() ?? 0.0,
        min: (json['min'] as num?)?.toDouble() ?? -1.0,
        max: (json['max'] as num?)?.toDouble() ?? 1.0,
        reversed: json['reversed'] as bool? ?? false,
        trim: (json['trim'] as num?)?.toDouble() ?? 0.0,
      );

  @override
  List<Object?> get props => [center, min, max, reversed, trim];
}

/// Calibration data for all 4 stick axes.
/// Schema version: 1 (see ModelVersions.calibrationData)
class CalibrationData extends Equatable {
  final AxisCalibration roll;
  final AxisCalibration pitch;
  final AxisCalibration throttle;
  final AxisCalibration yaw;
  final int schemaVersion;

  const CalibrationData({
    this.roll = const AxisCalibration(),
    this.pitch = const AxisCalibration(),
    this.throttle = const AxisCalibration(center: -1.0, min: -1.0),
    this.yaw = const AxisCalibration(),
    this.schemaVersion = 1,
  });

  /// Returns default factory calibration (no corrections applied).
  factory CalibrationData.defaults() => const CalibrationData();

  CalibrationData copyWith({
    AxisCalibration? roll,
    AxisCalibration? pitch,
    AxisCalibration? throttle,
    AxisCalibration? yaw,
  }) =>
      CalibrationData(
        roll: roll ?? this.roll,
        pitch: pitch ?? this.pitch,
        throttle: throttle ?? this.throttle,
        yaw: yaw ?? this.yaw,
        schemaVersion: schemaVersion,
      );

  Map<String, dynamic> toJson() => {
        'roll': roll.toJson(),
        'pitch': pitch.toJson(),
        'throttle': throttle.toJson(),
        'yaw': yaw.toJson(),
        'schemaVersion': schemaVersion,
      };

  factory CalibrationData.fromJson(Map<String, dynamic> json) =>
      CalibrationData(
        roll: AxisCalibration.fromJson(json['roll'] as Map<String, dynamic>? ?? {}),
        pitch: AxisCalibration.fromJson(json['pitch'] as Map<String, dynamic>? ?? {}),
        throttle: AxisCalibration.fromJson(json['throttle'] as Map<String, dynamic>? ?? {}),
        yaw: AxisCalibration.fromJson(json['yaw'] as Map<String, dynamic>? ?? {}),
        schemaVersion: json['schemaVersion'] as int? ?? 1,
      );

  @override
  List<Object?> get props => [roll, pitch, throttle, yaw, schemaVersion];
}
