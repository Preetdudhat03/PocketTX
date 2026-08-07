using CommunityToolkit.Mvvm.Messaging;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Logging.Engine;
using PocketTX.Companion.Logging.Sinks;
using PocketTX.Companion.Protocol.Channels;
using PocketTX.Companion.Services.Communication;
using PocketTX.Companion.Services.State;
using PocketTX.Companion.VirtualController;
using Xunit;

namespace PocketTX.Companion.Tests.Services;

public class ConnectionManagerTests
{
    [Fact]
    public async Task SwitchConnection_ToTestMode_ActivatesTestChannel()
    {
        IMessenger messenger = WeakReferenceMessenger.Default;
        IStateStore stateStore = new ApplicationState(messenger);
        ILoggerService logger = new LoggerService(new ILogSink[] { new DebugSink() });
        IVirtualController virtualController = new VirtualControllerManager();

        List<ICommunicationChannel> channels = new()
        {
            new TestModeChannel(),
            new UsbChannel()
        };

        ConnectionManager manager = new(channels, stateStore, virtualController, logger);

        await manager.SwitchConnectionAsync(ConnectionType.TestMode);
        Assert.Equal(ConnectionType.TestMode, manager.ActiveConnectionType);

        await manager.ConnectAsync();
        Assert.True(manager.IsConnected);
    }
}
