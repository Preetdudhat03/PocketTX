using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Protocol.Channels;

namespace PocketTX.Companion.Protocol.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddProtocol(this IServiceCollection services)
    {
        services.AddSingleton<ICommunicationChannel, TestModeChannel>();
        services.AddSingleton<ICommunicationChannel, WifiChannel>();
        services.AddSingleton<ICommunicationChannel, UsbChannel>();
        services.AddSingleton<ICommunicationChannel, AdbChannel>();
        services.AddSingleton<ICommunicationChannel, BluetoothChannel>();
        return services;
    }
}
