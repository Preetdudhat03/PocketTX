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
            _discoveryListener = new UdpClient();
            _discoveryListener.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
            _discoveryListener.Client.Bind(new IPEndPoint(IPAddress.Any, 18456));
            _discoveryListener.EnableBroadcast = true;

            _dataListener = new UdpClient();
            _dataListener.Client.SetSocketOption(SocketOptionLevel.Socket, SocketOptionName.ReuseAddress, true);
            _dataListener.Client.Bind(new IPEndPoint(IPAddress.Any, 18457));
            _dataListener.EnableBroadcast = true;

            _cts = new CancellationTokenSource();
            IsConnected = true;
            ConnectionStateChanged?.Invoke(this, true);

            _ = DiscoveryLoopAsync(_cts.Token);
            _ = DataLoopAsync(_cts.Token);
            return Task.FromResult(true);
        }
        catch (Exception ex)
        {
            string errStr = $"[WifiChannel.OpenAsync Fatal Exception] {ex}";
            System.Diagnostics.Debug.WriteLine(errStr);
            Console.WriteLine(errStr);
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
                string hexDump = BitConverter.ToString(result.Buffer);
                string logMsg = $"[UDP RX Discovery 18456] Received {result.Buffer.Length} bytes from {result.RemoteEndPoint} -> Hex: {hexDump}";
                System.Diagnostics.Debug.WriteLine(logMsg);
                Console.WriteLine(logMsg);

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
                        string txLog = $"[UDP TX ACK 18456] Sending ACK to {result.RemoteEndPoint} ({ackBytes.Length} bytes) -> Hex: {BitConverter.ToString(ackBytes)}";
                        System.Diagnostics.Debug.WriteLine(txLog);
                        Console.WriteLine(txLog);

                        await _discoveryListener.SendAsync(ackBytes, ackBytes.Length, result.RemoteEndPoint);
                    }
                    PacketReceived?.Invoke(this, result.Buffer);
                }
                else
                {
                    string errLog = $"[UDP RX Discovery 18456] Deserialization failed for {result.Buffer.Length} bytes from {result.RemoteEndPoint}";
                    System.Diagnostics.Debug.WriteLine(errLog);
                    Console.WriteLine(errLog);
                }
            }
            catch (OperationCanceledException)
            {
                break;
            }
            catch (Exception ex)
            {
                string excLog = $"[UDP RX Discovery 18456 Error] {ex.Message}";
                System.Diagnostics.Debug.WriteLine(excLog);
                Console.WriteLine(excLog);
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

                string hexDump = BitConverter.ToString(result.Buffer);
                string logMsg = $"[UDP RX Data 18457] Received {result.Buffer.Length} bytes from {result.RemoteEndPoint} -> Hex: {hexDump}";
                System.Diagnostics.Debug.WriteLine(logMsg);
                Console.WriteLine(logMsg);

                // Strict Packet Validation pipeline
                if (!PacketSerializer.TryDeserialize(result.Buffer, out var packet) || packet == null)
                {
                    string errLog = $"[UDP RX Data 18457] Validation failed for {result.Buffer.Length} bytes from {result.RemoteEndPoint}";
                    System.Diagnostics.Debug.WriteLine(errLog);
                    Console.WriteLine(errLog);
                    continue; // Reject malformed packet
                }

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
                    string txLog = $"[UDP TX ACK 18457] Sending ACK to {result.RemoteEndPoint} ({ackBytes.Length} bytes) -> Hex: {BitConverter.ToString(ackBytes)}";
                    System.Diagnostics.Debug.WriteLine(txLog);
                    Console.WriteLine(txLog);

                    await _dataListener.SendAsync(ackBytes, ackBytes.Length, result.RemoteEndPoint);
                }
                else if (packet.Header.Type == PacketType.Heartbeat)
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

/// <summary>
/// USB/ADB Wired Channel — TCP server on port 18458.
/// Phone connects via: adb reverse tcp:18458 tcp:18458
/// Frames are 2-byte big-endian length-prefixed for TCP stream reassembly.
/// </summary>
public sealed class UsbChannel : ICommunicationChannel
{
    private const int TcpPort = 18458;

    private TcpListener? _listener;
    private TcpClient? _client;
    private NetworkStream? _stream;
    private CancellationTokenSource? _cts;

