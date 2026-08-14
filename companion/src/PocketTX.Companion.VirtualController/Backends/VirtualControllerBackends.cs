using System.Runtime.InteropServices;
using Nefarius.ViGEm.Client;
using Nefarius.ViGEm.Client.Targets;
using Nefarius.ViGEm.Client.Targets.Xbox360;
using PocketTX.Companion.Core.Contracts;
using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.VirtualController.Backends;

// ─────────────────────────────────────────────────────────────────────────────
// Simulation backend (in-memory only, no real HID device created)
// ─────────────────────────────────────────────────────────────────────────────

/// <summary>
/// Simulation virtual controller backend. Stores values in memory only.
/// No real Windows joystick device is created.
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

    public void Dispose() => _ = ShutdownAsync();
    public ValueTask DisposeAsync() { _ = ShutdownAsync(); return ValueTask.CompletedTask; }
}



// ─────────────────────────────────────────────────────────────────────────────
// ViGEmBus Virtual Xbox 360 Controller Backend
// ─────────────────────────────────────────────────────────────────────────────

/// <summary>
/// ViGEmBus virtual controller backend. Emulates a native Xbox 360 Controller in Windows.
/// Instantly recognized by PicaSim, RealFlight, Liftoff, Freerider, and all DirectInput/XInput simulators.
/// </summary>
public sealed class ViGEmBackend : IVirtualControllerBackend
{
    private ViGEmClient? _client;
    private IXbox360Controller? _controller;

