using System.Diagnostics;
using System.Text.RegularExpressions;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.Services.Simulator;

public sealed class SimulatorDetectorService
{
    private static readonly Dictionary<string, SimulatorType> KnownSimulators = new(StringComparer.OrdinalIgnoreCase)
    {
        // Liftoff
        { "liftoff", SimulatorType.Liftoff },
        { "liftoffmicrodrones", SimulatorType.Liftoff },

        // VelociDrone
        { "velocidrone", SimulatorType.Velocidrone },

        // FPV.Skydive
        { "fpvskydive", SimulatorType.FPVSkyDive },
        { "fpvskydrive", SimulatorType.FPVSkyDive }, // Legacy typo alias
        { "skydive", SimulatorType.FPVSkyDive },

        // PicaSim
        { "picasim", SimulatorType.PicaSim },

        // Uncrashed & RealFlight & Freerider
        { "uncrashed", SimulatorType.Custom },
        { "uncrashedwin64shipping", SimulatorType.Custom },
        { "realflight", SimulatorType.Custom },
        { "realflight32", SimulatorType.Custom },
        { "realflight64", SimulatorType.Custom },
        { "realflightevo", SimulatorType.Custom },
        { "fpvfreerider", SimulatorType.Custom },
        { "fpvfreeriderrecharged", SimulatorType.Custom },
        { "trypfpv", SimulatorType.Custom },
        { "drlsimulator", SimulatorType.Custom }
    };

    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;

    public SimulatorDetectorService(IStateStore stateStore, ILoggerService logger)
    {
        _stateStore = stateStore;
        _logger = logger;
    }

    private static string NormalizeProcessName(string rawName)
    {
        // Remove non-alphanumeric characters (. - _ space) for robust matching
        return Regex.Replace(rawName, @"[^a-zA-Z0-9]", "").ToLowerInvariant();
    }

    public SimulatorStatus ScanForSimulator()
    {
        try
        {
            Process[] processes = Process.GetProcesses();
            foreach (var proc in processes)
            {
                string procName = proc.ProcessName;
                string normalized = NormalizeProcessName(procName);

                if (KnownSimulators.TryGetValue(procName, out SimulatorType simType) ||
                    KnownSimulators.TryGetValue(normalized, out simType))
                {
                    SimulatorStatus status = new()
                    {
                        IsDetected = true,
                        Type = simType,
                        ProcessName = procName,
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

