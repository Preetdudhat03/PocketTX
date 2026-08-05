using Microsoft.Extensions.Hosting;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Services.Simulator;

namespace PocketTX.Companion.Services.Background;

public sealed class SimulatorPollingService : BackgroundService
{
    private readonly SimulatorDetectorService _detector;
    private readonly ILoggerService _logger;

    public SimulatorPollingService(SimulatorDetectorService detector, ILoggerService logger)
    {
        _detector = detector;
        _logger = logger;
    }

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        _logger.LogInfo("SimulatorPollingService started (0.5Hz / 2s scan).", "BackgroundService");
        PeriodicTimer timer = new(TimeSpan.FromSeconds(2));

        while (!stoppingToken.IsCancellationRequested && await timer.WaitForNextTickAsync(stoppingToken))
        {
            try
            {
                _detector.ScanForSimulator();
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                _logger.LogWarning($"Error in SimulatorPollingService: {ex.Message}", "BackgroundService");
            }
        }

        _logger.LogInfo("SimulatorPollingService stopped.", "BackgroundService");
    }
}
