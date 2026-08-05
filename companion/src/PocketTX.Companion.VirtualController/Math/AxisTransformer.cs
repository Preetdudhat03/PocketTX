namespace PocketTX.Companion.VirtualController.Math;

/// <summary>
/// Math utilities for applying deadband thresholds and exponential response curves to analog stick inputs.
/// </summary>
public static class AxisTransformer
{
    public static float ApplyDeadband(float input, float deadband)
    {
        float clamped = System.Math.Clamp(input, -1.0f, 1.0f);
        float abs = System.Math.Abs(clamped);

        if (abs <= deadband) return 0.0f;

        float sign = System.Math.Sign(clamped);
        float scaled = (abs - deadband) / (1.0f - deadband);

        return sign * scaled;
    }

    public static float ApplyExpo(float input, float expo)
    {
        float clamped = System.Math.Clamp(input, -1.0f, 1.0f);
        if (expo <= 0.001f) return clamped;

        float abs = System.Math.Abs(clamped);
        float sign = System.Math.Sign(clamped);

        // Exponential curve blending linear and cubic response
        double expoVal = System.Math.Pow(abs, 1.0 + (expo * 2.0));
        return sign * (float)expoVal;
    }

    public static float Transform(float rawInput, float deadband, float expo)
    {
        float deadbanded = ApplyDeadband(rawInput, deadband);
        return ApplyExpo(deadbanded, expo);
    }
}
