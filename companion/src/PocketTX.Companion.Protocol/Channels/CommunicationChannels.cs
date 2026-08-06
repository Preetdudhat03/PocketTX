using System.Net;
using System.Net.Sockets;
using System.Buffers.Binary;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Protocol.Packets;
using PocketTX.Companion.Protocol.Serializers;

namespace PocketTX.Companion.Protocol.Channels;

/// <summary>
/// Active Phase 1 simulation channel for Test Mode operation.
/// </summary>
public sealed class TestModeChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.TestMode;
    public bool IsConnected { get; private set; } = false;

    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
    {
        IsConnected = true;
        ConnectionStateChanged?.Invoke(this, true);
        return Task.FromResult(true);
    }

    public Task CloseAsync(CancellationToken cancellationToken = default)
    {
        IsConnected = false;
        ConnectionStateChanged?.Invoke(this, false);
        return Task.CompletedTask;
    }

    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default)
    {
        if (!IsConnected) return Task.FromResult(false);
        PacketReceived?.Invoke(this, data);
        return Task.FromResult(true);
    }
}

/// <summary>
/// Active Wi-Fi / UDP Socket Channel for mobile app binary protocol communication.
/// Port 18456 = UDP Discovery Broadcasts
/// Port 18457 = Real-time Controller Data & Heartbeats
/// </summary>
public sealed class WifiChannel : ICommunicationChannel
{
    private UdpClient? _discoveryListener;
    private UdpClient? _dataListener;
    private CancellationTokenSource? _cts;
    private IPEndPoint? _clientEndpoint;
    private readonly DateTime _startTime = DateTime.UtcNow;

    public ConnectionType Type => ConnectionType.Wifi;
    public bool IsConnected { get; private set; }

    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected) return Task.FromResult(true);

        try
        {
            _discoveryListener = new UdpClient(18456);
            _discoveryListener.EnableBroadcast = true;

            _dataListener = new UdpClient(18457);
            _dataListener.EnableBroadcast = true;

            _cts = new CancellationTokenSource();
            IsConnected = true;
            ConnectionStateChanged?.Invoke(this, true);

            _ = DiscoveryLoopAsync(_cts.Token);
            _ = DataLoopAsync(_cts.Token);
            return Task.FromResult(true);
        }
        catch
        {
            IsConnected = false;
            ConnectionStateChanged?.Invoke(this, false);
            return Task.FromResult(false);
        }
    }

    private async Task DiscoveryLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested && _discoveryListener != null)
        {
            try
            {
                var result = await _discoveryListener.ReceiveAsync(token);
                if (PacketSerializer.TryDeserialize(result.Buffer, out var packet) && packet != null)
                {
                    if (packet.Header.Type == PacketType.Hello)
                    {
                        _clientEndpoint = result.RemoteEndPoint;
                        var ackPacket = new TelemetryPacket
                        {
                            Header = new PacketHeader
                            {
                                Type = PacketType.Ack,
                                SessionId = packet.Header.SessionId,
                                Sequence = packet.Header.Sequence
                            }
                        };
                        byte[] ackBytes = PacketSerializer.Serialize(ackPacket);
                        await _discoveryListener.SendAsync(ackBytes, ackBytes.Length, result.RemoteEndPoint);
                    }
                    PacketReceived?.Invoke(this, result.Buffer);
                }
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch
            {
                // Continue loop
            }
        }
    }

    private async Task DataLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested && _dataListener != null)
        {
            try
            {
                var result = await _dataListener.ReceiveAsync(token);
                _clientEndpoint = result.RemoteEndPoint;

                // Strict Packet Validation pipeline
                if (!PacketSerializer.TryDeserialize(result.Buffer, out var packet) || packet == null)
                {
                    continue; // Reject malformed packet
                }

                if (packet.Header.Type == PacketType.Heartbeat)
                {
                    // Respond with Rich Heartbeat ACK (Companion timestamp, session ID, uptime ms)
                    ulong nowMs = (ulong)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
                    ulong uptimeMs = (ulong)(DateTime.UtcNow - _startTime).TotalMilliseconds;

                    byte[] hbAckPayload = new byte[16];
                    BinaryPrimitives.WriteUInt64BigEndian(hbAckPayload.AsSpan(0, 8), nowMs);
                    BinaryPrimitives.WriteUInt64BigEndian(hbAckPayload.AsSpan(8, 8), uptimeMs);

                    var hbAck = new TelemetryPacket
                    {
                        Header = new PacketHeader
                        {
                            Type = PacketType.Heartbeat,
                            SessionId = packet.Header.SessionId,
                            Sequence = packet.Header.Sequence,
                            PayloadLength = 16
                        },
                        Payload = hbAckPayload
                    };
                    byte[] hbBytes = PacketSerializer.Serialize(hbAck);
                    await _dataListener.SendAsync(hbBytes, hbBytes.Length, result.RemoteEndPoint);
                }
                else if (packet.Header.Type == PacketType.Disconnect)
                {
                    IsConnected = false;
                    ConnectionStateChanged?.Invoke(this, false);
                }

                PacketReceived?.Invoke(this, result.Buffer);
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch
            {
                // Continue loop
            }
        }
    }

    public Task CloseAsync(CancellationToken cancellationToken = default)
    {
        _cts?.Cancel();
        _discoveryListener?.Close();
        _discoveryListener = null;

        _dataListener?.Close();
        _dataListener = null;

        if (IsConnected)
        {
            IsConnected = false;
            ConnectionStateChanged?.Invoke(this, false);
        }
        return Task.CompletedTask;
    }

    public async Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default)
    {
        if (!IsConnected || _dataListener == null || _clientEndpoint == null) return false;
        try
        {
            await _dataListener.SendAsync(data, data.Length, _clientEndpoint);
            return true;
        }
        catch
        {
            return false;
        }
    }
}

public sealed class UsbChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Usb;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default) => Task.FromResult(false);
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}

public sealed class AdbChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Adb;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default) => Task.FromResult(false);
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}

public sealed class BluetoothChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Bluetooth;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default) => Task.FromResult(false);
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}
