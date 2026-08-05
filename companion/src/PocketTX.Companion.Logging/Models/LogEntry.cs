using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.Logging.Models;

public sealed record LogEntry(
    DateTime Timestamp,
    LogLevel Level,
    string Category,
    string Message,
    Exception? Exception = null,
    Dictionary<string, object>? Metadata = null
);
