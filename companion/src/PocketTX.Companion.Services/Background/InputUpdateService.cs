using Microsoft.Extensions.Hosting;
using PocketTX.Companion.Core.Contracts;

namespace PocketTX.Companion.Services.Background;

public sealed class InputUpdateService : BackgroundService
{
    private readonly IVirtualController _virtualController;
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;

    public InputUpdateService(
        IVirtualController virtualController,
        IStateStore stateStore,
        ILoggerService logger)
    {
        _virtualController = virtualController;
        _stateStore = stateStore;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInfo("InputUpdateService started (250Hz tick).", "BackgroundService");

        // Initialize simulation backend on startup
        await _virtualController.ConnectAsync(_stateStore.CurrentBackend, stoppingToken);

        PeriodicTimer timer = new(TimeSpan.FromMilliseconds(4)); // 250 Hz
        while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                var channels = _stateStore.CurrentChannels;
                await _virtualController.UpdateInputAsync(channels, stoppingToken);

                _stateStore.UpdateDiagnostics(d =>
                {
                    d.TotalPacketsSent++;
                    d.LastPacketSentTime = DateTime.UtcNow;
                });
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogError("Error in InputUpdateService tick.", ex, "BackgroundService");
            }
        }

        _logger.LogInfo("InputUpdateService stopped.", "BackgroundService");
    }
}
