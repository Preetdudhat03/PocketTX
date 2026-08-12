import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:PocketTX/core/protocol/binary_channel_encoder.dart';

void main() {
  group('BinaryChannelEncoder', () {
    test('encodes 8-channel PWM values into 16-byte buffer', () {
      final pwmInput = [1500, 1500, 1000, 2000, 1200, 1800, 1400, 1600];
      final encoded = BinaryChannelEncoder.encodePwm(pwmInput);

      expect(encoded.length, equals(16));

      final decoded = BinaryChannelEncoder.decodePwm(encoded);
      expect(decoded.pwm, equals(pwmInput));
    });

    test('clamps out-of-range PWM values to [1000, 2000]', () {
      final outOfRangePwm = [900, 2100, 1500, 1500, 1500, 1500, 1500, 1500];
      final encoded = BinaryChannelEncoder.encodePwm(outOfRangePwm);
      final decoded = BinaryChannelEncoder.decodePwm(encoded);

      expect(decoded.pwm[0], equals(1000));
      expect(decoded.pwm[1], equals(2000));
    });

    test('decodes short buffer safely into idle ChannelData', () {
      final shortBuffer = Uint8List(5);
      final decoded = BinaryChannelEncoder.decodePwm(shortBuffer);
      expect(decoded.pwm[2], equals(1000)); // idle throttle is 1000µs
      expect(decoded.pwm[0], equals(1500)); // idle roll is 1500µs
    });
  });
}
