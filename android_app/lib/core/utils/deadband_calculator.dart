// ─────────────────────────────────────────────
// PocketTX – Deadband Calculator
// Applies a center deadband to normalized stick input.
// 100% test coverage required.
// ─────────────────────────────────────────────

/// Applies a center deadband to a normalized input value.
///
/// Within [-deadband, +deadband], output = 0.0.
/// Outside the deadband, the output is rescaled to fill [-1.0, +1.0].
abstract final class DeadbandCalculator {
  /// Apply deadband to [input].
  ///
  /// [input]    Normalized value in range [-1.0, +1.0]
  /// [deadband] Deadband width in range [0.0, 0.5] (e.g. 0.02 = 2%)
  /// Returns    Normalized value in range [-1.0, +1.0]
  static double apply(double input, double deadband) {
    assert(deadband >= 0.0 && deadband <= 0.5, 'deadband must be in [0.0, 0.5]');
    final clamped = input.clamp(-1.0, 1.0);
    if (deadband == 0.0) return clamped;

    final abs = clamped.abs();
    if (abs <= deadband) return 0.0;

    // Rescale: map (deadband → 1.0) to (0.0 → 1.0)
    final rescaled = (abs - deadband) / (1.0 - deadband);
    return rescaled * clamped.sign;
  }

  /// Apply deadband to all channels with per-channel deadband values.
  static List<double> applyAll(List<double> inputs, List<double> deadbands) {
    assert(inputs.length == deadbands.length);
    return List.generate(inputs.length, (i) => apply(inputs[i], deadbands[i]));
  }

  /// Returns true if [input] falls within the deadband zone.
  static bool isInDeadband(double input, double deadband) =>
      input.abs() <= deadband;
}
