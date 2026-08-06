using System.Buffers.Binary;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.Protocol.Channels;
using PocketTX.Companion.Protocol.Serializers;

namespace PocketTX.Companion.Services.Communication;

public sealed class ConnectionManager : IConnectionManager
{
    private readonly IEnumerable<ICommunicationChannel> _channels;
    private readonly IStateStore _stateStore;
    private readonly IVirtualController _virtualController;
    private readonly ILoggerService _logger;
    private ICommunicationChannel _activeChannel;

    public ConnectionType ActiveConnectionType => _activeChannel.Type;
    public bool IsConnected => _activeChannel.IsConnected;

    public ConnectionManager(
        IEnumerable<ICommunicationChannel> channels,
        IStateStore stateStore,
        IVirtualController virtualController,
        ILoggerService logger)
    {
        _channels = channels;
        _stateStore = stateStore;
        _virtualController = virtualController;
        _logger = logger;

        // Default to WifiChannel if available, fallback to TestMode
        var wifiChan = _channels.FirstOrDefault(c => c.Type == ConnectionType.Wifi);
        _activeChannel = wifiChan ?? _channels.FirstOrDefault(c => c.Type == ConnectionType.TestMode) ?? new TestModeChannel();

        // Subscribe to packet events across channels
        foreach (var chan in _channels)
        {
            chan.PacketReceived += OnPacketReceived;
        }

        // Auto-start Wi-Fi UDP listener on ports 18456 & 18457
        if (wifiChan != null)
        {
            _ = wifiChan.OpenAsync();
            _stateStore.UpdateConnectionStatus(ConnectionType.Wifi, true);
        }
    }

    private void OnPacketReceived(object? sender, byte[] rawBytes)
    {
        // Auto-switch active channel to Wi-Fi on incoming mobile packet
        if (sender is WifiChannel wifiChannel && _activeChannel.Type != ConnectionType.Wifi)
        {
            _activeChannel = wifiChannel;
            _stateStore.UpdateConnectionStatus(ConnectionType.Wifi, true);
            _logger.LogInfo("Auto-switched active connection channel to Wi-Fi on incoming mobile packet.", "ConnectionManager");
        }

        if (PacketSerializer.TryDeserialize(rawBytes, out var packet) && packet != null)
        {
            _stateStore.UpdateDiagnostics(d => d.LastPacketReceivedTime = DateTime.UtcNow);

            if (packet.Header.Type == PacketType.ChannelData && packet.Payload.Length >= 16)
            {
                var channelData = new ChannelData();
                int offset = 0;
                int count = 8;

                // Self-describing payload header: [0: version (0x01)], [1: count (8)]
                if (packet.Payload.Length >= 18 && packet.Payload[0] == 0x01)
                {
                    offset = 2;
                    count = Math.Min((int)packet.Payload[1], 8);
                }

                for (int i = 0; i < count; i++)
                {
                    ushort pwm = BinaryPrimitives.ReadUInt16BigEndian(packet.Payload.AsSpan(offset + (i * 2), 2));
                    channelData.SetChannelPwm(i, pwm);
                }

                _stateStore.UpdateChannels(channelData);
                _ = _virtualController.UpdateInputAsync(channelData);
            }
        }
    }

    public async Task SwitchConnectionAsync(ConnectionType connectionType, CancellationToken cancellationToken = default)
    {
        if (_activeChannel.IsConnected && _activeChannel.Type != connectionType)
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

    public async Task ScanDevicesAsync(CancellationToken cancellationToken = default)
    {
        _logger.LogInfo("Scanning USB / ADB / WiFi / Bluetooth for mobile devices...", "DeviceScanner");

        var wifiChan = _channels.FirstOrDefault(c => c.Type == ConnectionType.Wifi);
        if (wifiChan != null && !wifiChan.IsConnected)
        {
            await wifiChan.OpenAsync(cancellationToken);
        }

        await Task.Delay(300, cancellationToken);

        var physicalChannel = _channels.FirstOrDefault(c => c.Type != ConnectionType.TestMode && c.IsConnected);
        if (physicalChannel != null)
        {
            _activeChannel = physicalChannel;
            _stateStore.UpdateConnectionStatus(_activeChannel.Type, true);
            _logger.LogInfo($"Mobile device found on {_activeChannel.Type}!", "DeviceScanner");
        }
        else
        {
            _logger.LogWarning("No mobile device detected. Test Mode (Simulation) active.", "DeviceScanner");
            _stateStore.UpdateConnectionStatus(ConnectionType.TestMode, true);
        }
    }
}
