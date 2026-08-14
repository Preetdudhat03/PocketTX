// ─────────────────────────────────────────────
// PocketTX – Channel State (Riverpod)
// Central channel data state driving the controller UI.
// ─────────────────────────────────────────────

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/channel_data.dart';

class ChannelStateNotifier extends StateNotifier<ChannelData> {
  ChannelStateNotifier() : super(ChannelData.idle());

  /// Update all channels at once (from InputProcessor output).
  void updateAll(ChannelData data) => state = data;

  /// Update a single channel by index.
  void updateChannel(int index, double value) {
    state = state.withChannel(index, value);
  }

  /// Reset all channels to idle position.
  void reset() => state = ChannelData.idle();
}

final channelStateProvider =
    StateNotifierProvider<ChannelStateNotifier, ChannelData>(
  (ref) => ChannelStateNotifier(),
);

/// Trigger provider for centering both 2D gimbals on demand.
final recenterSticksTriggerProvider = StateProvider<int>((ref) => 0);

