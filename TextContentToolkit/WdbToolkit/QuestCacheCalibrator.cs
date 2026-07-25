using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace WdbToolkit
{
    /// <summary>
    /// Infers the per-build record layout of a quest cache file.
    ///
    /// Key observations that make this generic across builds:
    ///  - Each record ends with the concatenated string bytes (title, objectives text,
    ///    description, ...) whose lengths are bit-packed in a small header block.
    ///  - The block sits after a fixed-size numeric struct whose size is what changes
    ///    between client builds, so its offset is (nearly) constant within one file.
    ///  - Records normally have no data after the strings, so the strings are anchored
    ///    to the end of the record.
    ///
    /// Calibration therefore scans candidate header offsets on a sample of records and
    /// keeps the offset that most consistently produces valid UTF-8 for every string
    /// field. When an expected-title corpus is available, the title bytes are located
    /// directly in the payload, which also measures the trailing size exactly.
    /// </summary>
    public static class QuestCacheCalibrator
    {
        public static QuestCacheLayout Calibrate(
            IReadOnlyList<WdbCacheRecord> records,
            QuestCacheParseOptions options,
            IReadOnlyDictionary<int, byte[]> corpusTitleBytes)
        {
            var specs = options.Specs != null && options.Specs.Count > 0
                ? options.Specs
                : new List<QuestStringBlockSpec> { QuestStringBlockSpec.Modern };

            QuestCacheLayout best = null;
            var diagnostics = new StringBuilder();

            foreach (var spec in specs)
            {
                var layout = CalibrateSpec(records, options, corpusTitleBytes, spec, diagnostics);
                if (layout == null)
                    continue;

                if (best == null || layout.Confidence * layout.SupportingRecords >
                    best.Confidence * best.SupportingRecords)
                    best = layout;
            }

            if (best == null || best.SupportingRecords == 0)
                throw new QuestCacheFormatException(
                    "Could not infer the quest record layout - the string block format may have changed. " +
                    "Details: " + diagnostics);

            return best;
        }

        private static QuestCacheLayout CalibrateSpec(
            IReadOnlyList<WdbCacheRecord> records,
            QuestCacheParseOptions options,
            IReadOnlyDictionary<int, byte[]> corpusTitleBytes,
            QuestStringBlockSpec spec,
            StringBuilder diagnostics)
        {
            var headerSize = spec.HeaderSizeBytes;
            var usable = records.Where(r => r.Payload.Length >= headerSize + 4).ToList();
            if (usable.Count == 0)
            {
                diagnostics.AppendLine("spec " + spec.Name + ": no usable records.");
                return null;
            }

            var sampleSize = Math.Min(options.CalibrationSampleSize, usable.Count);
            var step = Math.Max(1, usable.Count / sampleSize);
            var sample = new List<WdbCacheRecord>();
            for (int i = 0; i < usable.Count && sample.Count < sampleSize; i += step)
                sample.Add(usable[i]);

            var offsetWeights = new Dictionary<int, long>();
            var trailingCounts = new Dictionary<int, int>();
            var supporting = 0;
            var lengths = new int[spec.Fields.Count];

            foreach (var record in sample)
            {
                byte[] titleBytes = null;
                if (corpusTitleBytes != null)
                    corpusTitleBytes.TryGetValue(record.Id, out titleBytes);

                var contributed = titleBytes != null && titleBytes.Length > 0
                    ? VoteWithCorpus(record.Payload, spec, lengths, titleBytes, options, offsetWeights, trailingCounts)
                    : VoteStructurally(record.Payload, spec, lengths, options, offsetWeights);

                if (contributed)
                    supporting++;
            }

            if (offsetWeights.Count == 0)
            {
                diagnostics.AppendLine("spec " + spec.Name + ": no candidate offsets found in " +
                                       sample.Count + " sampled records.");
                return null;
            }

            var peak = offsetWeights.OrderByDescending(kv => kv.Value).First();
            var peakWeight = peak.Value;

            // Offsets around the peak, 4-byte aligned relative to it, with non-trivial support:
            // these are the "base + 4n" shifts caused by a variable-length array before the header.
            var cluster = offsetWeights
                .Where(kv => Math.Abs(kv.Key - peak.Key) <= 64 &&
                             (kv.Key - peak.Key) % 4 == 0 &&
                             kv.Value >= peakWeight / 20)
                .ToList();

            var clusterWeight = cluster.Sum(kv => kv.Value);
            var totalWeight = offsetWeights.Values.Sum();

            var trailing = 0;
            if (trailingCounts.Count > 0)
                trailing = trailingCounts.OrderByDescending(kv => kv.Value).First().Key;

            var layout = new QuestCacheLayout
            {
                Spec = spec,
                BaseStringHeaderOffset = peak.Key,
                TrailingSize = trailing,
                HasHeaderOffsetDrift = cluster.Count > 1,
                Confidence = totalWeight == 0 ? 0 : (double)clusterWeight / totalWeight,
                SampleSize = sample.Count,
                SupportingRecords = supporting,
                OffsetWeights = offsetWeights,
            };

            diagnostics.AppendLine("spec " + spec.Name + ": " + layout.Describe());
            return layout;
        }

        /// <summary>
        /// Locates the known title bytes in the payload and votes for every header offset
        /// whose decoded title length matches and whose remaining string fields decode
        /// cleanly from that position. Also measures the exact trailing size.
        /// </summary>
        private static bool VoteWithCorpus(
            byte[] payload,
            QuestStringBlockSpec spec,
            int[] lengths,
            byte[] titleBytes,
            QuestCacheParseOptions options,
            Dictionary<int, long> offsetWeights,
            Dictionary<int, int> trailingCounts)
        {
            var contributed = false;
            var headerSize = spec.HeaderSizeBytes;
            var searchFrom = 0;
            var occurrences = 0;

            while (occurrences < 8)
            {
                var titlePos = IndexOf(payload, titleBytes, searchFrom);
                if (titlePos < 0)
                    break;

                searchFrom = titlePos + 1;
                occurrences++;

                var maxOffset = Math.Min(titlePos - headerSize, options.MaxHeaderOffset);
                for (int offset = 0; offset <= maxOffset; offset++)
                {
                    if (!spec.TryDecodeLengths(payload, offset, lengths))
                        break;

                    if (lengths[0] != titleBytes.Length)
                        continue;

                    var sum = Sum(lengths);
                    var trailing = payload.Length - (titlePos + sum);
                    if (trailing < 0 || trailing > options.MaxTrailingScan)
                        continue;

                    if (!AllFieldsDecode(payload, titlePos, lengths))
                        continue;

                    long weight;
                    offsetWeights.TryGetValue(offset, out weight);
                    offsetWeights[offset] = weight + sum + 1;

                    int count;
                    trailingCounts.TryGetValue(trailing, out count);
                    trailingCounts[trailing] = count + 1;
                    contributed = true;
                }
            }

            return contributed;
        }

        /// <summary>
        /// Corpus-free voting: assumes the strings end exactly at the end of the payload
        /// and votes for every header offset whose decoded lengths partition the record
        /// tail into valid UTF-8 fields with a plausible title.
        /// </summary>
        private static bool VoteStructurally(
            byte[] payload,
            QuestStringBlockSpec spec,
            int[] lengths,
            QuestCacheParseOptions options,
            Dictionary<int, long> offsetWeights)
        {
            var contributed = false;
            var headerSize = spec.HeaderSizeBytes;
            var maxOffset = Math.Min(payload.Length - headerSize, options.MaxHeaderOffset);

            for (int offset = 0; offset <= maxOffset; offset++)
            {
                if (!spec.TryDecodeLengths(payload, offset, lengths))
                    break;

                if (lengths[0] == 0)
                    continue;

                var sum = Sum(lengths);
                var start = payload.Length - sum;
                if (start < offset + headerSize)
                    continue;

                string title;
                if (!TextValidation.TryDecodeUtf8(payload, start, lengths[0], out title) ||
                    !TextValidation.IsPlausibleTitle(title))
                    continue;

                if (!AllFieldsDecode(payload, start, lengths))
                    continue;

                long weight;
                offsetWeights.TryGetValue(offset, out weight);
                offsetWeights[offset] = weight + sum + 1;
                contributed = true;
            }

            return contributed;
        }

        internal static bool AllFieldsDecode(byte[] payload, int stringsStart, int[] lengths)
        {
            var pos = stringsStart;
            for (int i = 0; i < lengths.Length; i++)
            {
                string value;
                if (!TextValidation.TryDecodeUtf8(payload, pos, lengths[i], out value))
                    return false;
                pos += lengths[i];
            }

            return true;
        }

        internal static int Sum(int[] values)
        {
            var sum = 0;
            for (int i = 0; i < values.Length; i++)
                sum += values[i];
            return sum;
        }

        internal static int IndexOf(byte[] haystack, byte[] needle, int startIndex)
        {
            if (needle.Length == 0)
                return -1;

            var limit = haystack.Length - needle.Length;
            for (int i = Math.Max(0, startIndex); i <= limit; i++)
            {
                if (haystack[i] != needle[0])
                    continue;

                var match = true;
                for (int j = 1; j < needle.Length; j++)
                {
                    if (haystack[i + j] != needle[j])
                    {
                        match = false;
                        break;
                    }
                }

                if (match)
                    return i;
            }

            return -1;
        }
    }
}
