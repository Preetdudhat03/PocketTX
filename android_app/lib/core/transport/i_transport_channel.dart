// ─────────────────────────────────────────────
// PocketTX – Transport Channel Interface
// Base interface for all network/physical transport channels.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:typed_data';
import '../compatibility/protocol_version.dart';

abstract class ITransportChannel {
  ConnectionType get type;
  bool get isConnected;

  /// Stream of incoming binary packets.
  Stream<Uint8List> get packetStream;

  /// Stream of connection state changes.
  Stream<bool> get connectionStateStream;

  /// Opens the transport channel to [host] and [port].
  Future<bool> open({String? host, int? port});

  /// Closes the transport channel.
  Future<void> close();

  /// Sends a raw [data] buffer across the transport.
  Future<bool> sendData(Uint8List data);
}
