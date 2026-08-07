using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Core.Models;
using PocketTX.Companion.VirtualController.Factory;
using PocketTX.Companion.VirtualController.Math;

namespace PocketTX.Companion.VirtualController;

/// <summary>
/// Orchestrates active virtual controller backend, axis transformations, and state updates.
/// </summary>
public sealed class VirtualControllerManager : IVirtualController
{
    private IVirtualControllerBackend _activeBackend;
    private readonly SemaphoreSlim _semaphore = new(1, 1);

    public VirtualBackendType ActiveBackendType => _activeBackend.Type;
    public bool IsConnected => _activeBackend.IsConnected;

    public VirtualControllerManager()
    {
        // Try vJoy first (real HID joystick visible to simulators like PicaSim).
        // Fall back to in-memory simulation if vJoy driver is not installed.
        _activeBackend = BackendFactory.CreateBackend(VirtualBackendType.VJoy);
    }

    public async Task ConnectAsync(VirtualBackendType backendType, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            if (_activeBackend.IsConnected)
            {
                await _activeBackend.ShutdownAsync(cancellationToken);
            }

            _activeBackend = BackendFactory.CreateBackend(backendType);

            try
            {
                await _activeBackend.InitializeAsync(cancellationToken);
            }
            catch
            {
                // Fallback to simulation backend if hardware/service backend fails
                _activeBackend = BackendFactory.CreateBackend(VirtualBackendType.Simulation);
                await _activeBackend.InitializeAsync(cancellationToken);
            }
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task DisconnectAsync(CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            if (_activeBackend.IsConnected)
            {
                await _activeBackend.ShutdownAsync(cancellationToken);
            }
        }
        finally
        {
            _semaphore.Release();
        }
    }

    public async Task UpdateInputAsync(ChannelData channelData, CancellationToken cancellationToken = default)
    {
        if (!IsConnected) return;

        float[] transformedChannels = new float[channelData.NormalizedValues.Length];
        for (int i = 0; i < channelData.NormalizedValues.Length; i++)
        {
            // Apply neutral deadband/expo transformation
            transformedChannels[i] = AxisTransformer.Transform(channelData.NormalizedValues[i], 0.02f, 0.15f);
        }

        await _activeBackend.UpdateChannelsAsync(transformedChannels, channelData.DigitalSwitches, cancellationToken);
    }

    public async Task ResetAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected)
        {
            await _activeBackend.ResetAsync(cancellationToken);
        }
    }
}