    public VirtualBackendType Type => VirtualBackendType.ViGEm;
    public bool IsAvailable => true;
    public bool IsConnected { get; private set; }

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _client = new ViGEmClient();
            _controller = _client.CreateXbox360Controller();
            try
            {
                _controller.Connect();
            }
            catch (System.ComponentModel.Win32Exception wex) when (wex.NativeErrorCode == 0 || wex.Message.Contains("completed successfully"))
            {
                Console.WriteLine($"[ViGEmBus] Win32Exception 0 ignored: {wex.Message}");
            }
            IsConnected = true;
            Console.WriteLine("[ViGEmBus] Xbox 360 Virtual Controller connected successfully to Windows!");
            _ = ResetAsync(cancellationToken);
            return Task.FromResult(true);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ViGEmBus] Initialization failed: {ex.Message}");
            IsConnected = false;
            return Task.FromResult(false);
        }
    }

    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default)
    {
        if (!IsConnected || _controller == null) return Task.CompletedTask;

        try
        {
            // Map normalized [-1.0, 1.0] float values to short [-32768, 32767]
            short ScaleToShort(float norm) => (short)System.Math.Clamp((int)(norm * 32767f), -32768, 32767);

            // Channel 0: Roll / Aileron -> LeftThumbX
            if (normalizedChannels.Length > 0)
                _controller.SetAxisValue(Xbox360Axis.LeftThumbX, ScaleToShort(normalizedChannels[0]));

            // Channel 1: Pitch / Elevator -> LeftThumbY
            if (normalizedChannels.Length > 1)
                _controller.SetAxisValue(Xbox360Axis.LeftThumbY, ScaleToShort(normalizedChannels[1]));

            // Channel 2: Throttle -> RightThumbY
            if (normalizedChannels.Length > 2)
                _controller.SetAxisValue(Xbox360Axis.RightThumbY, ScaleToShort(normalizedChannels[2]));

            // Channel 3: Yaw / Rudder -> RightThumbX
            if (normalizedChannels.Length > 3)
                _controller.SetAxisValue(Xbox360Axis.RightThumbX, ScaleToShort(normalizedChannels[3]));

            // Auxiliary Channels & Switch Buttons:
            // Channel 4 (Aux1 / ARM) -> Xbox360Button.A, LeftShoulder, and LeftTrigger slider
            bool isArmed = (normalizedChannels.Length > 4 && normalizedChannels[4] > 0.0f) || (switches.Length > 0 && switches[0]);
            _controller.SetButtonState(Xbox360Button.A, isArmed);
            _controller.SetButtonState(Xbox360Button.LeftShoulder, isArmed);
            byte ltVal = isArmed ? (byte)255 : (byte)0;
            if (normalizedChannels.Length > 4)
            {
                ltVal = (byte)System.Math.Clamp((int)(((normalizedChannels[4] + 1.0f) / 2.0f) * 255f), 0, 255);
            }
            _controller.SetSliderValue(Xbox360Slider.LeftTrigger, ltVal);

            // Channel 5 (Aux2 / BEEPER) -> Xbox360Button.B, RightShoulder, and RightTrigger slider
            bool isBeeper = (normalizedChannels.Length > 5 && normalizedChannels[5] > 0.0f) || (switches.Length > 1 && switches[1]);
            _controller.SetButtonState(Xbox360Button.B, isBeeper);
            _controller.SetButtonState(Xbox360Button.RightShoulder, isBeeper);
            byte rtVal = isBeeper ? (byte)255 : (byte)0;
            if (normalizedChannels.Length > 5)
            {
                rtVal = (byte)System.Math.Clamp((int)(((normalizedChannels[5] + 1.0f) / 2.0f) * 255f), 0, 255);
            }
            _controller.SetSliderValue(Xbox360Slider.RightTrigger, rtVal);

            // Channel 6 (Aux3) -> Xbox360Button.X
            bool aux3 = (normalizedChannels.Length > 6 && normalizedChannels[6] > 0.0f) || (switches.Length > 2 && switches[2]);
            _controller.SetButtonState(Xbox360Button.X, aux3);

            // Channel 7 (Aux4) -> Xbox360Button.Y
            bool aux4 = (normalizedChannels.Length > 7 && normalizedChannels[7] > 0.0f) || (switches.Length > 3 && switches[3]);
            _controller.SetButtonState(Xbox360Button.Y, aux4);

            _controller.SubmitReport();
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[ViGEmBus] UpdateChannels error: {ex.Message}");
        }

        return Task.CompletedTask;
    }

    public Task ResetAsync(CancellationToken cancellationToken = default)
    {
        if (!IsConnected || _controller == null) return Task.CompletedTask;

        _controller.SetAxisValue(Xbox360Axis.LeftThumbX, 0);
        _controller.SetAxisValue(Xbox360Axis.LeftThumbY, 0);
        _controller.SetAxisValue(Xbox360Axis.RightThumbY, -32768); // Throttle low
        _controller.SetAxisValue(Xbox360Axis.RightThumbX, 0);

        _controller.SetButtonState(Xbox360Button.A, false);
        _controller.SetButtonState(Xbox360Button.B, false);
        _controller.SetButtonState(Xbox360Button.X, false);
        _controller.SetButtonState(Xbox360Button.Y, false);
        _controller.SetButtonState(Xbox360Button.LeftShoulder, false);
        _controller.SetButtonState(Xbox360Button.RightShoulder, false);
        _controller.SetSliderValue(Xbox360Slider.LeftTrigger, 0);
        _controller.SetSliderValue(Xbox360Slider.RightTrigger, 0);

        _controller.SubmitReport();

        return Task.CompletedTask;
    }

    public Task ShutdownAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            _controller?.Disconnect();
            _client?.Dispose();
        }
        catch {}
        finally
        {
            _controller = null;
            _client = null;
            IsConnected = false;
        }
        return Task.CompletedTask;
    }

    public void Dispose() => _ = ShutdownAsync();
    public ValueTask DisposeAsync() { _ = ShutdownAsync(); return ValueTask.CompletedTask; }
}

/// <summary>Future HID Injector virtual controller backend stub.</summary>
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
    public void Dispose() {}
    public ValueTask DisposeAsync() => ValueTask.CompletedTask;
}

// ─────────────────────────────────────────────────────────────────────────────
// P/Invoke declarations for vJoyInterface.dll
// Requires vJoy driver installed: https://github.com/shauleiz/vJoy/releases
// DLL location: C:\Program Files\vJoy\x64\vJoyInterface.dll
// ─────────────────────────────────────────────────────────────────────────────

internal enum VjdStat
{
    VJD_STAT_OWN,   // Device is owned by this process
    VJD_STAT_FREE,  // Device is free - can be acquired
    VJD_STAT_BUSY,  // Device is busy - owned by another process
    VJD_STAT_MISS,  // Device is not installed or disabled
    VJD_STAT_UNKN   // Unknown
}