    public ConnectionType Type => ConnectionType.Usb;
    public bool IsConnected { get; private set; }

    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected) return Task.FromResult(true);
        try
        {
            _cts = new CancellationTokenSource();
            _listener = new TcpListener(IPAddress.Any, TcpPort);
            _listener.Start();
            IsConnected = true;
            ConnectionStateChanged?.Invoke(this, true);
            Console.WriteLine($"[USB TCP] Listening on port {TcpPort}. Run: adb reverse tcp:{TcpPort} tcp:{TcpPort}");
            _ = AcceptLoopAsync(_cts.Token);
            return Task.FromResult(true);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[USB TCP] OpenAsync failed: {ex.Message}");
            return Task.FromResult(false);
        }
    }

    private async Task AcceptLoopAsync(CancellationToken token)
    {
        while (!token.IsCancellationRequested)
        {
            try
            {
                var client = await _listener!.AcceptTcpClientAsync(token);
                // Only one phone at a time — drop previous client
                _client?.Close();
                _client = client;
                _stream = client.GetStream();
                Console.WriteLine($"[USB TCP] Phone connected from {client.Client.RemoteEndPoint}");
                _ = ReadLoopAsync(_stream, token);
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex) { Console.WriteLine($"[USB TCP] AcceptLoop error: {ex.Message}"); }
        }
    }

    private async Task ReadLoopAsync(NetworkStream stream, CancellationToken token)
    {
        var lenBuf = new byte[2];
        while (!token.IsCancellationRequested)
        {
            try
            {
                // Read 2-byte frame length
                int read = 0;
                while (read < 2)
                {
                    int n = await stream.ReadAsync(lenBuf.AsMemory(read, 2 - read), token);
                    if (n == 0) { Console.WriteLine("[USB TCP] Client disconnected."); return; }
                    read += n;
                }
                int payloadLen = (lenBuf[0] << 8) | lenBuf[1];
                if (payloadLen <= 0 || payloadLen > 4096) continue;

                // Read full payload
                var payload = new byte[payloadLen];
                read = 0;
                while (read < payloadLen)
                {
                    int n = await stream.ReadAsync(payload.AsMemory(read, payloadLen - read), token);
                    if (n == 0) { Console.WriteLine("[USB TCP] Client disconnected mid-frame."); return; }
                    read += n;
                }

                string hexDump = BitConverter.ToString(payload);
                Console.WriteLine($"[USB TCP RX] Received {payloadLen} bytes -> Hex: {hexDump}");

                if (PacketSerializer.TryDeserialize(payload, out var packet) && packet != null)
                {
                    if (packet.Header.Type == PacketType.Hello)
                    {
                        var ack = new TelemetryPacket
                        {
                            Header = new PacketHeader
                            {
                                Type = PacketType.Ack,
                                SessionId = packet.Header.SessionId,
                                Sequence = packet.Header.Sequence
                            }
                        };
                        byte[] ackBytes = PacketSerializer.Serialize(ack);
                        await SendFrameAsync(ackBytes, token);
                        Console.WriteLine($"[USB TCP TX] Sent ACK ({ackBytes.Length} bytes) -> Hex: {BitConverter.ToString(ackBytes)}");
                    }
                    PacketReceived?.Invoke(this, payload);
                }
            }
            catch (OperationCanceledException) { break; }
            catch (Exception ex) { Console.WriteLine($"[USB TCP] ReadLoop error: {ex.Message}"); break; }
        }
    }

    private async Task SendFrameAsync(byte[] data, CancellationToken token = default)
    {
        if (_stream == null) return;
        var frame = new byte[2 + data.Length];
        frame[0] = (byte)(data.Length >> 8);
        frame[1] = (byte)(data.Length & 0xFF);
        Array.Copy(data, 0, frame, 2, data.Length);
        await _stream.WriteAsync(frame, token);
        await _stream.FlushAsync(token);
    }

    public Task CloseAsync(CancellationToken cancellationToken = default)
    {
        _cts?.Cancel();
        _stream?.Close();
        _client?.Close();
        _listener?.Stop();
        _client = null; _stream = null; _listener = null;
        if (IsConnected) { IsConnected = false; ConnectionStateChanged?.Invoke(this, false); }
        return Task.CompletedTask;
    }

    public async Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default)
    {
        if (_stream == null) return false;
        try { await SendFrameAsync(data, cancellationToken); return true; }
        catch { return false; }
    }
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
