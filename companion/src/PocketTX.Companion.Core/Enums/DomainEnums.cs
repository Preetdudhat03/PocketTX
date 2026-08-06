namespace PocketTX.Companion.Core.Enums;

public enum SimulatorType
{
    None,
    Liftoff,
    Velocidrone,
    FPVSkyDive,
    PicaSim,
    Custom
}

public enum ThemeType
{
    Dark,
    Light
}

public enum ConnectionType
{
    TestMode,
    Usb,
    Adb,
    Bluetooth,
    Wifi
}

public enum LogLevel
{
    Debug,
    Info,
    Warning,
    Error
}

public enum ChannelType
{
    Roll = 0,
    Pitch = 1,
    Throttle = 2,
    Yaw = 3,
    Aux1 = 4,
    Aux2 = 5,
    Aux3 = 6,
    Aux4 = 7
}

public enum ProfileType
{
    DefaultAcro,
    LiftoffMicro,
    Velocidrone,
    Indoor,
    FPVSkyDive,
    PicaSim,
    Custom
}

public enum VirtualBackendType
{
    Simulation,
    ViGEm,
    HidInjector,
    VJoy
}

public enum PacketType : byte
{
    Hello = 0x01,
    Heartbeat = 0x02,
    ChannelData = 0x03,
    Telemetry = 0x04,
    Ack = 0x05,
    Disconnect = 0x06
}

[System.Flags]
public enum PacketFlags : byte
{
    None = 0x00,
    Compressed = 0x01,
    Encrypted = 0x02,
    RequiresAck = 0x04
}
