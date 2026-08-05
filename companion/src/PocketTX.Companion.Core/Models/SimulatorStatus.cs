using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.Core.Models;

/// <summary>
/// Status representation of detected flight simulator process.
/// </summary>
public sealed class SimulatorStatus
{
    public bool IsDetected { get; set; } = false;
    public SimulatorType Type { get; set; } = SimulatorType.None;
    public string ProcessName { get; set; } = string.Empty;
    public int ProcessId { get; set; } = 0;
    public DateTime LastDetectedTime { get; set; } = DateTime.MinValue;

    public static SimulatorStatus NotRunning() => new()
    {
        IsDetected = false,
        Type = SimulatorType.None,
        ProcessName = "None detected",
        ProcessId = 0
    };
}
