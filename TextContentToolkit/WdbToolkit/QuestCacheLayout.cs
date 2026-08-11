using System;
using System.Collections.Generic;
using System.Linq;

namespace WdbToolkit
{
    /// <summary>Where the bit-packed string-length block sits inside a record.</summary>
    public enum QuestCacheLayoutMode
    {
        /// <summary>
        /// The block sits at a (nearly) fixed offset from the payload start, before the
        /// objectives data. All builds up to 11.x retail 68256 and all classic builds.
        /// </summary>
        HeaderAtFixedOffset,

        /// <summary>
        /// The block sits immediately before the string bytes, after the objectives data,
        /// so its offset varies per record (observed from retail build 68914). Solved per
        /// record via the end-anchor equation offset + blockSize + sum(lengths) + trailing
        /// == payload length.
        /// </summary>
        HeaderBeforeStrings,
    }

    /// <summary>
    /// The per-file (per client build) layout inferred by <see cref="QuestCacheCalibrator"/>.
    /// </summary>
    public sealed class QuestCacheLayout
    {
        public QuestStringBlockSpec Spec { get; internal set; }

        public QuestCacheLayoutMode Mode { get; internal set; }

        /// <summary>
        /// Most common offset of the bit-packed string-length header inside record payloads
        /// (<see cref="QuestCacheLayoutMode.HeaderAtFixedOffset"/> only, -1 otherwise).
        /// Equals the size of the fixed numeric block that precedes it, which is what changes
        /// between client builds.
        /// </summary>
        public int BaseStringHeaderOffset { get; internal set; }

        /// <summary>Most common number of bytes following the string block (usually 0).</summary>
        public int TrailingSize { get; internal set; }

        /// <summary>
        /// True when the header offset varies between records of the same file
        /// (a variable-length array precedes the string header in this build).
        /// </summary>
        public bool HasHeaderOffsetDrift { get; internal set; }

        /// <summary>Share of calibration votes supporting the chosen offset cluster (0..1).</summary>
        public double Confidence { get; internal set; }

        /// <summary>Number of records sampled during calibration.</summary>
        public int SampleSize { get; internal set; }

        /// <summary>Sampled records that produced at least one consistent interpretation.</summary>
        public int SupportingRecords { get; internal set; }

        /// <summary>
        /// Share of sampled records the layout extracts directly with corpus agreement (0..1).
        /// A low value after successful calibration means many records need fallback searches.
        /// </summary>
        public double VerificationRate { get; internal set; }

        /// <summary>
        /// Average payload bytes explained per sampled record during verification. Used to
        /// pick between layout modes: a wrong layout can only "explain" tiny coincidental
        /// fragments while the true one accounts for the whole text block.
        /// </summary>
        public double VerificationScore { get; internal set; }

        /// <summary>Vote weight per candidate header offset (diagnostics; fixed-offset mode only).</summary>
        public IReadOnlyDictionary<int, long> OffsetWeights { get; internal set; }

        public string Describe()
        {
            var top = OffsetWeights == null
                ? string.Empty
                : " votes[" + string.Join(", ", OffsetWeights.OrderByDescending(kv => kv.Value).Take(5)
                      .Select(kv => kv.Key + ":" + kv.Value)) + "]";

            var position = Mode == QuestCacheLayoutMode.HeaderBeforeStrings
                ? "stringHeader=beforeStrings"
                : "stringHeaderOffset=" + BaseStringHeaderOffset + (HasHeaderOffsetDrift ? "(+4n)" : string.Empty);

            return string.Format(
                "spec={0} {1} trailing={2} confidence={3:P1} verified={4:P1} support={5}/{6}{7}",
                Spec.Name,
                position,
                TrailingSize,
                Confidence,
                VerificationRate,
                SupportingRecords,
                SampleSize,
                top);
        }
    }

    /// <summary>Thrown when no consistent layout could be inferred from a quest cache file.</summary>
    public sealed class QuestCacheFormatException : Exception
    {
        public QuestCacheFormatException(string message)
            : base(message)
        {
        }
    }
}
