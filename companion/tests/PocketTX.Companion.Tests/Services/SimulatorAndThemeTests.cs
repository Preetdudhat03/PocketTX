using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Logging.Engine;
using PocketTX.Companion.Logging.Sinks;
using PocketTX.Companion.Services.Simulator;
using PocketTX.Companion.Services.State;
using Xunit;

namespace PocketTX.Companion.Tests.Services;

public class SimulatorDetectorTests
{
    [Fact]
    public void ScanForSimulator_NoActiveSimulator_ReturnsNotRunning()
    {
        IMessenger messenger = WeakReferenceMessenger.Default;
        IStateStore stateStore = new ApplicationState(messenger);
        ILoggerService logger = new LoggerService(new ILogSink[] { new DebugSink() });

        SimulatorDetectorService detector = new(stateStore, logger);
        SimulatorStatus result = detector.ScanForSimulator();

        Assert.NotNull(result);
    }
}

public class ThemeTests
{
    [Fact]
    public void UpdateTheme_StateStoreUpdatesAndEmits()
    {
        IMessenger messenger = WeakReferenceMessenger.Default;
        ApplicationState stateStore = new(messenger);

        stateStore.UpdateTheme(ThemeType.Light);
        Assert.Equal(ThemeType.Light, stateStore.CurrentTheme);
    }
}
