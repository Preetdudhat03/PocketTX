using Microsoft.Extensions.DependencyInjection;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Logging.Engine;
using PocketTX.Companion.Logging.Sinks;

namespace PocketTX.Companion.Logging.Extensions;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddLogging(this IServiceCollection services)
    {
        services.AddSingleton<ILogSink, DebugSink>();
        services.AddSingleton<ILogSink, UISink>();
        services.AddSingleton<ILogSink, FileSink>();
        services.AddSingleton<ILoggerService, LoggerService>();
        return services;
    }
}
