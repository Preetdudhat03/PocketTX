namespace PocketTX.Companion.Protocol.Helpers;

/// <summary>
/// Fast IEEE 802.3 CRC32 calculation helper.
/// </summary>
public static class Crc32
{
    private static readonly uint[] Table;

    static Crc32()
    {
        Table = new uint[256];
        const uint polynomial = 0xEDB88320;
        for (uint i = 0; i < 256; i++)
        {
            uint crc = i;
            for (int j = 8; j > 0; j--)
            {
                if ((crc & 1) == 1)
                    crc = (crc >> 1) ^ polynomial;
                else
                    crc >>= 1;
            }
            Table[i] = crc;
        }
    }

    public static uint Compute(ReadOnlySpan<byte> buffer)
    {
        uint crc = 0xFFFFFFFF;
        foreach (byte b in buffer)
        {
            byte index = (byte)((crc ^ b) & 0xFF);
            crc = (crc >> 8) ^ Table[index];
        }
        return ~crc;
    }
}
