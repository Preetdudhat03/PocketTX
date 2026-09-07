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
    private readonly IStateStore _stateStore;

    public VirtualBackendType ActiveBackendType => _activeBackend.Type;
    public bool IsConnected => _activeBackend.IsConnected;

    public VirtualControllerManager(IStateStore stateStore, CommunityToolkit.Mvvm.Messaging.IMessenger messenger)
    {
        _stateStore = stateStore;
        // Start with Simulation backend initially
        _activeBackend = BackendFactory.CreateBackend(VirtualBackendType.Simulation);
        AppDomain.CurrentDomain.ProcessExit += (s, e) => Dispose();

        messenger.Register<VirtualControllerManager, PocketTX.Companion.Services.Messages.SettingsChangedMessage>(this, (r, m) =>
        {
            _ = r.ConnectAsync(m.Settings.PreferredVirtualBackend);
        });

        // Initialize with default or loaded settings immediately, though LoadSettingsAsync will trigger the messenger later
        _ = ConnectAsync(VirtualBackendType.ViGEm);
    }

    public async Task ConnectAsync(VirtualBackendType backendType, CancellationToken cancellationToken = default)
    {
        await _semaphore.WaitAsync(cancellationToken);
        try
        {
            if (_activeBackend.IsConnected)
            {
                await _activeBackend.ShutdownAsync(cancellationToken);
                _activeBackend.Dispose();
            }

            _activeBackend = BackendFactory.CreateBackend(backendType);

            bool ok = false;
            try
            {
                ok = await _activeBackend.InitializeAsync(cancellationToken);
            }
            catch {}

            if (!ok)
            {
                // Fallback to vJoy if ViGEm fails, then Simulation
                if (backendType == VirtualBackendType.ViGEm)
                {
                    _activeBackend = BackendFactory.CreateBackend(VirtualBackendType.VJoy);
                    try { ok = await _activeBackend.InitializeAsync(cancellationToken); } catch {}
                }

                if (!ok)
                {
                    _activeBackend = BackendFactory.CreateBackend(VirtualBackendType.Simulation);
                    await _activeBackend.InitializeAsync(cancellationToken);
                }
            }

            _stateStore.UpdateBackend(_activeBackend.Type);
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
                _activeBackend.Dispose();
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
            if (i < 4)
            {
                // Apply neutral deadband/expo transformation to main stick axes
                transformedChannels[i] = AxisTransformer.Transform(channelData.NormalizedValues[i], 0.02f, 0.15f);
            }
            else
            {
                // Pass auxiliary channels (ARM, BEEPER, Aux3, Aux4) raw
                transformedChannels[i] = channelData.NormalizedValues[i];
            }
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

    public void Dispose()
    {
        try
        {
            _activeBackend.Dispose();
        }
        catch {}
    }

    public async ValueTask DisposeAsync()
    {
        try
        {
            await _activeBackend.DisposeAsync();
        }
        catch {}
    }
}
