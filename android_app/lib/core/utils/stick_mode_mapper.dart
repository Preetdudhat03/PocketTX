// ─────────────────────────────────────────────
// PocketTX – Stick Mode Mapper
// Maps 2D stick positions to channel outputs
// for Mode 1, 2, 3, 4 conventions.
// 100% test coverage required.
// ─────────────────────────────────────────────

import '../../models/controller_profile.dart';
import '../constants/channel_constants.dart';

/// Raw 2D stick position from touch input.
class StickPosition {
  final double x; // horizontal, -1.0 (left) to +1.0 (right)
  final double y; // vertical, -1.0 (down) to +1.0 (up)

  const StickPosition({required this.x, required this.y});
  const StickPosition.center() : x = 0.0, y = 0.0;
  const StickPosition.idle()
      : x = 0.0,
        y = -1.0; // throttle idle = fully down
}

/// Maps left and right 2D stick positions to 8-channel normalized outputs
/// based on the selected [StickMode].
///
/// Mode 2 (default, most popular):
///   Left Stick:  Y = Throttle, X = Yaw
///   Right Stick: Y = Pitch,    X = Roll
abstract final class StickModeMapper {
  /// Returns a 8-element normalized channel list for the given stick positions.
  static List<double> map({
    required StickPosition leftStick,
    required StickPosition rightStick,
    required StickMode mode,
  }) {
    final ch = List<double>.filled(ChannelConstants.channelCount, 0.0);

    switch (mode) {
      case StickMode.mode1:
        // Right: Throttle (Y) + Yaw (X)
        // Left:  Pitch (Y)    + Roll (X)
        ch[ChannelConstants.chRoll] = leftStick.x;
        ch[ChannelConstants.chPitch] = leftStick.y;
        ch[ChannelConstants.chThrottle] = rightStick.y;
        ch[ChannelConstants.chYaw] = rightStick.x;

      case StickMode.mode2:
        // Left:  Throttle (Y) + Yaw (X)
        // Right: Pitch (Y)    + Roll (X)
        ch[ChannelConstants.chRoll] = rightStick.x;
        ch[ChannelConstants.chPitch] = rightStick.y;
        ch[ChannelConstants.chThrottle] = leftStick.y;
        ch[ChannelConstants.chYaw] = leftStick.x;

      case StickMode.mode3:
        // Right: Throttle (Y) + Roll (X)
        // Left:  Pitch (Y)    + Yaw (X)
        ch[ChannelConstants.chRoll] = rightStick.x;
        ch[ChannelConstants.chPitch] = leftStick.y;
        ch[ChannelConstants.chThrottle] = rightStick.y;
        ch[ChannelConstants.chYaw] = leftStick.x;

      case StickMode.mode4:
        // Left:  Throttle (Y) + Roll (X)
        // Right: Pitch (Y)    + Yaw (X)
        ch[ChannelConstants.chRoll] = leftStick.x;
        ch[ChannelConstants.chPitch] = rightStick.y;
        ch[ChannelConstants.chThrottle] = leftStick.y;
        ch[ChannelConstants.chYaw] = rightStick.x;
    }

    // Aux channels default to center (0.0)
    // They are controlled independently by switches/buttons.
    return ch;
  }

  /// Returns a human-readable description of the stick mode layout.
  static String describe(StickMode mode) {
    return switch (mode) {
      StickMode.mode1 => 'Mode 1 – Left: Pitch+Roll | Right: Throttle+Yaw',
      StickMode.mode2 => 'Mode 2 – Left: Throttle+Yaw | Right: Pitch+Roll',
      StickMode.mode3 => 'Mode 3 – Left: Pitch+Yaw | Right: Throttle+Roll',
      StickMode.mode4 => 'Mode 4 – Left: Throttle+Roll | Right: Pitch+Yaw',
    };
  }
}
