using Microsoft.Extensions.DependencyInjection;

namespace PocketTX.Companion.Shared.Extensions;

/// <summary>
/// Service collection extension for registering Shared project dependencies.
/// </summary>
public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddShared(this IServiceCollection services)
    {
        // Shared layer helpers / services can be registered here.
        return services;
    }
}
