namespace PocketTX.Companion.Shared.Constants;

/// <summary>
/// Constants representing standard RC channel parameters and boundaries.
/// </summary>
public static class ChannelConstants
{
    public const ushort MinPwmUs = 1000;
    public const ushort CenterPwmUs = 1500;
    public const ushort MaxPwmUs = 2000;

    public const float MinNormalized = -1.0f;
    public const float ZeroNormalized = 0.0f;
    public const float MaxNormalized = 1.0f;

    public const int DefaultChannelCount = 8;
    public const int MaxSupportedChannels = 16;
}
