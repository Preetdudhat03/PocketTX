using PocketTX.Companion.Logging.Models;

namespace PocketTX.Companion.Logging.Sinks;

public interface ILogSink
{
    Task EmitAsync(LogEntry logEntry, CancellationToken cancellationToken = default);
}
