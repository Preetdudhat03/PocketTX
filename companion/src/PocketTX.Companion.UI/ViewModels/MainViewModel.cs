using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Input;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Services.Messages;
using System.Windows;

namespace PocketTX.Companion.UI.ViewModels;

public partial class MainViewModel : ObservableObject, IRecipient<ThemeChangedMessage>
{
    private readonly IStateStore _stateStore;

    public DashboardViewModel DashboardVM { get; }
    public TestControllerViewModel TestControllerVM { get; }
    public DiagnosticsViewModel DiagnosticsVM { get; }
    public ProfilesViewModel ProfilesVM { get; }
    public SettingsViewModel SettingsVM { get; }
    public LogsViewModel LogsVM { get; }

    [ObservableProperty]
    private ObservableObject _currentView;

    [ObservableProperty]
    private string _activeViewTitle = "Dashboard";

    [ObservableProperty]
    private string _connectionBadgeText = "Test Mode Active";

    [ObservableProperty]
    private bool _isConnected = true;

    public MainViewModel(
        IStateStore stateStore,
        IMessenger messenger,
        DashboardViewModel dashboardVM,
        TestControllerViewModel testControllerVM,
        DiagnosticsViewModel diagnosticsVM,
        ProfilesViewModel profilesVM,
        SettingsViewModel settingsVM,
        LogsViewModel logsVM)
    {
        _stateStore = stateStore;
        messenger.RegisterAll(this);

        DashboardVM = dashboardVM;
        TestControllerVM = testControllerVM;
        DiagnosticsVM = diagnosticsVM;
        ProfilesVM = profilesVM;
        SettingsVM = settingsVM;
        LogsVM = logsVM;

        _currentView = DashboardVM;
    }

    [RelayCommand]
    private void Navigate(string viewName)
    {
        switch (viewName)
        {
            case "Dashboard":
                CurrentView = DashboardVM;
                ActiveViewTitle = "Dashboard";
                break;
            case "TestController":
                CurrentView = TestControllerVM;
                ActiveViewTitle = "Test Controller Mode";
                break;
            case "Diagnostics":
                CurrentView = DiagnosticsVM;
                ActiveViewTitle = "System Diagnostics";
                break;
            case "Profiles":
                CurrentView = ProfilesVM;
                ActiveViewTitle = "Profile Manager";
                break;
            case "Settings":
                CurrentView = SettingsVM;
                ActiveViewTitle = "Application Settings";
                break;
            case "Logs":
                CurrentView = LogsVM;
                ActiveViewTitle = "Log Terminal";
                break;
        }
    }

    public void Receive(ThemeChangedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            ApplyThemeResource(message.Theme);
        });
    }

    public static void ApplyThemeResource(ThemeType theme)
    {
        if (Application.Current == null) return;

        string themeUri = theme switch
        {
            ThemeType.Light => "Themes/Theme.Light.xaml",
            _ => "Themes/Theme.Dark.xaml"
        };

        var resourceDict = new ResourceDictionary
        {
            Source = new Uri(themeUri, UriKind.Relative)
        };

        Application.Current.Resources.MergedDictionaries.Clear();
        Application.Current.Resources.MergedDictionaries.Add(resourceDict);
    }
}
