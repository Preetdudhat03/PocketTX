using System.Windows;
using System.Windows.Interop;
using System.Windows.Media;
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
        RenderOptions.ProcessRenderMode = RenderMode.SoftwareOnly;

        AppDomain.CurrentDomain.UnhandledException += (s, e) =>
        {
            MessageBox.Show($"Unhandled Exception: {e.ExceptionObject}", "PocketTX Fatal Error", MessageBoxButton.OK, MessageBoxImage.Error);
        };

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

    protected override void OnStartup(StartupEventArgs e)
    {
        base.OnStartup(e);

        try
        {
            // 1. Show MainWindow IMMEDIATELY on UI thread
            var mainWindow = _host.Services.GetRequiredService<MainWindow>();
            MainWindow = mainWindow;
            mainWindow.Show();

            // 2. Start Host background services after UI window is visible
            _ = _host.StartAsync();

            // 3. Load Settings & Profiles asynchronously
            var settingsService = _host.Services.GetRequiredService<ISettingsService>();
            _ = settingsService.LoadSettingsAsync();

            var profileService = _host.Services.GetRequiredService<IProfileService>();
            _ = profileService.LoadProfilesAsync();
        }
        catch (Exception ex)
        {
            MessageBox.Show($"Startup Error: {ex.Message}\n\n{ex.StackTrace}", "PocketTX Startup Error", MessageBoxButton.OK, MessageBoxImage.Error);
        }
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
