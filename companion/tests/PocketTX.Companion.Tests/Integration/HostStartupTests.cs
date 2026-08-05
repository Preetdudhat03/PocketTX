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
using Xunit;

namespace PocketTX.Companion.Tests.Integration;

public class HostStartupTests
{
    [Fact]
    public void BuildGenericHost_AllServicesAndViewModelsRegistered_ResolvesSuccessfully()
    {
        using IHost host = Host.CreateDefaultBuilder()
            .ConfigureServices((context, services) =>
            {
                services
                    .AddShared()
                    .AddCore()
                    .AddLogging()
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

        Assert.NotNull(host.Services.GetRequiredService<IStateStore>());
        Assert.NotNull(host.Services.GetRequiredService<IVirtualController>());
        Assert.NotNull(host.Services.GetRequiredService<IConnectionManager>());
        Assert.NotNull(host.Services.GetRequiredService<IProfileService>());
        Assert.NotNull(host.Services.GetRequiredService<ISettingsService>());
        Assert.NotNull(host.Services.GetRequiredService<MainViewModel>());
        Assert.NotNull(host.Services.GetRequiredService<DashboardViewModel>());
        Assert.NotNull(host.Services.GetRequiredService<TestControllerViewModel>());
        Assert.NotNull(host.Services.GetRequiredService<DiagnosticsViewModel>());
    }
}
