// ─────────────────────────────────────────────
// PocketTX – InputProcessor
// Pipeline: Touch → Deadband → Expo → StickMode → ChannelData
// ─────────────────────────────────────────────

import 'dart:ui';
import '../../models/channel_data.dart';
import '../../models/controller_profile.dart';
import '../../models/calibration_data.dart';
import '../utils/expo_calculator.dart';
import '../utils/deadband_calculator.dart';
import '../utils/stick_mode_mapper.dart';

/// Processes raw stick input through the full signal pipeline.
///
/// Pipeline:
///   Touch Input → Calibration → Deadband → Expo → StickMode → ChannelData
class InputProcessor {
  ControllerProfile _profile;

  InputProcessor({required ControllerProfile profile}) : _profile = profile;

  /// Update the active profile (e.g. when user changes settings).
  void updateProfile(ControllerProfile profile) => _profile = profile;

  /// Process raw 2D touch positions into a [ChannelData] packet.
  ///
  /// [leftStick]  Raw position from left gimbal touch, in [-1.0, +1.0]
  /// [rightStick] Raw position from right gimbal touch, in [-1.0, +1.0]
  /// [auxValues]  Aux channel values (Ch5–Ch8), in [-1.0, +1.0]
  ChannelData process({
    required Offset leftStick,
    required Offset rightStick,
    List<double> auxValues = const [0.0, 0.0, 0.0, 0.0],
  }) {
    // 1. Apply calibration to each axis
    final calLeft = _applyCalibration(leftStick, _profile.calibration, isLeft: true);
    final calRight = _applyCalibration(rightStick, _profile.calibration, isLeft: false);

    // 2. Map to channels based on stick mode
    final rawChannels = StickModeMapper.map(
      leftStick: StickPosition(x: calLeft.dx, y: calLeft.dy),
      rightStick: StickPosition(x: calRight.dx, y: calRight.dy),
      mode: _profile.stickMode,
    );

    // 3. Inject aux values
    final withAux = List<double>.from(rawChannels);
    for (int i = 0; i < auxValues.length && i + 4 < withAux.length; i++) {
      withAux[4 + i] = auxValues[i];
    }

    // 4. Apply deadband per channel
    final afterDeadband = DeadbandCalculator.applyAll(withAux, _profile.deadband);

    // 5. Apply expo per channel
    final afterExpo = ExpoCalculator.applyAll(afterDeadband, _profile.expo);

    return ChannelData.fromNormalized(afterExpo);
  }

  /// Apply per-axis calibration to a 2D stick offset.
  Offset _applyCalibration(
    Offset raw,
    CalibrationData cal, {
    required bool isLeft,
  }) {
    // In Mode 2: left = throttle(Y) + yaw(X), right = pitch(Y) + roll(X)
    // Calibration is applied at axis level
    final xCal = isLeft ? cal.yaw : cal.roll;
    final yCal = isLeft ? cal.throttle : cal.pitch;

    return Offset(
      xCal.apply(raw.dx),
      yCal.apply(raw.dy),
    );
  }
}
