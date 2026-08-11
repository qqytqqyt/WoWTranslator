using System.Collections.Generic;
using System.Linq;

namespace WdbToolkit
{
    /// <summary>One bit-packed string length field of the quest record.</summary>
    public sealed class QuestStringField
    {
        public QuestStringField(string name, int bits)
        {
            Name = name;
            Bits = bits;
        }

        public string Name { get; }

        /// <summary>Width of the length field in bits.</summary>
        public int Bits { get; }
    }

    /// <summary>
    /// Describes the bit-packed block of string lengths inside a quest cache record.
    /// The block is followed (after the per-objective data) by the concatenated string
    /// bytes in the same order as the fields.
    ///
    /// This matches the layout of the QUEST_QUERY_RESPONSE packet the client writes to
    /// questcache.wdb. The layout has been stable from Legion through current retail and
    /// all "modern engine" classic clients; if a future build adds or resizes a field,
    /// add another spec here and pass it via <see cref="QuestCacheParseOptions.Specs"/>.
    /// </summary>
    public sealed class QuestStringBlockSpec
    {
        public QuestStringBlockSpec(string name, IReadOnlyList<QuestStringField> fields, int trailingBits)
        {
            Name = name;
            Fields = fields;
            TrailingBits = trailingBits;
            TotalBits = fields.Sum(f => f.Bits) + trailingBits;
            HeaderSizeBytes = (TotalBits + 7) / 8;
        }

        public string Name { get; }

        public IReadOnlyList<QuestStringField> Fields { get; }

        /// <summary>Extra bits after the length fields (e.g. the ReadyForTranslation flag).</summary>
        public int TrailingBits { get; }

        public int TotalBits { get; }

        /// <summary>Size of the block in bytes, including flush padding.</summary>
        public int HeaderSizeBytes { get; }

        /// <summary>
        /// Field order: LogTitle(9), LogDescription(12), QuestDescription(12), AreaDescription(9),
        /// PortraitGiverText(10), PortraitGiverName(8), PortraitTurnInText(10), PortraitTurnInName(8),
        /// QuestCompletionLog(11), plus 1 trailing bit (ReadyForTranslation). 90 bits => 12 bytes.
        /// </summary>
        public static readonly QuestStringBlockSpec Modern = new QuestStringBlockSpec(
            "modern",
            new[]
            {
                new QuestStringField("LogTitle", 9),
                new QuestStringField("LogDescription", 12),
                new QuestStringField("QuestDescription", 12),
                new QuestStringField("AreaDescription", 9),
                new QuestStringField("PortraitGiverText", 10),
                new QuestStringField("PortraitGiverName", 8),
                new QuestStringField("PortraitTurnInText", 10),
                new QuestStringField("PortraitTurnInName", 8),
                new QuestStringField("QuestCompletionLog", 11),
            },
            1);

        /// <summary>
        /// Decodes the string lengths at <paramref name="byteOffset"/> into <paramref name="lengths"/>
        /// (which must have <c>Fields.Count</c> elements). Returns false when the buffer is too short.
        /// </summary>
        public bool TryDecodeLengths(byte[] payload, int byteOffset, int[] lengths)
        {
            if (byteOffset < 0 || byteOffset + HeaderSizeBytes > payload.Length)
                return false;

            var reader = new MsbBitReader(payload, byteOffset);
            for (int i = 0; i < Fields.Count; i++)
                lengths[i] = reader.ReadBits(Fields[i].Bits);

            return true;
        }

        /// <summary>
        /// Decodes only the first length field (the title). Used as a cheap filter in the
        /// hot search loops before paying for a full decode.
        /// </summary>
        public bool TryDecodeFirstLength(byte[] payload, int byteOffset, out int length)
        {
            length = 0;
            if (byteOffset < 0 || byteOffset + HeaderSizeBytes > payload.Length)
                return false;

            var reader = new MsbBitReader(payload, byteOffset);
            length = reader.ReadBits(Fields[0].Bits);
            return true;
        }
    }
}
