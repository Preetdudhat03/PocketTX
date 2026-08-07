using PocketTX.Companion.Core.Enums;
using PocketTX.Companion.Protocol.Packets;
using PocketTX.Companion.Protocol.Serializers;
using Xunit;

namespace PocketTX.Companion.Tests.Protocol;

public class PacketSerializerTests
{
    [Fact]
    public void SerializeAndDeserialize_ValidPacket_RoundtripsSuccessfully()
    {
        TelemetryPacket packet = new()
        {
            Header = new PacketHeader
            {
                Version = 1,
                Type = PacketType.ChannelData,
                Sequence = 42,
                TimestampMs = 123456789,
                PayloadLength = 4
            },
            Payload = [0x01, 0x02, 0x03, 0x04]
        };

        byte[] raw = PacketSerializer.Serialize(packet);
        Assert.True(raw.Length > 0);

        bool success = PacketSerializer.TryDeserialize(raw, out TelemetryPacket? deserialized);
        Assert.True(success);
        Assert.NotNull(deserialized);
        Assert.Equal(packet.Header.Sequence, deserialized!.Header.Sequence);
        Assert.Equal(packet.Header.Type, deserialized.Header.Type);
        Assert.Equal(packet.Payload, deserialized.Payload);
    }

    [Fact]
    public void TryDeserialize_TooShortBuffer_ReturnsFalse()
    {
        // A buffer shorter than the header size must be rejected
        byte[] raw = new byte[4]; // Way less than 24-byte header

        bool success = PacketSerializer.TryDeserialize(raw, out _);
        Assert.False(success);
    }

    [Fact]
    public void TryDeserialize_WrongMagicBytes_ReturnsFalse()
    {
        TelemetryPacket packet = new()
        {
            Header = new PacketHeader { Sequence = 1 },
            Payload = [0xAA, 0xBB]
        };

        byte[] raw = PacketSerializer.Serialize(packet);
        // Corrupt the magic bytes ('P','T' at index 0,1)
        raw[0] = 0xFF;

        bool success = PacketSerializer.TryDeserialize(raw, out _);
        Assert.False(success);
    }
}
