using System.Windows;
using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Services.Messages;

namespace PocketTX.Companion.UI.ViewModels;

public partial class TestControllerViewModel : ObservableObject,
    IRecipient<ChannelUpdatedMessage>,
    IRecipient<DiagnosticMetricsUpdatedMessage>,
    IRecipient<ConnectionStateChangedMessage>
{
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;
    private readonly IMessenger _messenger;
    private bool _isInternalUpdating;

    [ObservableProperty]
    private float _rollNormalized = 0.0f; // -1.0 to 1.0

    [ObservableProperty]
    private float _pitchNormalized = 0.0f; // -1.0 to 1.0

    [ObservableProperty]
    private float _throttleNormalized = -1.0f; // -1.0 to 1.0

    [ObservableProperty]
    private float _yawNormalized = 0.0f; // -1.0 to 1.0

    [ObservableProperty]
    private bool _isArmed = false;

    [ObservableProperty]
    private bool _isBeeperActive = false;

    [ObservableProperty]
    private string _flightModeText = "Acro";

    [ObservableProperty]
    private double _latencyMs = 1.2;

    [ObservableProperty]
    private int _packetRate = 250;

    [ObservableProperty]
    private int _updateFrequencyHz = 250;

    [ObservableProperty]
    private bool _isConnected = true;

    [ObservableProperty]
    private string _connectionStatusText = "USB Wired (127.0.0.1)";

    public ushort RollPwm => ChannelData.NormalizedToPwm(RollNormalized);
    public ushort PitchPwm => ChannelData.NormalizedToPwm(PitchNormalized);
    public ushort ThrottlePwm => ChannelData.NormalizedToPwm(ThrottleNormalized);
    public ushort YawPwm => ChannelData.NormalizedToPwm(YawNormalized);

    public string ArmText => IsArmed ? "ARMED" : "DISARMED";
    public string BeeperText => IsBeeperActive ? "ON" : "OFF";

    public TestControllerViewModel(IStateStore stateStore, ILoggerService logger, IMessenger messenger)
    {
        _stateStore = stateStore;
        _logger = logger;
        _messenger = messenger;
        _messenger.RegisterAll(this);

        RefreshFromState();
    }

    private void RefreshFromState()
    {
        IsConnected = _stateStore.IsConnected;
        ConnectionStatusText = $"{_stateStore.CurrentConnection} ({(_stateStore.IsConnected ? "Connected" : "Disconnected")})";
        LatencyMs = _stateStore.CurrentLatencyMs;
    }

    public void Receive(ChannelUpdatedMessage message)
    {
        if (_isInternalUpdating) return;

        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            _isInternalUpdating = true;
            try
            {
                RollNormalized = message.ChannelData.NormalizedValues.Length > 0 ? message.ChannelData.NormalizedValues[0] : 0.0f;
                PitchNormalized = message.ChannelData.NormalizedValues.Length > 1 ? message.ChannelData.NormalizedValues[1] : 0.0f;
                ThrottleNormalized = message.ChannelData.NormalizedValues.Length > 2 ? message.ChannelData.NormalizedValues[2] : -1.0f;
                YawNormalized = message.ChannelData.NormalizedValues.Length > 3 ? message.ChannelData.NormalizedValues[3] : 0.0f;
                
                IsArmed = (message.ChannelData.DigitalSwitches != null && message.ChannelData.DigitalSwitches.Length > 0 && message.ChannelData.DigitalSwitches[0]) ||
                          (message.ChannelData.NormalizedValues.Length > 4 && message.ChannelData.NormalizedValues[4] > 0.0f);

                IsBeeperActive = (message.ChannelData.DigitalSwitches != null && message.ChannelData.DigitalSwitches.Length > 1 && message.ChannelData.DigitalSwitches[1]) ||
                                 (message.ChannelData.NormalizedValues.Length > 5 && message.ChannelData.NormalizedValues[5] > 0.0f);

                OnPropertyChanged(nameof(RollPwm));
                OnPropertyChanged(nameof(PitchPwm));
                OnPropertyChanged(nameof(ThrottlePwm));
                OnPropertyChanged(nameof(YawPwm));
                OnPropertyChanged(nameof(ArmText));
                OnPropertyChanged(nameof(BeeperText));
            }
            finally
            {
                _isInternalUpdating = false;
            }
        });
    }

    public void Receive(DiagnosticMetricsUpdatedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            LatencyMs = message.Metrics.CurrentLatencyMs;
            PacketRate = (int)message.Metrics.PacketsPerSecond;
            UpdateFrequencyHz = message.Metrics.InputFrequencyHz;
        });
    }

    public void Receive(ConnectionStateChangedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            IsConnected = message.IsConnected;
            string dev = string.IsNullOrEmpty(message.DeviceName) ? "Mobile Device" : message.DeviceName;
            ConnectionStatusText = message.IsConnected ? $"{dev} ({message.ConnectionType})" : "Disconnected";
        });
    }

    partial void OnRollNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnPitchNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnThrottleNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnYawNormalizedChanged(float value) => PushChannelUpdate();

    [RelayCommand]
    private void ToggleArm()
    {
        IsArmed = !IsArmed;
        OnPropertyChanged(nameof(ArmText));
        _logger.LogInfo($"Toggle ARM switch: {ArmText}", "TestController");
        PushChannelUpdate();
    }

    [RelayCommand]
    private void ToggleBeeper()
    {
        IsBeeperActive = !IsBeeperActive;
        OnPropertyChanged(nameof(BeeperText));
        _logger.LogInfo($"Toggle BEEPER switch: {BeeperText}", "TestController");
        PushChannelUpdate();
    }

    [RelayCommand]
    private void CycleFlightMode()
    {
        FlightModeText = FlightModeText switch
        {
            "Acro" => "Angle",
            "Angle" => "Horizon",
            _ => "Acro"
        };
        _logger.LogInfo($"Switched Flight Mode to: {FlightModeText}", "TestController");
        PushChannelUpdate();
    }

    [RelayCommand]
    private void ResetSticks()
    {
        _isInternalUpdating = true;
        try
        {
            RollNormalized = 0.0f;
            PitchNormalized = 0.0f;
            ThrottleNormalized = -1.0f;
            YawNormalized = 0.0f;
            IsArmed = false;
            IsBeeperActive = false;
            FlightModeText = "Acro";

            OnPropertyChanged(nameof(ArmText));
            OnPropertyChanged(nameof(BeeperText));
        }
        finally
        {
            _isInternalUpdating = false;
        }

        _logger.LogInfo("Reset all sticks to neutral default position.", "TestController");
        PushChannelUpdate();
    }

    private void PushChannelUpdate()
    {
        if (_isInternalUpdating) return;

        _isInternalUpdating = true;
        try
        {
            OnPropertyChanged(nameof(RollPwm));
            OnPropertyChanged(nameof(PitchPwm));
            OnPropertyChanged(nameof(ThrottlePwm));
            OnPropertyChanged(nameof(YawPwm));
            OnPropertyChanged(nameof(ArmText));
            OnPropertyChanged(nameof(BeeperText));

            ChannelData channels = new();
            channels.SetChannelNormalized(0, RollNormalized);
            channels.SetChannelNormalized(1, PitchNormalized);
            channels.SetChannelNormalized(2, ThrottleNormalized);
            channels.SetChannelNormalized(3, YawNormalized);

            channels.DigitalSwitches[0] = IsArmed;
            channels.DigitalSwitches[1] = IsBeeperActive;
            channels.SetChannelNormalized(4, IsArmed ? 1.0f : -1.0f);
            channels.SetChannelNormalized(5, IsBeeperActive ? 1.0f : -1.0f);

            _stateStore.UpdateChannels(channels);
        }
        finally
        {
            _isInternalUpdating = false;
        }
    }
}

