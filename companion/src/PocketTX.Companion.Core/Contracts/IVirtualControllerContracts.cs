using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;

namespace PocketTX.Companion.Core.Contracts;

public interface IVirtualControllerBackend : IDisposable, IAsyncDisposable
{
    VirtualBackendType Type { get; }
    bool IsAvailable { get; }
    bool IsConnected { get; }

    Task<bool> InitializeAsync(CancellationToken cancellationToken = default);
    Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default);
    Task ResetAsync(CancellationToken cancellationToken = default);
    Task ShutdownAsync(CancellationToken cancellationToken = default);
}

public interface IVirtualController : IDisposable, IAsyncDisposable
{
    VirtualBackendType ActiveBackendType { get; }
    bool IsConnected { get; }

    Task ConnectAsync(VirtualBackendType backendType, CancellationToken cancellationToken = default);
    Task DisconnectAsync(CancellationToken cancellationToken = default);
    Task UpdateInputAsync(ChannelData channelData, CancellationToken cancellationToken = default);
    Task ResetAsync(CancellationToken cancellationToken = default);
}