internal enum HID_USAGES
{
    HID_USAGE_X   = 0x30,
    HID_USAGE_Y   = 0x31,
    HID_USAGE_Z   = 0x32,
    HID_USAGE_RX  = 0x33,
    HID_USAGE_RY  = 0x34,
    HID_USAGE_RZ  = 0x35,
    HID_USAGE_SL0 = 0x36,
    HID_USAGE_SL1 = 0x37,
}

[StructLayout(LayoutKind.Sequential)]
internal struct JoystickPosition
{
    public byte bDevice;
    public int wThrottle;
    public int wRudder;
    public int wAileron;
    public int wAxisX;
    public int wAxisY;
    public int wAxisZ;
    public int wAxisXRot;
    public int wAxisYRot;
    public int wAxisZRot;
    public int wSlider;
    public int wDial;
    public int wWheel;
    public int wAxisVX;
    public int wAxisVY;
    public int wAxisVZ;
    public int wAxisVBRX;
    public int wAxisVBRY;
    public int wAxisVBRZ;
    public uint lButtons;
    public uint bHats;
    public uint bHatsEx1;
    public uint bHatsEx2;
    public uint bHatsEx3;
    public uint lButtonsEx1;
    public uint lButtonsEx2;
    public uint lButtonsEx3;
}

internal static class VJoyNative
{
    private const string DLL = "vJoyInterface.dll";

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern bool vJoyEnabled();

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern VjdStat GetVJDStatus(uint rID);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern bool AcquireVJD(uint rID);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern void RelinquishVJD(uint rID);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern bool ResetVJD(uint rID);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern bool UpdateVJD(uint rID, ref JoystickPosition pData);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern long GetVJDAxisMax(uint rID, HID_USAGES Axis);

    [DllImport(DLL, CallingConvention = CallingConvention.Cdecl)]
    public static extern long GetVJDAxisMin(uint rID, HID_USAGES Axis);
}

// ─────────────────────────────────────────────────────────────────────────────
// Real vJoy backend — feeds actual HID axis data to vJoy Device 1
// Simulators (PicaSim, RealFlight, etc.) see this as a real joystick.
// ─────────────────────────────────────────────────────────────────────────────

/// <summary>
/// vJoy backend that creates a real Windows HID joystick device.
/// Requires vJoy driver to be installed and Device 1 configured.
/// Falls back gracefully if vJoy is not installed.
/// </summary>
public sealed class VJoyBackend : IVirtualControllerBackend
{
    private const uint DeviceId = 1;
    private const int AxisMin  = 1;
    private const int AxisMax  = 32768;
    private const int AxisMid  = 16384;

    public VirtualBackendType Type => VirtualBackendType.VJoy;
    public bool IsAvailable => TryCheckAvailable();
    public bool IsConnected { get; private set; }

    private JoystickPosition _pos;
    private long _axisMax = AxisMax;
    private long _axisMin = AxisMin;

    private static bool TryCheckAvailable()
    {
        try { return VJoyNative.vJoyEnabled(); }
        catch (DllNotFoundException) { return false; }
    }

