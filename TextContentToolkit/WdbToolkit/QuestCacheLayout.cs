using System;
using System.Collections.Generic;
using System.Linq;

namespace WdbToolkit
{
    /// <summary>
    /// The per-file (per client build) layout inferred by <see cref="QuestCacheCalibrator"/>.
    /// </summary>
    public sealed class QuestCacheLayout
    {
        public QuestStringBlockSpec Spec { get; internal set; }

        /// <summary>
        /// Most common offset of the bit-packed string-length header inside record payloads.
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

        /// <summary>Vote weight per candidate header offset (diagnostics).</summary>
        public IReadOnlyDictionary<int, long> OffsetWeights { get; internal set; }

        public string Describe()
        {
            var top = OffsetWeights == null
                ? string.Empty
                : " votes[" + string.Join(", ", OffsetWeights.OrderByDescending(kv => kv.Value).Take(5)
                      .Select(kv => kv.Key + ":" + kv.Value)) + "]";

            return string.Format(
                "spec={0} stringHeaderOffset={1}{2} trailing={3} confidence={4:P1} support={5}/{6}{7}",
                Spec.Name,
                BaseStringHeaderOffset,
                HasHeaderOffsetDrift ? "(+4n)" : string.Empty,
                TrailingSize,
                Confidence,
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
