using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.UI.ViewModels;

public partial class TestControllerViewModel : ObservableObject
{
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;

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

    public ushort RollPwm => ChannelData.NormalizedToPwm(RollNormalized);
    public ushort PitchPwm => ChannelData.NormalizedToPwm(PitchNormalized);
    public ushort ThrottlePwm => ChannelData.NormalizedToPwm(ThrottleNormalized);
    public ushort YawPwm => ChannelData.NormalizedToPwm(YawNormalized);

    public TestControllerViewModel(IStateStore stateStore, ILoggerService logger)
    {
        _stateStore = stateStore;
        _logger = logger;
    }

    partial void OnRollNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnPitchNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnThrottleNormalizedChanged(float value) => PushChannelUpdate();
    partial void OnYawNormalizedChanged(float value) => PushChannelUpdate();

    [RelayCommand]
    private void ToggleArm()
    {
        IsArmed = !IsArmed;
        _logger.LogInfo($"Toggle ARM switch: {(IsArmed ? "ARMED" : "DISARMED")}", "TestController");
        PushChannelUpdate();
    }

    [RelayCommand]
    private void ToggleBeeper()
    {
        IsBeeperActive = !IsBeeperActive;
        _logger.LogInfo($"Toggle BEEPER switch: {(IsBeeperActive ? "ON" : "OFF")}", "TestController");
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
        RollNormalized = 0.0f;
        PitchNormalized = 0.0f;
        ThrottleNormalized = -1.0f;
        YawNormalized = 0.0f;
        IsArmed = false;
        IsBeeperActive = false;
        FlightModeText = "Acro";

        _logger.LogInfo("Reset all sticks to neutral default position.", "TestController");
        PushChannelUpdate();
    }

    private void PushChannelUpdate()
    {
        OnPropertyChanged(nameof(RollPwm));
        OnPropertyChanged(nameof(PitchPwm));
        OnPropertyChanged(nameof(ThrottlePwm));
        OnPropertyChanged(nameof(YawPwm));

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
}
