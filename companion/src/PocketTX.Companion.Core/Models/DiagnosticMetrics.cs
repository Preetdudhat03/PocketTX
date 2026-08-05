using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.Core.Models;

/// <summary>
/// Telemetry metrics for system diagnostics and health monitoring.
/// </summary>
public sealed class DiagnosticMetrics
{
    public TimeSpan ApplicationUptime { get; set; } = TimeSpan.Zero;
    public DateTime? LastPacketReceivedTime { get; set; }
    public DateTime? LastPacketSentTime { get; set; }

    public int QueueDepth { get; set; } = 0;
    public double CurrentLatencyMs { get; set; } = 0.0;
    public double AverageLatencyMs { get; set; } = 0.0;
    public double PeakLatencyMs { get; set; } = 0.0;

    public double PacketsPerSecond { get; set; } = 0.0;
    public long TotalPacketsReceived { get; set; } = 0;
    public long TotalPacketsSent { get; set; } = 0;
    public long DroppedPackets { get; set; } = 0;

    public int Fps { get; set; } = 60;
    public int InputFrequencyHz { get; set; } = 250;

    public float CpuUsagePercent { get; set; } = 0.0f;
    public double RamUsageMb { get; set; } = 0.0;
    public int ThreadCount { get; set; } = 0;

    public VirtualBackendType ActiveBackend { get; set; } = VirtualBackendType.Simulation;
}
