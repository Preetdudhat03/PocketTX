using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.VirtualController.Backends;

namespace PocketTX.Companion.VirtualController.Factory;

/// <summary>
/// Factory pattern resolving appropriate virtual controller backend implementation.
/// </summary>
public static class BackendFactory
{
    public static IVirtualControllerBackend CreateBackend(VirtualBackendType type)
    {
        return type switch
        {
            VirtualBackendType.Simulation => new SimulatedVirtualControllerBackend(),
            VirtualBackendType.ViGEm => new ViGEmBackend(),
            VirtualBackendType.HidInjector => new HidInjectorBackend(),
            VirtualBackendType.VJoy => new VJoyBackend(),
            _ => new SimulatedVirtualControllerBackend()
        };
    }
}
