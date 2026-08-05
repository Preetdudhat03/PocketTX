using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Shared.Constants;

namespace PocketTX.Companion.Core.Models;

/// <summary>
/// Model representing a transmitter profile with metadata, mappings, deadband, and expo settings.
/// </summary>
public sealed class ControllerProfile
{
    public string Name { get; set; } = "Default Acro";
    public int Version { get; set; } = 1;
    public string Author { get; set; } = "PocketTX";
    public DateTime Created { get; set; } = DateTime.UtcNow;
    public DateTime Modified { get; set; } = DateTime.UtcNow;
    public ProfileType Type { get; set; } = ProfileType.DefaultAcro;

    public float Deadband { get; set; } = 0.02f;
    public float Expo { get; set; } = 0.15f;

    public Dictionary<ChannelType, int> ChannelMap { get; set; } = new()
    {
        { ChannelType.Roll, 0 },
        { ChannelType.Pitch, 1 },
        { ChannelType.Throttle, 2 },
        { ChannelType.Yaw, 3 },
        { ChannelType.Aux1, 4 },
        { ChannelType.Aux2, 5 },
        { ChannelType.Aux3, 6 },
        { ChannelType.Aux4, 7 }
    };

    public Dictionary<ChannelType, bool> InvertedChannels { get; set; } = new()
    {
        { ChannelType.Roll, false },
        { ChannelType.Pitch, false },
        { ChannelType.Throttle, false },
        { ChannelType.Yaw, false }
    };

    public static ControllerProfile CreateDefaultAcro()
    {
        return new ControllerProfile
        {
            Name = "Default Acro",
            Version = 1,
            Author = "PocketTX",
            Type = ProfileType.DefaultAcro,
            Deadband = 0.02f,
            Expo = 0.20f
        };
    }

    public static ControllerProfile CreateLiftoffMicro()
    {
        return new ControllerProfile
        {
            Name = "Liftoff Micro Drones",
            Version = 1,
            Author = "PocketTX",
            Type = ProfileType.LiftoffMicro,
            Deadband = 0.015f,
            Expo = 0.15f
        };
    }

    public static ControllerProfile CreateVelocidrone()
    {
        return new ControllerProfile
        {
            Name = "Velocidrone",
            Version = 1,
            Author = "PocketTX",
            Type = ProfileType.Velocidrone,
            Deadband = 0.01f,
            Expo = 0.25f
        };
    }

    public static ControllerProfile CreateFPVSkyDive()
    {
        return new ControllerProfile
        {
            Name = "FPV SkyDive",
            Version = 1,
            Author = "PocketTX",
            Type = ProfileType.FPVSkyDive,
            Deadband = 0.02f,
            Expo = 0.10f
        };
    }

    public static ControllerProfile CreatePicaSim()
    {
        return new ControllerProfile
        {
            Name = "PicaSim",
            Version = 1,
            Author = "PocketTX",
            Type = ProfileType.PicaSim,
            Deadband = 0.03f,
            Expo = 0.05f
        };
    }
}
