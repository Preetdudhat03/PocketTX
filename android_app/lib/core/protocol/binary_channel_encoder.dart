// ─────────────────────────────────────────────
// PocketTX – Binary Channel Encoder
// Serializes 8-channel PWM & normalized floats into binary byte buffers.
// ─────────────────────────────────────────────

import 'dart:typed_data';
import '../../models/channel_data.dart';
import '../constants/channel_constants.dart';

abstract final class BinaryChannelEncoder {
  static const int payloadSize = ChannelConstants.channelCount * 2; // 8 * 2 = 16 bytes

  /// Encodes 8-channel PWM values into a 16-byte Uint8List.
  static Uint8List encodePwm(List<int> pwmValues) {
    final buffer = Uint8List(payloadSize);
    final bd = ByteData.sublistView(buffer);

    for (var i = 0; i < ChannelConstants.channelCount; i++) {
      final val = (i < pwmValues.length) ? pwmValues[i] : 1500;
      bd.setUint16(i * 2, val.clamp(1000, 2000), Endian.big);
    }
    return buffer;
  }

  /// Decodes a 16-byte Uint8List into ChannelData.
  static ChannelData decodePwm(Uint8List payload) {
    if (payload.length < payloadSize) {
      return ChannelData.idle();
    }

    final bd = ByteData.sublistView(payload);
    final pwmList = List<int>.generate(
      ChannelConstants.channelCount,
      (i) => bd.getUint16(i * 2, Endian.big),
    );

    return ChannelData.fromPwm(pwmList);
  }
}
