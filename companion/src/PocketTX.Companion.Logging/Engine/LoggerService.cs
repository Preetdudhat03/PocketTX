using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Logging.Models;
using PocketTX.Companion.Logging.Sinks;

namespace PocketTX.Companion.Logging.Engine;

public sealed class LoggerService : ILoggerService
{
    private readonly IEnumerable<ILogSink> _sinks;

    public LoggerService(IEnumerable<ILogSink> sinks)
    {
        _sinks = sinks;
    }

    public void LogDebug(string message, string category = "General", Dictionary<string, object>? metadata = null)
        => Log(LogLevel.Debug, message, category, null, metadata);

    public void LogInfo(string message, string category = "General", Dictionary<string, object>? metadata = null)
        => Log(LogLevel.Info, message, category, null, metadata);

    public void LogWarning(string message, string category = "General", Dictionary<string, object>? metadata = null)
        => Log(LogLevel.Warning, message, category, null, metadata);

    public void LogError(string message, Exception? exception = null, string category = "General", Dictionary<string, object>? metadata = null)
        => Log(LogLevel.Error, message, category, exception, metadata);

    private void Log(LogLevel level, string message, string category, Exception? exception, Dictionary<string, object>? metadata)
    {
        LogEntry entry = new(DateTime.UtcNow, level, category, message, exception, metadata);
        foreach (var sink in _sinks)
        {
            _ = sink.EmitAsync(entry);
        }
    }
}
