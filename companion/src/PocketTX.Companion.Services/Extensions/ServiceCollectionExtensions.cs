using CommunityToolkit.Mvvm.Messaging;
using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Services.Background;
using PocketTX.Companion.Services.Communication;
using PocketTX.Companion.Services.Profiles;
using PocketTX.Companion.Services.Settings;
using PocketTX.Companion.Services.Simulator;
using PocketTX.Companion.Services.State;

namespace PocketTX.Companion.Services.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddServices(this IServiceCollection services)
    {
        // Event bus & State store
        services.AddSingleton<IMessenger>(WeakReferenceMessenger.Default);
        services.AddSingleton<IStateStore, ApplicationState>();

        // Domain services
        services.AddSingleton<IConnectionManager, ConnectionManager>();
        services.AddSingleton<IProfileService, ProfileService>();
        services.AddSingleton<ISettingsService, SettingsService>();
        services.AddSingleton<SimulatorDetectorService>();

        // Hosted background services
        services.AddHostedService<InputUpdateService>();
        services.AddHostedService<SimulatorPollingService>();
        services.AddHostedService<HeartbeatService>();
        services.AddHostedService<TelemetryService>();

        return services;
    }
}
