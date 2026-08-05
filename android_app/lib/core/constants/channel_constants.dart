// ─────────────────────────────────────────────
// PocketTX – Channel Constants
// Symmetric with Windows Companion values
// ─────────────────────────────────────────────

abstract final class ChannelConstants {
  static const int channelCount = 8;

  // Normalized range
  static const double normalizedMin = -1.0;
  static const double normalizedMax = 1.0;
  static const double normalizedCenter = 0.0;

  // PWM range (microseconds)
  static const int pwmMin = 1000;
  static const int pwmMax = 2000;
  static const int pwmCenter = 1500;
  static const int pwmRange = pwmMax - pwmMin; // 1000

  // Throttle (Ch3) specific — starts at min not center
  static const double throttleNormalizedMin = -1.0; // maps to 1000us
  static const double throttleNormalizedMax = 1.0;  // maps to 2000us
  static const double throttleDefault = -1.0;       // armed idle = 1000us

  // Channel indices (0-based)
  static const int chRoll = 0;
  static const int chPitch = 1;
  static const int chThrottle = 2;
  static const int chYaw = 3;
  static const int chAux1 = 4;
  static const int chAux2 = 5;
  static const int chAux3 = 6;
  static const int chAux4 = 7;

  // Channel names
  static const List<String> channelNames = [
    'ROLL', 'PITCH', 'THROTTLE', 'YAW',
    'AUX1', 'AUX2', 'AUX3', 'AUX4',
  ];

  // Default expo values (0.0 = linear, 1.0 = max expo)
  static const double defaultExpo = 0.3;

  // Default deadband (normalized, 0.02 = 2%)
  static const double defaultDeadband = 0.02;

  // Update rate presets (Hz)
  static const List<int> updateRatePresets = [250, 500, 750, 1000];
  static const int defaultUpdateRateHz = 250;

  // Conversion
  static int normalizedToPwm(double normalized) =>
      (pwmCenter + (normalized * (pwmRange / 2))).round().clamp(pwmMin, pwmMax);

  static double pwmToNormalized(int pwm) =>
      ((pwm - pwmCenter) / (pwmRange / 2)).clamp(normalizedMin, normalizedMax);
}
