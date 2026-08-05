using System.Windows;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Extensions;
using PocketTX.Companion.Logging.Extensions;
using PocketTX.Companion.Protocol.Extensions;
using PocketTX.Companion.Services.Extensions;
using PocketTX.Companion.Shared.Extensions;
using PocketTX.Companion.UI.ViewModels;
using PocketTX.Companion.UI.Views;
using PocketTX.Companion.VirtualController.Extensions;

namespace PocketTX.Companion.UI;

public partial class App : Application
{
    private readonly IHost _host;

    public App()
    {
        _host = Host.CreateDefaultBuilder()
            .ConfigureServices((context, services) =>
            {
                // Register modular extension layers
                services
                    .AddShared()
                    .AddCore()
                    .AddPocketTXLogging()
                    .AddProtocol()
                    .AddVirtualController()
                    .AddServices();

                // UI ViewModels
                services.AddSingleton<DashboardViewModel>();
                services.AddSingleton<TestControllerViewModel>();
                services.AddSingleton<DiagnosticsViewModel>();
                services.AddSingleton<ProfilesViewModel>();
                services.AddSingleton<SettingsViewModel>();
                services.AddSingleton<LogsViewModel>();
                services.AddSingleton<MainViewModel>();

                // Windows
                services.AddSingleton<MainWindow>();
            })
            .Build();
    }

    protected override async void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        await _host.StartAsync();

        // Load Settings and Profiles on Startup
        var settingsService = _host.Services.GetRequiredService<ISettingsService>();
        await settingsService.LoadSettingsAsync();

        var profileService = _host.Services.GetRequiredService<IProfileService>();
        await profileService.LoadProfilesAsync();

        var stateStore = _host.Services.GetRequiredService<IStateStore>();
        MainViewModel.ApplyThemeResource(stateStore.CurrentTheme);

        var mainWindow = _host.Services.GetRequiredService<MainWindow>();
        mainWindow.Show();
    }

    protected override async void OnExit(ExitEventArgs e)
    {
        using (_host)
        {
            await _host.StopAsync(TimeSpan.FromSeconds(5));
        }
        base.OnExit(e);
    }
}
