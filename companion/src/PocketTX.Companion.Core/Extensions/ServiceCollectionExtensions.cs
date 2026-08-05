using Microsoft.Extensions.DependencyInjection;

namespace PocketTX.Companion.Core.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddCore(this IServiceCollection services)
    {
        // Core models and contract definitions live here
        return services;
    }
}
