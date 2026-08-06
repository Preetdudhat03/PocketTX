// ─────────────────────────────────────────────
// PocketTX – Packet Payload
// Encapsulates binary payload bytes with CRC32 integrity checksums.
// ─────────────────────────────────────────────

import 'dart:typed_data';

class PacketPayload {
  final Uint8List data;

  const PacketPayload(this.data);

  int get length => data.length;

  int calculateCrc32() {
    int crc = 0xFFFFFFFF;
    for (int i = 0; i < data.length; i++) {
      crc ^= data[i];
      for (int j = 0; j < 8; j++) {
        if ((crc & 1) != 0) {
          crc = (crc >> 1) ^ 0xEDB88320;
        } else {
          crc = crc >> 1;
        }
      }
    }
    return (crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
  }
}
