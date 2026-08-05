using CommunityToolkit.Mvvm.ComponentModel;
using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Services.Messages;
using System.Windows;

namespace PocketTX.Companion.UI.ViewModels;

public partial class DiagnosticsViewModel : ObservableObject, IRecipient<DiagnosticMetricsUpdatedMessage>
{
    private readonly IStateStore _stateStore;

    [ObservableProperty]
    private string _uptimeText = "00:00:00";

    [ObservableProperty]
    private string _lastPacketReceivedText = "N/A (Test Mode)";

    [ObservableProperty]
    private string _lastPacketSentText = "Just now";

    [ObservableProperty]
    private int _queueDepth = 0;

    [ObservableProperty]
    private double _currentLatencyMs = 1.2;

    [ObservableProperty]
    private double _avgLatencyMs = 1.3;

    [ObservableProperty]
    private double _peakLatencyMs = 2.1;

    [ObservableProperty]
    private double _packetsPerSecond = 250;

    [ObservableProperty]
    private long _totalPacketsSent = 0;

    [ObservableProperty]
    private long _droppedPackets = 0;

    [ObservableProperty]
    private int _fps = 60;

    [ObservableProperty]
    private float _cpuUsagePercent = 0.5f;

    [ObservableProperty]
    private double _ramUsageMb = 48.0;

    [ObservableProperty]
    private int _threadCount = 12;

    [ObservableProperty]
    private string _activeBackendText = "Simulation";

    public DiagnosticsViewModel(IStateStore stateStore, IMessenger messenger)
    {
        _stateStore = stateStore;
        messenger.RegisterAll(this);
        UpdateFromMetrics(_stateStore.Diagnostics);
    }

    public void Receive(DiagnosticMetricsUpdatedMessage message)
    {
        Application.Current?.Dispatcher.InvokeAsync(() =>
        {
            UpdateFromMetrics(message.Metrics);
        });
    }

    private void UpdateFromMetrics(DiagnosticMetrics metrics)
    {
        UptimeText = metrics.ApplicationUptime.ToString(@"hh\:mm\:ss");
        LastPacketReceivedText = metrics.LastPacketReceivedTime.HasValue ? metrics.LastPacketReceivedTime.Value.ToString("HH:mm:ss.fff") : "N/A (Test Mode)";
        LastPacketSentText = metrics.LastPacketSentTime.HasValue ? metrics.LastPacketSentTime.Value.ToString("HH:mm:ss.fff") : "N/A";
        QueueDepth = metrics.QueueDepth;
        CurrentLatencyMs = metrics.CurrentLatencyMs;
        AvgLatencyMs = metrics.AverageLatencyMs;
        PeakLatencyMs = metrics.PeakLatencyMs;
        PacketsPerSecond = metrics.PacketsPerSecond;
        TotalPacketsSent = metrics.TotalPacketsSent;
        DroppedPackets = metrics.DroppedPackets;
        Fps = metrics.Fps;
        CpuUsagePercent = metrics.CpuUsagePercent;
        RamUsageMb = metrics.RamUsageMb;
        ThreadCount = metrics.ThreadCount;
        ActiveBackendText = metrics.ActiveBackend.ToString();
    }
}
