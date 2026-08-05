using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Protocol.Channels;

namespace PocketTX.Companion.Protocol.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddProtocol(this IServiceCollection services)
    {
        services.AddSingleton<ICommunicationChannel, TestModeChannel>();
        services.AddTransient<UsbChannel>();
        services.AddTransient<AdbChannel>();
        services.AddTransient<BluetoothChannel>();
        services.AddTransient<WifiChannel>();
        return services;
    }
}
