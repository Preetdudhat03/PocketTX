import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/models/channel_data.dart';
import 'package:PocketTX/core/constants/channel_constants.dart';

void main() {
  group('ChannelData', () {
    test('idle() sets throttle to -1.0, others to 0.0', () {
      final idle = ChannelData.idle();
      expect(idle.throttle, -1.0);
      expect(idle.roll, 0.0);
      expect(idle.pitch, 0.0);
      expect(idle.yaw, 0.0);
    });

    test('idle() PWM: throttle = 1000us, center = 1500us', () {
      final idle = ChannelData.idle();
      expect(idle.throttlePwm, 1000);
      expect(idle.rollPwm, 1500);
    });

    test('fromNormalized creates correct PWM values', () {
      final ch = ChannelData.fromNormalized(List.filled(8, 0.0));
      for (final pwm in ch.pwm) {
        expect(pwm, 1500);
      }
    });

    test('fromNormalized clamps out-of-range values', () {
      final data = [2.0, -3.0, 0.5, 0.0, 0.0, 0.0, 0.0, 0.0];
      final ch = ChannelData.fromNormalized(data);
      expect(ch.roll, 1.0);
      expect(ch.pitch, -1.0);
    });

    test('withChannel updates single channel correctly', () {
      final idle = ChannelData.idle();
      final updated = idle.withChannel(ChannelConstants.chRoll, 0.75);
      expect(updated.roll, closeTo(0.75, 0.001));
      expect(updated.throttle, idle.throttle); // unchanged
    });

    test('normalizedToPwm: -1.0 = 1000, 0.0 = 1500, +1.0 = 2000', () {
      expect(ChannelConstants.normalizedToPwm(-1.0), 1000);
      expect(ChannelConstants.normalizedToPwm(0.0), 1500);
      expect(ChannelConstants.normalizedToPwm(1.0), 2000);
    });

    test('pwmToNormalized: 1000 = -1.0, 1500 = 0.0, 2000 = +1.0', () {
      expect(ChannelConstants.pwmToNormalized(1000), closeTo(-1.0, 0.001));
      expect(ChannelConstants.pwmToNormalized(1500), closeTo(0.0, 0.001));
      expect(ChannelConstants.pwmToNormalized(2000), closeTo(1.0, 0.001));
    });

    test('equatable: two identical channel data are equal', () {
      final a = ChannelData.fromNormalized(List.filled(8, 0.0));
      final b = ChannelData.fromNormalized(List.filled(8, 0.0));
      // normalized values are equal
      expect(a.normalized, b.normalized);
    });
  });
}
