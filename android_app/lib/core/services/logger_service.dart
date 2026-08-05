// ─────────────────────────────────────────────
// PocketTX – Logger Service
// Structured logging with in-memory ring buffer (200 entries)
// + optional file sink. Matches Windows Companion log format.
// ─────────────────────────────────────────────

import 'dart:async';
import 'dart:collection';
import 'package:logger/logger.dart' as pkg_logger;
import '../../models/log_entry_model.dart';
import '../constants/app_constants.dart';

/// Structured logging service with a 200-entry in-memory ring buffer.
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final Queue<LogEntry> _buffer = Queue();
  int _nextId = 0;

  final _streamController =
      StreamController<LogEntry>.broadcast();

  final _pkg = pkg_logger.Logger(
    printer: pkg_logger.PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  /// Stream of new log entries for reactive UI.
  Stream<LogEntry> get stream => _streamController.stream;

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

    if (!_streamController.isClosed) {
      _streamController.add(entry);
    }

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
    _streamController.close();
  }
}
