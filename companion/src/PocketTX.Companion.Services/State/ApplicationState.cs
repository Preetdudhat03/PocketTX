using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Services.Messages;

namespace PocketTX.Companion.Services.State;

/// <summary>
/// Central application state store implementation.
/// Thread-safe single source of truth for UI ViewModels and background services.
/// </summary>
public sealed class ApplicationState : IStateStore
{
    private readonly IMessenger _messenger;
    private readonly object _lock = new();

    public ChannelData CurrentChannels { get; private set; } = new();
    public ControllerProfile CurrentProfile { get; private set; } = ControllerProfile.CreateDefaultAcro();
    public AppSettings CurrentSettings { get; private set; } = new();
    public SimulatorStatus CurrentSimulator { get; private set; } = SimulatorStatus.NotRunning();
    public DiagnosticMetrics Diagnostics { get; private set; } = new();

    public ConnectionType CurrentConnection { get; private set; } = ConnectionType.Usb;
    public VirtualBackendType CurrentBackend { get; private set; } = VirtualBackendType.Simulation;
    public ThemeType CurrentTheme { get; private set; } = ThemeType.Dark;
    public bool IsConnected { get; private set; } = true;

    public double CurrentLatencyMs
    {
        get => Diagnostics.CurrentLatencyMs;
        set => UpdateDiagnostics(d => d.CurrentLatencyMs = value);
    }

    public ApplicationState(IMessenger messenger)
    {
        _messenger = messenger;
    }

    public void UpdateChannels(ChannelData channels)
    {
        lock (_lock)
        {
            CurrentChannels = channels;
        }
        _messenger.Send(new ChannelUpdatedMessage(channels));
    }

    public void UpdateProfile(ControllerProfile profile)
    {
        lock (_lock)
        {
            CurrentProfile = profile;
        }
        _messenger.Send(new ProfileChangedMessage(profile));
    }

    public void UpdateSettings(AppSettings settings)
    {
        lock (_lock)
        {
            CurrentSettings = settings;
            CurrentTheme = settings.Theme;
        }
        _messenger.Send(new ThemeChangedMessage(settings.Theme));
    }

    public string ConnectedDeviceName { get; private set; } = "";

    public void UpdateConnectionStatus(ConnectionType connectionType, bool isConnected, string deviceName = "")
    {
        lock (_lock)
        {
            CurrentConnection = connectionType;
            IsConnected = isConnected;
            if (!string.IsNullOrEmpty(deviceName))
            {
                ConnectedDeviceName = deviceName;
            }
        }
        _messenger.Send(new ConnectionStateChangedMessage(connectionType, isConnected, ConnectedDeviceName));
    }

    public void UpdateBackend(VirtualBackendType backendType)
    {
        lock (_lock)
        {
            CurrentBackend = backendType;
            Diagnostics.ActiveBackend = backendType;
        }
    }

    public void UpdateTheme(ThemeType theme)
    {
        lock (_lock)
        {
            CurrentTheme = theme;
            CurrentSettings.Theme = theme;
        }
        _messenger.Send(new ThemeChangedMessage(theme));
    }

    public void UpdateSimulator(SimulatorStatus status)
    {
        lock (_lock)
        {
            CurrentSimulator = status;
        }
        _messenger.Send(new SimulatorStatusChangedMessage(status));
    }

    public void UpdateDiagnostics(Action<DiagnosticMetrics> updateAction)
    {
        lock (_lock)
        {
            updateAction(Diagnostics);
        }
        _messenger.Send(new DiagnosticMetricsUpdatedMessage(Diagnostics));
    }
}
