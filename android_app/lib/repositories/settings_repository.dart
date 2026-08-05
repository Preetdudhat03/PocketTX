// ─────────────────────────────────────────────
// PocketTX – SettingsRepository
// SharedPreferences-backed app settings persistence.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../models/app_settings.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';

const _kSettingsKey = 'app_settings_v1';

class SettingsRepository {
  static final SettingsRepository _instance = SettingsRepository._internal();
  factory SettingsRepository() => _instance;
  SettingsRepository._internal();

  final _log = LoggerService();
  late SharedPreferences _prefs;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _log.info(LogCategory.storage, 'SettingsRepository.init', 'SharedPreferences ready');
  }

  Future<AppSettings> load() async {
    try {
      final raw = _prefs.getString(_kSettingsKey);
      if (raw == null) return const AppSettings();
      return AppSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.error(LogCategory.storage, 'SettingsRepository.load', e.toString());
      return const AppSettings();
    }
  }

  Future<void> save(AppSettings settings) async {
    try {
      await _prefs.setString(_kSettingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      _log.error(LogCategory.storage, 'SettingsRepository.save', e.toString());
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_kSettingsKey);
  }
}
