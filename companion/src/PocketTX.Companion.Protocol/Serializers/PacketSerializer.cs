using System.IO.Hashing;
using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Protocol.Packets;

namespace PocketTX.Companion.Protocol.Serializers;

/// <summary>
/// Binary packet serializer and parser with CRC32 integrity verification.
/// </summary>
public static class PacketSerializer
{
    public static byte[] Serialize(TelemetryPacket packet)
    {
        int totalSize = PacketHeader.HeaderSize + packet.Payload.Length + 4; // Header + Payload + CRC32
        byte[] buffer = new byte[totalSize];

        using MemoryStream ms = new(buffer);
        using BinaryWriter writer = new(ms);

        // Header
        writer.Write(PacketHeader.MagicBytes);
        writer.Write(packet.Header.Version);
        writer.Write((byte)packet.Header.Flags);
        writer.Write(packet.Header.Reserved);
        writer.Write((byte)packet.Header.Type);
        writer.Write(packet.Header.Sequence);
        writer.Write(packet.Header.TimestampMs);
        writer.Write((ushort)packet.Payload.Length);

        // Payload
        if (packet.Payload.Length > 0)
        {
            writer.Write(packet.Payload);
        }

        // CRC32 calculation over header + payload
        uint crc = Crc32.HashToUInt32(buffer.AsSpan(0, PacketHeader.HeaderSize + packet.Payload.Length));
        packet.Crc32 = crc;
        writer.Write(crc);

        return buffer;
    }

    public static bool TryDeserialize(ReadOnlySpan<byte> buffer, out TelemetryPacket? packet)
    {
        packet = null;
        if (buffer.Length < PacketHeader.HeaderSize + 4) return false;

        // Check magic bytes
        if (buffer[0] != PacketHeader.MagicBytes[0] || buffer[1] != PacketHeader.MagicBytes[1])
            return false;

        int payloadLength = BitConverter.ToUInt16(buffer.Slice(18, 2));
        int expectedTotalSize = PacketHeader.HeaderSize + payloadLength + 4;

        if (buffer.Length < expectedTotalSize) return false;

        // Verify CRC32
        uint expectedCrc = BitConverter.ToUInt32(buffer.Slice(PacketHeader.HeaderSize + payloadLength, 4));
        uint calculatedCrc = Crc32.HashToUInt32(buffer.Slice(0, PacketHeader.HeaderSize + payloadLength));

        if (expectedCrc != calculatedCrc) return false;

        TelemetryPacket result = new()
        {
            Header = new PacketHeader
            {
                Version = buffer[2],
                Flags = (PacketFlags)buffer[3],
                Reserved = buffer[4],
                Type = (PacketType)buffer[5],
                Sequence = BitConverter.ToUInt32(buffer.Slice(6, 4)),
                TimestampMs = BitConverter.ToUInt64(buffer.Slice(10, 8)),
                PayloadLength = (ushort)payloadLength
            },
            Payload = buffer.Slice(PacketHeader.HeaderSize, payloadLength).ToArray(),
            Crc32 = expectedCrc
        };

        packet = result;
        return true;
    }
}
