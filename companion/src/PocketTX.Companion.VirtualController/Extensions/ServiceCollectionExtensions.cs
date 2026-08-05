using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.Core.Contracts;

namespace PocketTX.Companion.VirtualController.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddVirtualController(this IServiceCollection services)
    {
        services.AddSingleton<IVirtualController, VirtualControllerManager>();
        return services;
    }
}
