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
using PocketTX.Companion.VirtualController.Extensions;

namespace PocketTX.Companion.UI;

public partial class App : Application
{
    private readonly IHost _host;
    public IServiceProvider Services => _host.Services;

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
                services
                    .AddShared()
                    .AddCore()
                    .AddPocketTXLogging()
                    .AddProtocol()
                    .AddVirtualController()
                    .AddServices();

                services.AddSingleton<DashboardViewModel>();
                services.AddSingleton<TestControllerViewModel>();
                services.AddSingleton<DiagnosticsViewModel>();
                services.AddSingleton<ProfilesViewModel>();
                services.AddSingleton<SettingsViewModel>();
                services.AddSingleton<LogsViewModel>();
                services.AddSingleton<MainViewModel>();
            })
            .Build();

        _ = _host.StartAsync();

        // Load Settings & Profiles asynchronously
        var settingsService = Services.GetRequiredService<ISettingsService>();
        _ = settingsService.LoadSettingsAsync();

        var profileService = Services.GetRequiredService<IProfileService>();
        _ = profileService.LoadProfilesAsync();
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
