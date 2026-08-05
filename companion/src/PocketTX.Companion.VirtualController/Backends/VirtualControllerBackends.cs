using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.VirtualController.Backends;

/// <summary>
/// Simulation virtual controller backend active in Phase 1.
/// </summary>
public sealed class SimulatedVirtualControllerBackend : IVirtualControllerBackend
{
    public VirtualBackendType Type => VirtualBackendType.Simulation;
    public bool IsAvailable => true;
    public bool IsConnected { get; private set; } = false;

    public float[] CurrentNormalizedChannels { get; } = new float[8];
    public bool[] CurrentSwitches { get; } = new bool[8];

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
    {
        IsConnected = true;
        return Task.FromResult(true);
    }

    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default)
    {
        if (!IsConnected) return Task.CompletedTask;

        int len = System.Math.Min(normalizedChannels.Length, CurrentNormalizedChannels.Length);
        Array.Copy(normalizedChannels, CurrentNormalizedChannels, len);

        int switchLen = System.Math.Min(switches.Length, CurrentSwitches.Length);
        Array.Copy(switches, CurrentSwitches, switchLen);

        return Task.CompletedTask;
    }

    public Task ResetAsync(CancellationToken cancellationToken = default)
    {
        Array.Clear(CurrentNormalizedChannels, 0, CurrentNormalizedChannels.Length);
        Array.Clear(CurrentSwitches, 0, CurrentSwitches.Length);
        CurrentNormalizedChannels[2] = -1.0f; // Throttle low
        return Task.CompletedTask;
    }

    public Task ShutdownAsync(CancellationToken cancellationToken = default)
    {
        IsConnected = false;
        return Task.CompletedTask;
    }
}

/// <summary>
/// Future ViGEmBus virtual controller backend stub.
/// </summary>
public sealed class ViGEmBackend : IVirtualControllerBackend
{
    public VirtualBackendType Type => VirtualBackendType.ViGEm;
    public bool IsAvailable => false; // Future phase capability check
    public bool IsConnected => false;

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
        => Task.FromException<bool>(new NotSupportedException("ViGEmBus backend will be integrated in a future phase."));
    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ResetAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ShutdownAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
}

/// <summary>
/// Future HID Injector virtual controller backend stub.
/// </summary>
public sealed class HidInjectorBackend : IVirtualControllerBackend
{
    public VirtualBackendType Type => VirtualBackendType.HidInjector;
    public bool IsAvailable => false;
    public bool IsConnected => false;

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
        => Task.FromException<bool>(new NotSupportedException("Raw HID Injector backend will be integrated in a future phase."));
    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ResetAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ShutdownAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
}

/// <summary>
/// Legacy vJoy virtual controller backend stub.
/// </summary>
public sealed class VJoyBackend : IVirtualControllerBackend
{
    public VirtualBackendType Type => VirtualBackendType.VJoy;
    public bool IsAvailable => false;
    public bool IsConnected => false;

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
        => Task.FromException<bool>(new NotSupportedException("vJoy is retained for legacy compatibility only."));
    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ResetAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
    public Task ShutdownAsync(CancellationToken cancellationToken = default) => Task.CompletedTask;
}
