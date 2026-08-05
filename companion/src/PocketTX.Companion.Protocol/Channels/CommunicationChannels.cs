using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;

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
/// Placeholder USB connection channel (Future Phase).
/// </summary>
public sealed class UsbChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Usb;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
        => throw new NotImplementedException("USB communication will be available when Android application is integrated.");
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}

/// <summary>
/// Placeholder ADB connection channel (Future Phase).
/// </summary>
public sealed class AdbChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Adb;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
        => throw new NotImplementedException("ADB communication will be available when Android application is integrated.");
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}

/// <summary>
/// Placeholder Bluetooth connection channel (Future Phase).
/// </summary>
public sealed class BluetoothChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Bluetooth;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
        => throw new NotImplementedException("Bluetooth communication will be available when Android application is integrated.");
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}

/// <summary>
/// Placeholder Wi-Fi connection channel (Future Phase).
/// </summary>
public sealed class WifiChannel : ICommunicationChannel
{
    public ConnectionType Type => ConnectionType.Wifi;
    public bool IsConnected => false;
    public event EventHandler<byte[]>? PacketReceived;
    public event EventHandler<bool>? ConnectionStateChanged;

    public Task<bool> OpenAsync(CancellationToken cancellationToken = default)
        => throw new NotImplementedException("Wi-Fi communication will be available when Android application is integrated.");
    public Task CloseAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task<bool> SendDataAsync(byte[] data, CancellationToken cancellationToken = default) => Task.FromResult(false);
}
