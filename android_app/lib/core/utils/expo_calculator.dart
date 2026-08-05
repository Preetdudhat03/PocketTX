// ─────────────────────────────────────────────
// PocketTX – Expo Calculator
// Applies cubic expo curve to normalized stick input.
// 100% test coverage required.
// ─────────────────────────────────────────────

/// Applies an exponential curve to a normalized input value.
///
/// Formula: output = input * (1 - expo) + input³ * expo
/// - expo = 0.0 → linear response
/// - expo = 1.0 → maximum cubic curve (feels very soft near center)
abstract final class ExpoCalculator {
  /// Apply expo curve to [input] with given [expo] rate.
  ///
  /// [input]   Normalized value in range [-1.0, +1.0]
  /// [expo]    Expo factor in range [0.0, 1.0]
  /// Returns   Normalized value in range [-1.0, +1.0]
  static double apply(double input, double expo) {
    assert(expo >= 0.0 && expo <= 1.0, 'expo must be in [0.0, 1.0]');
    final clamped = input.clamp(-1.0, 1.0);
    if (expo == 0.0) return clamped;
    return clamped * (1.0 - expo) + (clamped * clamped * clamped) * expo;
  }

  /// Apply expo to a list of values with per-channel expo rates.
  static List<double> applyAll(List<double> inputs, List<double> expos) {
    assert(inputs.length == expos.length);
    return List.generate(inputs.length, (i) => apply(inputs[i], expos[i]));
  }

  /// Compute the slope (sensitivity) at the center (input=0).
  /// At center, slope = (1 - expo). Useful for displaying "center sensitivity".
  static double centerSensitivity(double expo) => 1.0 - expo;

  /// Compute the slope at full deflection (input=±1).
  /// At full stick, slope is always 1.0 regardless of expo.
  static double fullDeflectionSensitivity() => 1.0;
}
