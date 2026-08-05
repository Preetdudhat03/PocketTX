using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.Core.Models;

/// <summary>
/// Root settings model serialized to appsettings.json with versioning support.
/// </summary>
public sealed class AppSettings
{
    public int Version { get; set; } = 1;
    public ThemeType Theme { get; set; } = ThemeType.Dark;
    public bool AutoStart { get; set; } = false;
    public bool StartMinimized { get; set; } = false;

    public ConnectionType PreferredConnection { get; set; } = ConnectionType.TestMode;
    public VirtualBackendType PreferredVirtualBackend { get; set; } = VirtualBackendType.Simulation;

    public float Deadband { get; set; } = 0.02f;
    public float Expo { get; set; } = 0.15f;
    public int InputUpdateFrequencyHz { get; set; } = 250;

    public string SelectedProfileName { get; set; } = "Default Acro";
}
