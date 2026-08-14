using PocketTX.Companion.Shared.Constants;

namespace PocketTX.Companion.Core.Models;

/// <summary>
/// Domain model encapsulating normalized (-1.0 to 1.0) and PWM (1000us to 2000us) channel values.
/// </summary>
public sealed class ChannelData
{
    public float[] NormalizedValues { get; }
    public ushort[] PwmValues { get; }
    public bool[] DigitalSwitches { get; }
    public DateTime Timestamp { get; set; }

    public ChannelData(int channelCount = ChannelConstants.DefaultChannelCount)
    {
        NormalizedValues = new float[channelCount];
        PwmValues = new ushort[channelCount];
        DigitalSwitches = new bool[channelCount];
        Timestamp = DateTime.UtcNow;

        // Default neutral positions
        NormalizedValues[0] = 0.0f; // Roll
        NormalizedValues[1] = 0.0f; // Pitch
        NormalizedValues[2] = -1.0f; // Throttle down
        NormalizedValues[3] = 0.0f; // Yaw

        UpdatePwmFromNormalized();
    }

    public void SetChannelNormalized(int index, float normalizedValue)
    {
        if (index < 0 || index >= NormalizedValues.Length) return;

        NormalizedValues[index] = Math.Clamp(normalizedValue, ChannelConstants.MinNormalized, ChannelConstants.MaxNormalized);
        PwmValues[index] = NormalizedToPwm(NormalizedValues[index]);
        if (index < DigitalSwitches.Length)
        {
            DigitalSwitches[index] = NormalizedValues[index] > 0.0f;
        }
        Timestamp = DateTime.UtcNow;
    }

    public void SetChannelPwm(int index, ushort pwmValue)
    {
        if (index < 0 || index >= PwmValues.Length) return;

        PwmValues[index] = Math.Clamp(pwmValue, ChannelConstants.MinPwmUs, ChannelConstants.MaxPwmUs);
        NormalizedValues[index] = PwmToNormalized(PwmValues[index]);
        if (index < DigitalSwitches.Length)
        {
            DigitalSwitches[index] = NormalizedValues[index] > 0.0f;
        }
        Timestamp = DateTime.UtcNow;
    }

    public void UpdatePwmFromNormalized()
    {
        for (int i = 0; i < NormalizedValues.Length; i++)
        {
            PwmValues[i] = NormalizedToPwm(NormalizedValues[i]);
        }
    }

    public static ushort NormalizedToPwm(float normalized)
    {
        float clamped = Math.Clamp(normalized, -1.0f, 1.0f);
        return (ushort)Math.Round(ChannelConstants.CenterPwmUs + (clamped * 500.0f));
    }

    public static float PwmToNormalized(ushort pwm)
    {
        ushort clamped = Math.Clamp(pwm, ChannelConstants.MinPwmUs, ChannelConstants.MaxPwmUs);
        return (clamped - (float)ChannelConstants.CenterPwmUs) / 500.0f;
    }
}
