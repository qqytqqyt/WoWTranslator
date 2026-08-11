namespace WdbToolkit
{
    /// <summary>
    /// Reads big-endian (most-significant-bit first) bit fields from a byte buffer,
    /// matching the bit packing produced by the WoW packet writer (WriteBits).
    /// </summary>
    internal struct MsbBitReader
    {
        private readonly byte[] m_data;
        private int m_bitPos;

        public MsbBitReader(byte[] data, int byteOffset)
        {
            m_data = data;
            m_bitPos = byteOffset * 8;
        }

        public bool CanRead(int bitCount)
        {
            return m_bitPos + bitCount <= m_data.Length * 8;
        }

        public int ReadBits(int bitCount)
        {
            var value = 0;
            for (int i = 0; i < bitCount; i++)
            {
                var b = m_data[m_bitPos >> 3];
                value = (value << 1) | ((b >> (7 - (m_bitPos & 7))) & 1);
                m_bitPos++;
            }

            return value;
        }
    }
}
