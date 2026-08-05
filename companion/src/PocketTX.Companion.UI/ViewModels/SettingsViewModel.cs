using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.UI.ViewModels;

public partial class SettingsViewModel : ObservableObject
{
    private readonly ISettingsService _settingsService;
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;

    [ObservableProperty]
    private ThemeType _selectedTheme = ThemeType.Dark;

    [ObservableProperty]
    private ConnectionType _selectedConnection = ConnectionType.TestMode;

    [ObservableProperty]
    private VirtualBackendType _selectedBackend = VirtualBackendType.Simulation;

    [ObservableProperty]
    private float _deadband = 0.02f;

    [ObservableProperty]
    private float _expo = 0.15f;

    [ObservableProperty]
    private bool _autoStart = false;

    [ObservableProperty]
    private bool _startMinimized = false;

    public SettingsViewModel(ISettingsService settingsService, IStateStore stateStore, ILoggerService logger)
    {
        _settingsService = settingsService;
        _stateStore = stateStore;
        _logger = logger;

        LoadFromState();
    }

    private void LoadFromState()
    {
        var settings = _stateStore.CurrentSettings;
        SelectedTheme = settings.Theme;
        SelectedConnection = settings.PreferredConnection;
        SelectedBackend = settings.PreferredVirtualBackend;
        Deadband = settings.Deadband;
        Expo = settings.Expo;
        AutoStart = settings.AutoStart;
        StartMinimized = settings.StartMinimized;
    }

    partial void OnSelectedThemeChanged(ThemeType value)
    {
        _stateStore.UpdateTheme(value);
        _logger.LogInfo($"Switched UI theme to {value}", "Settings");
    }

    [RelayCommand]
    private async Task SaveSettings()
    {
        AppSettings settings = new()
        {
            Theme = SelectedTheme,
            PreferredConnection = SelectedConnection,
            PreferredVirtualBackend = SelectedBackend,
            Deadband = Deadband,
            Expo = Expo,
            AutoStart = AutoStart,
            StartMinimized = StartMinimized,
            SelectedProfileName = _stateStore.CurrentProfile.Name
        };

        await _settingsService.SaveSettingsAsync(settings);
        _logger.LogInfo("Settings persisted to disk.", "Settings");
    }
}
