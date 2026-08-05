// ─────────────────────────────────────────────
// PocketTX – LogEntry Model
// Structured log entry matching Windows Companion logging format.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';

enum LogLevel { verbose, debug, info, warning, error }

enum LogCategory {
  system,
  controller,
  channels,
  profiles,
  settings,
  diagnostics,
  communication,
  physics,
  storage,
}

class LogEntry extends Equatable {
  final int id;
  final DateTime timestamp;
  final LogCategory category;
  final String event;
  final LogLevel level;
  final String message;
  final Map<String, dynamic>? metadata;

  const LogEntry({
    required this.id,
    required this.timestamp,
    required this.category,
    required this.event,
    required this.level,
    required this.message,
    this.metadata,
  });

  factory LogEntry.info({
    required int id,
    required LogCategory category,
    required String event,
    required String message,
    Map<String, dynamic>? metadata,
  }) =>
      LogEntry(
        id: id,
        timestamp: DateTime.now(),
        category: category,
        event: event,
        level: LogLevel.info,
        message: message,
        metadata: metadata,
      );

  factory LogEntry.warning({
    required int id,
    required LogCategory category,
    required String event,
    required String message,
    Map<String, dynamic>? metadata,
  }) =>
      LogEntry(
        id: id,
        timestamp: DateTime.now(),
        category: category,
        event: event,
        level: LogLevel.warning,
        message: message,
        metadata: metadata,
      );

  factory LogEntry.error({
    required int id,
    required LogCategory category,
    required String event,
    required String message,
    Map<String, dynamic>? metadata,
  }) =>
      LogEntry(
        id: id,
        timestamp: DateTime.now(),
        category: category,
        event: event,
        level: LogLevel.error,
        message: message,
        metadata: metadata,
      );

  String get categoryLabel => category.name.toUpperCase();
  String get levelLabel => level.name.toUpperCase();
  String get formattedTime =>
      '${timestamp.hour.toString().padLeft(2, '0')}:'
      '${timestamp.minute.toString().padLeft(2, '0')}:'
      '${timestamp.second.toString().padLeft(2, '0')}.'
      '${timestamp.millisecond.toString().padLeft(3, '0')}';

  @override
  List<Object?> get props => [id, timestamp, category, event, level, message];

  @override
  String toString() =>
      '[$formattedTime] [$categoryLabel] [$levelLabel] $event: $message';
}
