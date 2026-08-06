using System.Net;
using System.Net.Sockets;
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
/// </summary>
public sealed class WifiChannel : ICommunicationChannel
{
    private UdpClient? _udpListener;
    private CancellationTokenSource? _cts;
    private IPEndPoint? _clientEndpoint;

    public ConnectionType Type => ConnectionType.Wifi;
    public bool IsConnected { get; private set; }

    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected) return Task.FromResult(true);

        try
        {
            _udpListener = new UdpClient(18456);
            _udpListener.EnableBroadcast = true;
            _cts = new CancellationTokenSource();
            IsConnected = true;
            ConnectionStateChanged?.Invoke(this, true);

            _ = ListenLoopAsync(_cts.Token);
            return Task.FromResult(true);
        }
        catch
        {
            IsConnected = false;
            ConnectionStateChanged?.Invoke(this, false);
            return Task.FromResult(false);
        }
    }

    private async Task ListenLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested && _udpListener != null)
        {
            try
            {
                var result = await _udpListener.ReceiveAsync(token);
                _clientEndpoint = result.RemoteEndPoint;

                if (PacketSerializer.TryDeserialize(result.Buffer, out var packet) && packet != null)
                {
                    if (packet.Header.Type == PacketType.Hello)
                    {
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
                        await _udpListener.SendAsync(ackBytes, ackBytes.Length, _clientEndpoint);
                    }
                    else if (packet.Header.Type == PacketType.Heartbeat)
                    {
                        byte[] hbBytes = PacketSerializer.Serialize(packet);
                        await _udpListener.SendAsync(hbBytes, hbBytes.Length, _clientEndpoint);
                    }
                    else if (packet.Header.Type == PacketType.Disconnect)
                    {
                        IsConnected = false;
                        ConnectionStateChanged?.Invoke(this, false);
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
                // Ignore transient socket glitches
            }
        }
    }

    public Task CloseAsync(CancellationToken cancellationToken = default)
    {
        _cts?.Cancel();
        _udpListener?.Close();
        _udpListener = null;

        if (IsConnected)
        {
            IsConnected = false;
            ConnectionStateChanged?.Invoke(this, false);
        }
        return Task.CompletedTask;
    }

    public async Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default)
    {
        if (!IsConnected || _udpListener == null || _clientEndpoint == null) return false;
        try
        {
            await _udpListener.SendAsync(data, data.Length, _clientEndpoint);
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
