// ─────────────────────────────────────────────
// PocketTX – Event Bus
// Decoupled reactive event stream for app-wide event broadcasting.
// ─────────────────────────────────────────────

import 'dart:async';

abstract class AppEvent {
  const AppEvent();
}

class EventBus {
  static final EventBus _instance = EventBus._internal();
  factory EventBus() => _instance;
  EventBus._internal();

  final _streamController = StreamController<AppEvent>.broadcast();

  Stream<T> on<T extends AppEvent>() {
    return _streamController.stream.where((event) => event is T).cast<T>();
  }

  void fire(AppEvent event) {
    if (!_streamController.isClosed) {
      _streamController.add(event);
    }
  }

  void dispose() {
    _streamController.close();
  }
}
