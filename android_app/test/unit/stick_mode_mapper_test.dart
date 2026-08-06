import 'package:flutter_test/flutter_test.dart';
import 'package:pockettx_app/core/utils/stick_mode_mapper.dart';
import 'package:pockettx_app/models/controller_profile.dart';
import 'package:pockettx_app/core/constants/channel_constants.dart';

void main() {
  group('StickModeMapper', () {
    const left = StickPosition(x: 0.5, y: 0.8);  // x=yaw/roll, y=throttle/pitch
    const right = StickPosition(x: -0.3, y: 0.6);

    test('Mode 2 maps left-Y to throttle, left-X to yaw', () {
      final ch = StickModeMapper.map(
          leftStick: left, rightStick: right, mode: StickMode.mode2);
      expect(ch[ChannelConstants.chThrottle], closeTo(0.8, 0.001));
      expect(ch[ChannelConstants.chYaw], closeTo(0.5, 0.001));
      expect(ch[ChannelConstants.chPitch], closeTo(0.6, 0.001));
      expect(ch[ChannelConstants.chRoll], closeTo(-0.3, 0.001));
    });

    test('Mode 1 maps right-Y to throttle, right-X to yaw', () {
      final ch = StickModeMapper.map(
          leftStick: left, rightStick: right, mode: StickMode.mode1);
      expect(ch[ChannelConstants.chThrottle], closeTo(0.6, 0.001));
      expect(ch[ChannelConstants.chYaw], closeTo(-0.3, 0.001));
      expect(ch[ChannelConstants.chPitch], closeTo(0.8, 0.001));
      expect(ch[ChannelConstants.chRoll], closeTo(0.5, 0.001));
    });

    test('Mode 3 maps right-Y to throttle, right-X to roll', () {
      final ch = StickModeMapper.map(
          leftStick: left, rightStick: right, mode: StickMode.mode3);
      expect(ch[ChannelConstants.chThrottle], closeTo(0.6, 0.001));
      expect(ch[ChannelConstants.chRoll], closeTo(-0.3, 0.001));
    });

    test('Mode 4 maps left-Y to throttle, left-X to roll', () {
      final ch = StickModeMapper.map(
          leftStick: left, rightStick: right, mode: StickMode.mode4);
      expect(ch[ChannelConstants.chThrottle], closeTo(0.8, 0.001));
      expect(ch[ChannelConstants.chRoll], closeTo(0.5, 0.001));
    });

    test('all outputs have exactly 8 channels', () {
      for (final mode in StickMode.values) {
        final ch = StickModeMapper.map(
            leftStick: left, rightStick: right, mode: mode);
        expect(ch.length, ChannelConstants.channelCount);
      }
    });

    test('aux channels default to 0.0', () {
      final ch = StickModeMapper.map(
          leftStick: left, rightStick: right, mode: StickMode.mode2);
      for (int i = 4; i < 8; i++) {
        expect(ch[i], 0.0);
      }
    });

    test('describe returns non-empty string for all modes', () {
      for (final mode in StickMode.values) {
        expect(StickModeMapper.describe(mode), isNotEmpty);
      }
    });
  });
}
