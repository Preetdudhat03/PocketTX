using System.Diagnostics;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.Services.Simulator;

public sealed class SimulatorDetectorService
{
    private static readonly Dictionary<string, SimulatorType> KnownSimulators = new(StringComparer.OrdinalIgnoreCase)
    {
        { "liftoff", SimulatorType.Liftoff },
        { "liftoff_microdrones", SimulatorType.Liftoff },
        { "velocidrone", SimulatorType.Velocidrone },
        { "fpvskydrive", SimulatorType.FPVSkyDive },
        { "picasim", SimulatorType.PicaSim }
    };

    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;

    public SimulatorDetectorService(IStateStore stateStore, ILoggerService logger)
    {
        _stateStore = stateStore;
        _logger = logger;
    }

    public SimulatorStatus ScanForSimulator()
    {
        try
        {
            Process[] processes = Process.GetProcesses();
            foreach (var proc in processes)
            {
                if (KnownSimulators.TryGetValue(proc.ProcessName, out SimulatorType simType))
                {
                    SimulatorStatus status = new()
                    {
                        IsDetected = true,
                        Type = simType,
                        ProcessName = proc.ProcessName,
                        ProcessId = proc.Id,
                        LastDetectedTime = DateTime.UtcNow
                    };

                    _stateStore.UpdateSimulator(status);
                    return status;
                }
            }
        }
        catch (Exception ex)
        {
            _logger.LogWarning($"Error scanning processes for simulator: {ex.Message}", "SimulatorDetector");
        }

        SimulatorStatus notRunning = SimulatorStatus.NotRunning();
        _stateStore.UpdateSimulator(notRunning);
        return notRunning;
    }
}
