using System.Diagnostics;
using System.Text;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Logging.Models;
using PocketTX.Companion.Shared.Constants;

namespace PocketTX.Companion.Logging.Sinks;

public sealed class DebugSink : ILogSink
{
    public Task EmitAsync(LogEntry logEntry, CancellationToken cancellationToken = default)
    {
        Debug.WriteLine($"[{logEntry.Timestamp:HH:mm:ss.fff}] [{logEntry.Level}] [{logEntry.Category}] {logEntry.Message}");
        if (logEntry.Exception != null)
        {
            Debug.WriteLine($"Exception: {logEntry.Exception}");
        }
        return Task.CompletedTask;
    }
}

public sealed class UISink : ILogSink
{
    private readonly IMessenger _messenger;

    public UISink(IMessenger messenger)
    {
        _messenger = messenger;
    }

    public Task EmitAsync(LogEntry logEntry, CancellationToken cancellationToken = default)
    {
        _messenger.Send(logEntry);
        return Task.CompletedTask;
    }
}

public sealed class FileSink : ILogSink
{
    private readonly string _logFolderPath;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public FileSink()
    {
        string localAppData = Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData);
        _logFolderPath = Path.Combine(localAppData, AppConstants.DefaultFolderName, AppConstants.SettingsFolderName, AppConstants.LogsFolderName);
        Directory.CreateDirectory(_logFolderPath);
    }

    public async Task EmitAsync(LogEntry logEntry, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            string fileName = $"companion_{DateTime.UtcNow:yyyy-MM-dd}.log";
            string filePath = Path.Combine(_logFolderPath, fileName);

            StringBuilder sb = new();
            sb.Append($"[{logEntry.Timestamp:yyyy-MM-dd HH:mm:ss.fff}] [{logEntry.Level}] [{logEntry.Category}] {logEntry.Message}");

            if (logEntry.Metadata != null && logEntry.Metadata.Count > 0)
            {
                sb.Append(" | Meta: ");
                foreach (var (key, value) in logEntry.Metadata)
                {
                    sb.Append($"{key}={value}; ");
                }
            }

            if (logEntry.Exception != null)
            {
                sb.AppendLine();
                sb.Append($"    Exception: {logEntry.Exception.Message}");
            }

            sb.AppendLine();
            await File.AppendAllTextAsync(filePath, sb.ToString(), cancellationToken);
        }
        catch
        {
            // Ignore file logging failures in background
        }
        finally
        {
            _semaphore.Release();
        }
    }
}
