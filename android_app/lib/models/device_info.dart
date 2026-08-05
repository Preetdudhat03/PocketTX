// ─────────────────────────────────────────────
// PocketTX – DeviceInfo Model
// Runtime device information for diagnostics & tuning.
// ─────────────────────────────────────────────

import 'package:equatable/equatable.dart';

class DeviceInfo extends Equatable {
  final String manufacturer;
  final String model;
  final String androidVersion;
  final int sdkInt;
  final double screenRefreshRateHz;
  final double displayDpi;
  final double screenWidthDp;
  final double screenHeightDp;
  final bool isPhysicalDevice;

  const DeviceInfo({
    this.manufacturer = 'Unknown',
    this.model = 'Unknown',
    this.androidVersion = 'Unknown',
    this.sdkInt = 0,
    this.screenRefreshRateHz = 60.0,
    this.displayDpi = 160.0,
    this.screenWidthDp = 360.0,
    this.screenHeightDp = 800.0,
    this.isPhysicalDevice = true,
  });

  factory DeviceInfo.unknown() => const DeviceInfo();

  String get displayName => '$manufacturer $model';

  String get refreshRateLabel =>
      '${screenRefreshRateHz.toStringAsFixed(0)}Hz';

  @override
  List<Object?> get props => [
        manufacturer, model, androidVersion, sdkInt,
        screenRefreshRateHz, displayDpi,
      ];

  @override
  String toString() =>
      'DeviceInfo($displayName, Android $androidVersion, '
      '$refreshRateLabel, ${displayDpi.round()}dpi)';
}
