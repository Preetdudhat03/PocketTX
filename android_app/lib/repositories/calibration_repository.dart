// ─────────────────────────────────────────────
// PocketTX – CalibrationRepository
// Hive-backed calibration data persistence.
// ─────────────────────────────────────────────

import 'dart:convert';
import 'package:hive_ce_flutter/hive_flutter.dart';
import '../../models/calibration_data.dart';
import '../constants/app_constants.dart';
import '../services/logger_service.dart';
import '../../models/log_entry_model.dart';

class CalibrationRepository {
  static final CalibrationRepository _instance = CalibrationRepository._internal();
  factory CalibrationRepository() => _instance;
  CalibrationRepository._internal();

  final _log = LoggerService();
  late Box _box;

  Future<void> init() async {
    _box = await Hive.openBox(AppConstants.calibrationBox);
  }

  Future<CalibrationData> loadForProfile(String profileId) async {
    try {
      final raw = _box.get(profileId) as String?;
      if (raw == null) return CalibrationData.defaults();
      return CalibrationData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      _log.error(LogCategory.storage, 'CalibrationRepository.load', e.toString());
      return CalibrationData.defaults();
    }
  }

  Future<void> saveForProfile(String profileId, CalibrationData data) async {
    try {
      await _box.put(profileId, jsonEncode(data.toJson()));
    } catch (e) {
      _log.error(LogCategory.storage, 'CalibrationRepository.save', e.toString());
    }
  }

  Future<void> resetForProfile(String profileId) async {
    await _box.delete(profileId);
    _log.info(LogCategory.storage, 'CalibrationRepository.reset',
        'Reset calibration for profile: $profileId');
  }
}
