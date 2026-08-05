// ─────────────────────────────────────────────
// PocketTX – Logger Service
// Structured logging with in-memory ring buffer (200 entries)
// + optional file sink. Matches Windows Companion log format.
// ─────────────────────────────────────────────

import 'dart:collection';
import 'package:logger/logger.dart' as pkg_logger;
import '../../models/log_entry_model.dart';
import '../constants/app_constants.dart';

/// Structured logging service with a 200-entry in-memory ring buffer.
///
/// Features:
/// - In-memory ring buffer for fast log viewer rendering
/// - Structured entries (Timestamp, Category, Event, Level, Message)
/// - Console output via logger package in debug mode
/// - Stream for reactive log UI updates
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final Queue<LogEntry> _buffer = Queue();
  int _nextId = 0;

  final _pkg = pkg_logger.Logger(
    printer: pkg_logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  final _controller = _StreamController();

  /// Stream of new log entries for reactive UI.
  Stream<LogEntry> get stream => _controller.stream;

  /// Read-only snapshot of the current ring buffer.
  List<LogEntry> get entries => List.unmodifiable(_buffer.toList());

  int get entryCount => _buffer.length;

  void info(
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) =>
      _log(LogLevel.info, category, event, message, metadata: metadata);

  void warning(
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) =>
      _log(LogLevel.warning, category, event, message, metadata: metadata);

  void error(
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) =>
      _log(LogLevel.error, category, event, message, metadata: metadata);

  void debug(
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) =>
      _log(LogLevel.debug, category, event, message, metadata: metadata);

  void verbose(
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) =>
      _log(LogLevel.verbose, category, event, message, metadata: metadata);

  void _log(
    LogLevel level,
    LogCategory category,
    String event,
    String message, {
    Map<String, dynamic>? metadata,
  }) {
    final entry = LogEntry(
      id: _nextId++,
      timestamp: DateTime.now(),
      category: category,
      event: event,
      level: level,
      message: message,
      metadata: metadata,
    );

    // Ring buffer: evict oldest when full
    if (_buffer.length >= AppConstants.maxLogEntries) {
      _buffer.removeFirst();
    }
    _buffer.addLast(entry);
    _controller.add(entry);

    // Console output
    switch (level) {
      case LogLevel.verbose:
      case LogLevel.debug:
        _pkg.d('[${category.name}] $event: $message');
      case LogLevel.info:
        _pkg.i('[${category.name}] $event: $message');
      case LogLevel.warning:
        _pkg.w('[${category.name}] $event: $message');
      case LogLevel.error:
        _pkg.e('[${category.name}] $event: $message');
    }
  }

  void clear() {
    _buffer.clear();
    _nextId = 0;
  }

  void dispose() {
    _controller.dispose();
  }
}

// Minimal broadcast stream controller wrapper
class _StreamController {
  final List<void Function(LogEntry)> _listeners = [];
  bool _disposed = false;

  Stream<LogEntry> get stream => _StreamImpl(this);

  void add(LogEntry entry) {
    if (_disposed) return;
    for (final l in List.of(_listeners)) {
      l(entry);
    }
  }

  void dispose() {
    _disposed = true;
    _listeners.clear();
  }
}

class _StreamImpl extends Stream<LogEntry> {
  final _StreamController _ctrl;
  _StreamImpl(this._ctrl);

  @override
  StreamSubscription<LogEntry> listen(
    void Function(LogEntry event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    if (onData != null) _ctrl._listeners.add(onData);
    return _NoOpSubscription(onData, _ctrl);
  }
}

class _NoOpSubscription implements StreamSubscription<LogEntry> {
  final void Function(LogEntry)? _onData;
  final _StreamController _ctrl;
  bool _paused = false;
  bool _cancelled = false;

  _NoOpSubscription(this._onData, this._ctrl);

  @override
  Future<void> cancel() async {
    _cancelled = true;
    if (_onData != null) _ctrl._listeners.remove(_onData);
  }

  @override
  void onData(void Function(LogEntry data)? handleData) {}
  @override
  void onError(Function? handleError) {}
  @override
  void onDone(void Function()? handleDone) {}
  @override
  void pause([Future<void>? resumeSignal]) => _paused = true;
  @override
  void resume() => _paused = false;
  @override
  bool get isPaused => _paused;
  @override
  Future<E> asFuture<E>([E? futureValue]) => Completer<E>().future;
}
