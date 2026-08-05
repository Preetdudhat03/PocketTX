using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.UI.DesignData;

public static class SampleData
{
    public static AppSettings SampleSettings => new()
    {
        Theme = ThemeType.Dark,
        PreferredConnection = ConnectionType.TestMode,
        PreferredVirtualBackend = VirtualBackendType.Simulation,
        Deadband = 0.02f,
        Expo = 0.15f
    };

    public static ControllerProfile SampleProfile => ControllerProfile.CreateDefaultAcro();

    public static DiagnosticMetrics SampleMetrics => new()
    {
        ApplicationUptime = TimeSpan.FromMinutes(42),
        CurrentLatencyMs = 1.25,
        AverageLatencyMs = 1.30,
        PeakLatencyMs = 2.45,
        PacketsPerSecond = 250,
        Fps = 60,
        CpuUsagePercent = 0.8f,
        RamUsageMb = 48.5,
        ThreadCount = 14,
        ActiveBackend = VirtualBackendType.Simulation
    };
}
