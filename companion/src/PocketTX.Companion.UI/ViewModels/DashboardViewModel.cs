using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Logging.Models;
using PocketTX.Companion.Services.Messages;
using System.Collections.ObjectModel;
using System.Windows;

namespace PocketTX.Companion.UI.ViewModels;

public partial class DashboardViewModel : ObservableObject,
    IRecipient<ConnectionStateChangedMessage>,
    IRecipient<ProfileChangedMessage>,
    IRecipient<SimulatorStatusChangedMessage>,
    IRecipient<DiagnosticMetricsUpdatedMessage>,
    IRecipient<LogEntry>
{
    private readonly IStateStore _stateStore;
    private readonly IConnectionManager _connectionManager;

    [ObservableProperty]
    private string _connectionStatusText = "TestMode (Connected)";

    [ObservableProperty]
    private bool _isConnected = true;

    [ObservableProperty]
    private string _activeProfileName = "Default Acro";

    [ObservableProperty]
    private string _simulatorStatusText = "None Detected";

    [ObservableProperty]
    private bool _isSimulatorRunning = false;

    [ObservableProperty]
    private double _latencyMs = 1.2;

    [ObservableProperty]
    private int _updateFrequencyHz = 250;

    [ObservableProperty]
    private int _packetRate = 250;

    [ObservableProperty]
    private int _fps = 60;

    [ObservableProperty]
    private string _activeBackendText = "Simulation Backend";

    [ObservableProperty]
    private bool _isScanning = false;

    [ObservableProperty]
    private string _scanButtonText = "REFRESH DEVICES";

    public ObservableCollection<string> QuickLogs { get; } = new();

    public DashboardViewModel(
        IStateStore stateStore,
        IConnectionManager connectionManager,
        IMessenger messenger)
    {
        _stateStore = stateStore;
        _connectionManager = connectionManager;
        messenger.RegisterAll(this);

        RefreshFromState();
    }

    [RelayCommand]
    private async Task ScanDevicesAsync()
    {
        IsScanning = true;
        ScanButtonText = "SCANNING...";

        try
        {
            await _connectionManager.ScanDevicesAsync();
        }
        finally
        {
            IsScanning = false;
            ScanButtonText = "REFRESH DEVICES";
        }
    }

    private void RefreshFromState()
    {
        ConnectionStatusText = $"{_stateStore.CurrentConnection} ({(_stateStore.IsConnected ? "Connected" : "Disconnected")})";
        IsConnected = _stateStore.IsConnected;
        ActiveProfileName = _stateStore.CurrentProfile.Name;
        SimulatorStatusText = _stateStore.CurrentSimulator.IsDetected ? $"{_stateStore.CurrentSimulator.Type} (PID {_stateStore.CurrentSimulator.ProcessId})" : "None Detected";
        IsSimulatorRunning = _stateStore.CurrentSimulator.IsDetected;
        LatencyMs = _stateStore.CurrentLatencyMs;
        ActiveBackendText = $"{_stateStore.CurrentBackend} Backend";
    }

    public void Receive(ConnectionStateChangedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            string devName = !string.IsNullOrEmpty(message.DeviceName) ? message.DeviceName : "Mobile Device";
            ConnectionStatusText = message.IsConnected ? $"{devName} ({message.ConnectionType})" : "Disconnected";
            IsConnected = message.IsConnected;
        });
    }

    public void Receive(ProfileChangedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            ActiveProfileName = message.Profile.Name;
        });
    }

    public void Receive(SimulatorStatusChangedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            SimulatorStatusText = message.Status.IsDetected ? $"{message.Status.Type} ({message.Status.ProcessName})" : "None Detected";
            IsSimulatorRunning = message.Status.IsDetected;
        });
    }

    public void Receive(DiagnosticMetricsUpdatedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            LatencyMs = message.Metrics.CurrentLatencyMs;
            UpdateFrequencyHz = message.Metrics.InputFrequencyHz;
            PacketRate = (int)message.Metrics.PacketsPerSecond;
            Fps = message.Metrics.Fps;
            ActiveBackendText = $"{message.Metrics.ActiveBackend} Backend";
        });
    }

    public void Receive(LogEntry log)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            QuickLogs.Insert(0, $"[{log.Timestamp:HH:mm:ss}] [{log.Level}] {log.Message}");
            while (QuickLogs.Count > 10)
            {
                QuickLogs.RemoveAt(QuickLogs.Count - 1);
            }
        });
    }
}
