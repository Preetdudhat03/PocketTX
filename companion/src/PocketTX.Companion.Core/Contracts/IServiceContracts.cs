using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.Core.Contracts;

public interface ICommunicationChannel
{
    ConnectionType Type { get; }
    bool IsConnected { get; }

    event EventHandler<byte[]>? PacketReceived;
    event EventHandler<bool>? ConnectionStateChanged;

    Task<bool> OpenAsync(CancellationToken cancellationToken = default);
    Task CloseAsync(CancellationToken cancellationToken = default);
    Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default);
}

public interface IConnectionManager
{
    ConnectionType ActiveConnectionType { get; }
    bool IsConnected { get; }

    Task SwitchConnectionAsync(ConnectionType connectionType, CancellationToken cancellationToken = default);
    Task ConnectAsync(CancellationToken cancellationToken = default);
    Task DisconnectAsync(CancellationToken cancellationToken = default);
}

public interface IProfileService
{
    IReadOnlyList<ControllerProfile> AvailableProfiles { get; }
    ControllerProfile ActiveProfile { get; }

    Task LoadProfilesAsync(CancellationToken cancellationToken = default);
    Task<ControllerProfile> SelectProfileAsync(string profileName, CancellationToken cancellationToken = default);
    Task SaveProfileAsync(ControllerProfile profile, CancellationToken cancellationToken = default);
}

public interface ISettingsService
{
    AppSettings CurrentSettings { get; }

    Task LoadSettingsAsync(CancellationToken cancellationToken = default);
    Task SaveSettingsAsync(AppSettings settings, CancellationToken cancellationToken = default);
}

public interface ILoggerService
{
    void LogDebug(string message, string category = "General", Dictionary<string, object>? metadata = null);
    void LogInfo(string message, string category = "General", Dictionary<string, object>? metadata = null);
    void LogWarning(string message, string category = "General", Dictionary<string, object>? metadata = null);
    void LogError(string message, Exception? exception = null, string category = "General", Dictionary<string, object>? metadata = null);
}

public interface IStateStore
{
    ChannelData CurrentChannels { get; }
    ControllerProfile CurrentProfile { get; }
    AppSettings CurrentSettings { get; }
    SimulatorStatus CurrentSimulator { get; }
    DiagnosticMetrics Diagnostics { get; }

    ConnectionType CurrentConnection { get; }
    VirtualBackendType CurrentBackend { get; }
    ThemeType CurrentTheme { get; }
    bool IsConnected { get; }
    double CurrentLatencyMs { get; set; }

    void UpdateChannels(ChannelData channels);
    void UpdateProfile(ControllerProfile profile);
    void UpdateSettings(AppSettings settings);
    void UpdateConnectionStatus(ConnectionType connectionType, bool isConnected);
    void UpdateBackend(VirtualBackendType backendType);
    void UpdateTheme(ThemeType theme);
    void UpdateSimulator(SimulatorStatus status);
    void UpdateDiagnostics(Action<DiagnosticMetrics> updateAction);
}
