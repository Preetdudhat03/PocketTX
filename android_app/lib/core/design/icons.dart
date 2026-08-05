// ─────────────────────────────────────────────
// PocketTX Design System – Semantic Icon Map
// Centralizes all icon usages to prevent inconsistency
// ─────────────────────────────────────────────

import 'package:flutter/material.dart';

abstract final class AppIcons {
  // Navigation
  static const IconData dashboard = Icons.dashboard_rounded;
  static const IconData controller = Icons.sports_esports_rounded;
  static const IconData profiles = Icons.tune_rounded;
  static const IconData settings = Icons.settings_rounded;
  static const IconData diagnostics = Icons.analytics_rounded;
  static const IconData logs = Icons.terminal_rounded;

  // Connection & Status
  static const IconData connected = Icons.link_rounded;
  static const IconData disconnected = Icons.link_off_rounded;
  static const IconData searching = Icons.wifi_find_rounded;
  static const IconData bluetooth = Icons.bluetooth_rounded;
  static const IconData usb = Icons.usb_rounded;
  static const IconData wifi = Icons.wifi_rounded;
  static const IconData signal = Icons.signal_wifi_4_bar_rounded;
  static const IconData noSignal = Icons.signal_wifi_off_rounded;

  // Controller
  static const IconData arm = Icons.power_settings_new_rounded;
  static const IconData disarm = Icons.power_off_rounded;
  static const IconData beeper = Icons.volume_up_rounded;
  static const IconData beeperOff = Icons.volume_off_rounded;
  static const IconData gimbalLeft = Icons.gamepad_rounded;
  static const IconData gimbalRight = Icons.ads_click_rounded;
  static const IconData channel = Icons.bar_chart_rounded;
  static const IconData throttle = Icons.rocket_launch_rounded;
  static const IconData calibrate = Icons.straighten_rounded;

  // Profiles
  static const IconData profile = Icons.flight_rounded;
  static const IconData addProfile = Icons.add_circle_rounded;
  static const IconData editProfile = Icons.edit_rounded;
  static const IconData deleteProfile = Icons.delete_rounded;
  static const IconData copyProfile = Icons.copy_rounded;
  static const IconData activeProfile = Icons.check_circle_rounded;

  // Settings
  static const IconData theme = Icons.palette_rounded;
  static const IconData darkMode = Icons.dark_mode_rounded;
  static const IconData lightMode = Icons.light_mode_rounded;
  static const IconData haptics = Icons.vibration_rounded;
  static const IconData sensitivity = Icons.touch_app_rounded;
  static const IconData expo = Icons.show_chart_rounded;
  static const IconData deadband = Icons.center_focus_strong_rounded;
  static const IconData frequency = Icons.speed_rounded;

  // Diagnostics & Dev
  static const IconData fps = Icons.speed_rounded;
  static const IconData memory = Icons.memory_rounded;
  static const IconData cpu = Icons.developer_board_rounded;
  static const IconData timer = Icons.timer_rounded;
  static const IconData devOverlay = Icons.bug_report_rounded;
  static const IconData refresh = Icons.refresh_rounded;
  static const IconData history = Icons.history_rounded;

  // Logs
  static const IconData logInfo = Icons.info_rounded;
  static const IconData logWarning = Icons.warning_amber_rounded;
  static const IconData logError = Icons.error_rounded;
  static const IconData logDebug = Icons.code_rounded;
  static const IconData logVerbose = Icons.notes_rounded;
  static const IconData filterLog = Icons.filter_list_rounded;
  static const IconData clearLog = Icons.clear_all_rounded;

  // General Actions
  static const IconData close = Icons.close_rounded;
  static const IconData back = Icons.arrow_back_rounded;
  static const IconData forward = Icons.arrow_forward_rounded;
  static const IconData expand = Icons.expand_more_rounded;
  static const IconData collapse = Icons.expand_less_rounded;
  static const IconData more = Icons.more_vert_rounded;
  static const IconData check = Icons.check_rounded;
  static const IconData warning = Icons.warning_rounded;
  static const IconData error = Icons.error_outline_rounded;
  static const IconData info = Icons.info_outline_rounded;
  static const IconData success = Icons.check_circle_outline_rounded;
  static const IconData copy = Icons.copy_rounded;
  static const IconData save = Icons.save_rounded;
  static const IconData reset = Icons.restart_alt_rounded;
  static const IconData battery = Icons.battery_full_rounded;
  static const IconData batteryLow = Icons.battery_alert_rounded;
  static const IconData device = Icons.phone_android_rounded;
}
