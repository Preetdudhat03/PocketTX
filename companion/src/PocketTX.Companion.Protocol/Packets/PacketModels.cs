using PocketTX.Companion.Core.Enums;

namespace PocketTX.Companion.Protocol.Packets;

/// <summary>
/// Binary packet header representation. Layout (24 bytes header total):
/// Header [2b: 'P','T'], Version [1b], Type [1b], SessionId [4b], Sequence [4b], Timestamp [8b], PayloadLength [2b], Reserved [2b].
/// </summary>
public sealed class PacketHeader
{
    public static readonly byte[] MagicBytes = [(byte)'P', (byte)'T'];

    public byte Version { get; set; } = 0x01;
    public PacketType Type { get; set; } = PacketType.ChannelData;
    public uint SessionId { get; set; } = 0;
    public uint Sequence { get; set; } = 0;
    public ulong TimestampMs { get; set; } = (ulong)DateTimeOffset.UtcNow.ToUnixTimeMilliseconds();
    public ushort PayloadLength { get; set; } = 0;

    public const int HeaderSize = 24; // 2 + 1 + 1 + 4 + 4 + 8 + 2 + 2
}

public sealed class TelemetryPacket
{
    public PacketHeader Header { get; set; } = new();
    public byte[] Payload { get; set; } = Array.Empty<byte>();
    public uint Crc32 { get; set; } = 0;
}
