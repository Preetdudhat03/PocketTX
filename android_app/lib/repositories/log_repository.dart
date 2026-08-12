// ─────────────────────────────────────────────
// PocketTX – LogRepository
// In-memory ring buffer + optional Hive persistence.
// ─────────────────────────────────────────────

import '../../models/log_entry_model.dart';
import 'package:PocketTX/core/services/logger_service.dart';

/// Repository providing access to the in-memory log ring buffer.
/// For Phase 1, this wraps LoggerService directly.
class LogRepository {
  static final LogRepository _instance = LogRepository._internal();
  factory LogRepository() => _instance;
  LogRepository._internal();

  final _logger = LoggerService();

  Future<void> init() async {
    // Ring buffer is always initialized in LoggerService singleton
    _logger.info(LogCategory.storage, 'LogRepository.init', 'Log repository ready');
  }

  List<LogEntry> getAll() => _logger.entries;

  List<LogEntry> getByLevel(LogLevel level) =>
      _logger.entries.where((e) => e.level == level).toList();

  List<LogEntry> getByCategory(LogCategory category) =>
      _logger.entries.where((e) => e.category == category).toList();

  Stream<LogEntry> get stream => _logger.stream;

  void clear() => _logger.clear();

  int get count => _logger.entryCount;
}