    public Task<bool> InitializeAsync(CancellationToken cancellationToken = default)
    {
        try
        {
            if (!VJoyNative.vJoyEnabled())
            {
                Console.WriteLine("[vJoy] vJoy driver is not enabled or not installed.");
                return Task.FromResult(false);
            }

            var status = VJoyNative.GetVJDStatus(DeviceId);
            Console.WriteLine($"[vJoy] Device {DeviceId} status: {status}");

            if (status != VjdStat.VJD_STAT_FREE && status != VjdStat.VJD_STAT_OWN)
            {
                Console.WriteLine($"[vJoy] Device {DeviceId} not free (status={status}). Cannot acquire.");
                return Task.FromResult(false);
            }

            if (!VJoyNative.AcquireVJD(DeviceId))
            {
                Console.WriteLine($"[vJoy] Failed to acquire Device {DeviceId}.");
                return Task.FromResult(false);
            }

            _axisMax = VJoyNative.GetVJDAxisMax(DeviceId, HID_USAGES.HID_USAGE_X);
            _axisMin = VJoyNative.GetVJDAxisMin(DeviceId, HID_USAGES.HID_USAGE_X);
            if (_axisMax <= 0) _axisMax = AxisMax;

            VJoyNative.ResetVJD(DeviceId);
            _pos = new JoystickPosition { bDevice = (byte)DeviceId };
            _pos.wAxisX    = AxisMid;
            _pos.wAxisY    = AxisMid;
            _pos.wAxisZ    = AxisMid;
            _pos.wAxisXRot = AxisMid;
            _pos.wAxisYRot = AxisMid;
            _pos.wAxisZRot = AxisMid;
            _pos.wThrottle = AxisMin;
            VJoyNative.UpdateVJD(DeviceId, ref _pos);

            IsConnected = true;
            Console.WriteLine($"[vJoy] Device {DeviceId} acquired. AxisRange=[{_axisMin}..{_axisMax}]. Ready.");
            return Task.FromResult(true);
        }
        catch (DllNotFoundException ex)
        {
            Console.WriteLine($"[vJoy] vJoyInterface.dll not found. Install vJoy driver. Details: {ex.Message}");
            return Task.FromResult(false);
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[vJoy] InitializeAsync error: {ex.Message}");
            return Task.FromResult(false);
        }
    }

    public Task UpdateChannelsAsync(float[] normalizedChannels, bool[] switches, CancellationToken cancellationToken = default)
    {
        if (!IsConnected) return Task.CompletedTask;

        // Map normalized [-1..+1] → vJoy axis integer [AxisMin..AxisMax]
        int Map(float n) => (int)(((n + 1.0f) / 2.0f) * (_axisMax - _axisMin) + _axisMin);

        // RC channel mapping:
        // Ch0 = Roll    → X axis
        // Ch1 = Pitch   → Y axis
        // Ch2 = Throttle→ Z axis
        // Ch3 = Yaw     → X rotation (Rudder)
        // Ch4-7         → additional axes
        if (normalizedChannels.Length > 0) _pos.wAxisX    = Map(normalizedChannels[0]);
        if (normalizedChannels.Length > 1) _pos.wAxisY    = Map(normalizedChannels[1]);
        if (normalizedChannels.Length > 2) _pos.wAxisZ    = Map(normalizedChannels[2]);
        if (normalizedChannels.Length > 3) _pos.wAxisXRot = Map(normalizedChannels[3]);
        if (normalizedChannels.Length > 4) _pos.wAxisYRot = Map(normalizedChannels[4]);
        if (normalizedChannels.Length > 5) _pos.wAxisZRot = Map(normalizedChannels[5]);
        if (normalizedChannels.Length > 6) _pos.wSlider   = Map(normalizedChannels[6]);
        if (normalizedChannels.Length > 7) _pos.wDial     = Map(normalizedChannels[7]);

        uint buttons = 0;
        for (int i = 0; i < System.Math.Min(switches.Length, 32); i++)
        {
            if (switches[i]) buttons |= (1u << i);
        }
        _pos.lButtons = buttons;

        bool ok = VJoyNative.UpdateVJD(DeviceId, ref _pos);
        if (!ok)
        {
            Console.WriteLine("[vJoy] UpdateVJD failed — device may have been disconnected.");
            IsConnected = false;
        }

        return Task.CompletedTask;
    }

    public Task ResetAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected)
        {
            VJoyNative.ResetVJD(DeviceId);
            _pos.wAxisX    = AxisMid;
            _pos.wAxisY    = AxisMid;
            _pos.wAxisZ    = AxisMin;
            _pos.wAxisXRot = AxisMid;
            _pos.lButtons  = 0;
            VJoyNative.UpdateVJD(DeviceId, ref _pos);
        }
        return Task.CompletedTask;
    }

    public Task ShutdownAsync(CancellationToken cancellationToken = default)
    {
        if (IsConnected)
        {
            VJoyNative.ResetVJD(DeviceId);
            VJoyNative.RelinquishVJD(DeviceId);
            IsConnected = false;
            Console.WriteLine($"[vJoy] Device {DeviceId} relinquished.");
        }
        return Task.CompletedTask;
    }

    public void Dispose() => _ = ShutdownAsync();
    public ValueTask DisposeAsync() { _ = ShutdownAsync(); return ValueTask.CompletedTask; }
}
