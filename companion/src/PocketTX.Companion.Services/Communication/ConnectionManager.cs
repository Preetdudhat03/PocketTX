using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Protocol.Channels;

namespace PocketTX.Companion.Services.Communication;

public sealed class ConnectionManager : IConnectionManager
{
    private readonly IEnumerable<ICommunicationChannel> _channels;
    private readonly IStateStore _stateStore;
    private readonly ILoggerService _logger;
    private ICommunicationChannel _activeChannel;

    public ConnectionType ActiveConnectionType => _activeChannel.Type;
    public bool IsConnected => _activeChannel.IsConnected;

    public ConnectionManager(
        IEnumerable<ICommunicationChannel> channels,
        IStateStore stateStore,
        ILoggerService logger)
    {
        _channels = channels;
        _stateStore = stateStore;
        _logger = logger;
        _activeChannel = _channels.FirstOrDefault(c => c.Type == ConnectionType.TestMode) ?? new TestModeChannel();
    }

    public async Task SwitchConnectionAsync(ConnectionType connectionType, CancellationToken cancellationToken = default)
    {
        if (_activeChannel.IsConnected)
        {
            await DisconnectAsync(cancellationToken);
        }

        var targetChannel = _channels.FirstOrDefault(c => c.Type == connectionType);
        if (targetChannel == null)
        {
            _logger.LogWarning($"Requested connection channel '{connectionType}' not registered, falling back to TestMode.", "ConnectionManager");
            targetChannel = new TestModeChannel();
        }

        _activeChannel = targetChannel;
        _stateStore.UpdateConnectionStatus(_activeChannel.Type, _activeChannel.IsConnected);
        _logger.LogInfo($"Switched active connection channel to {_activeChannel.Type}.", "ConnectionManager");
    }

    public async Task ConnectAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            bool success = await _activeChannel.OpenAsync(cancellationToken);
            _stateStore.UpdateConnectionStatus(_activeChannel.Type, success);
            _logger.LogInfo($"Connection established on {_activeChannel.Type}.", "ConnectionManager", new Dictionary<string, object>
            {
                { "Event", "ConnectionEstablished" },
                { "ConnectionType", _activeChannel.Type.ToString() }
            });
        }
        catch (Exception ex)
        {
            _logger.LogError($"Failed to connect on {_activeChannel.Type}: {ex.Message}", ex, "ConnectionManager");
            _stateStore.UpdateConnectionStatus(_activeChannel.Type, false);
        }
    }

    public async Task DisconnectAsync(CancellationToken cancellationToken = default)
    {
        await _activeChannel.CloseAsync(cancellationToken);
        _stateStore.UpdateConnectionStatus(_activeChannel.Type, false);
        _logger.LogInfo($"Disconnected from {_activeChannel.Type}.", "ConnectionManager");
    }
}
