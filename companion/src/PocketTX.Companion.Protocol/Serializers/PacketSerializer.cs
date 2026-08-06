using System.Buffers.Binary;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Protocol.Packets;

namespace PocketTX.Companion.Protocol.Serializers;

/// <summary>
/// Binary packet serializer and parser for PocketTX Phase 2A binary protocol.
/// </summary>
public static class PacketSerializer
{
    public static byte[] Serialize(TelemetryPacket packet)
    {
        int totalSize = PacketHeader.HeaderSize + packet.Payload.Length;
        byte[] buffer = new byte[totalSize];

        buffer[0] = PacketHeader.MagicBytes[0];
        buffer[1] = PacketHeader.MagicBytes[1];
        buffer[2] = packet.Header.Version;
        buffer[3] = (byte)packet.Header.Type;

        BinaryPrimitives.WriteUInt32BigEndian(buffer.AsSpan(4, 4), packet.Header.SessionId);
        BinaryPrimitives.WriteUInt32BigEndian(buffer.AsSpan(8, 4), packet.Header.Sequence);
        BinaryPrimitives.WriteUInt64BigEndian(buffer.AsSpan(12, 8), packet.Header.TimestampMs);
        BinaryPrimitives.WriteUInt16BigEndian(buffer.AsSpan(20, 2), (ushort)packet.Payload.Length);
        buffer[22] = 0;
        buffer[23] = 0;

        if (packet.Payload.Length > 0)
        {
            packet.Payload.CopyTo(buffer.AsSpan(PacketHeader.HeaderSize));
        }

        return buffer;
    }

    public static bool TryDeserialize(ReadOnlySpan<byte> buffer, out TelemetryPacket? packet)
    {
        packet = null;
        if (buffer.Length < PacketHeader.HeaderSize) return false;

        // Check magic bytes 'P', 'T'
        if (buffer[0] != PacketHeader.MagicBytes[0] || buffer[1] != PacketHeader.MagicBytes[1])
            return false;

        ushort payloadLength = BinaryPrimitives.ReadUInt16BigEndian(buffer.Slice(20, 2));
        int expectedTotalSize = PacketHeader.HeaderSize + payloadLength;

        if (buffer.Length < expectedTotalSize) return false;

        TelemetryPacket result = new()
        {
            Header = new PacketHeader
            {
                Version = buffer[2],
                Type = (PacketType)buffer[3],
                SessionId = BinaryPrimitives.ReadUInt32BigEndian(buffer.Slice(4, 4)),
                Sequence = BinaryPrimitives.ReadUInt32BigEndian(buffer.Slice(8, 4)),
                TimestampMs = BinaryPrimitives.ReadUInt64BigEndian(buffer.Slice(12, 8)),
                PayloadLength = payloadLength
            },
            Payload = buffer.Slice(PacketHeader.HeaderSize, payloadLength).ToArray()
        };

        packet = result;
        return true;
    }
}
