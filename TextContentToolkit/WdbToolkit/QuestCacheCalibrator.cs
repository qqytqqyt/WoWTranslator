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
    ///  - Records normally have no data after the strings, so the strings are anchored
    ///    to the end of the record.
    ///  - The block position follows one of two schemes (<see cref="QuestCacheLayoutMode"/>):
    ///    at a fixed offset after the numeric struct (all builds up to 11.x/68256), or
    ///    immediately before the strings (observed from retail build 68914).
    ///
    /// Calibration builds a candidate layout for each scheme from a sample of records,
    /// then verifies both by direct extraction and keeps the one that explains the most
    /// payload bytes - a wrong scheme only matches tiny coincidental fragments, so the
    /// comparison is decisive even without a title corpus.
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
                var sample = BuildSample(records, options, spec);
                if (sample.Count == 0)
                {
                    diagnostics.AppendLine("spec " + spec.Name + ": no usable records.");
                    continue;
                }

                Trace(options, "calibrating spec " + spec.Name + " on " + sample.Count + " of " +
                               records.Count + " records");

                var candidates = new List<QuestCacheLayout>();
                var fixedOffset = CalibrateFixedOffset(sample, spec, options, corpusTitleBytes);
                if (fixedOffset != null)
                    candidates.Add(fixedOffset);

                var beforeStrings = CalibrateHeaderBeforeStrings(sample, spec, options, corpusTitleBytes);
                if (beforeStrings != null)
                    candidates.Add(beforeStrings);

                foreach (var candidate in candidates)
                {
                    Verify(sample, candidate, options, corpusTitleBytes);
                    var line = candidate.Describe() + " score=" + candidate.VerificationScore.ToString("F0");
                    diagnostics.AppendLine(line);
                    Trace(options, "candidate " + line);

                    if (best == null || candidate.VerificationScore > best.VerificationScore)
                        best = candidate;
                }
            }

            if (best == null || best.SupportingRecords == 0 || best.VerificationScore <= 0)
                throw new QuestCacheFormatException(
                    "Could not infer the quest record layout - the string block format may have changed. " +
                    "Details: " + diagnostics);

            return best;
        }

        private static void Trace(QuestCacheParseOptions options, string message)
        {
            if (options.Trace != null)
                options.Trace(message);
        }

        private static List<WdbCacheRecord> BuildSample(
            IReadOnlyList<WdbCacheRecord> records, QuestCacheParseOptions options, QuestStringBlockSpec spec)
        {
            var usable = records.Where(r => r.Payload.Length >= spec.HeaderSizeBytes + 4).ToList();
            if (usable.Count == 0)
                return usable;

            var sampleSize = Math.Min(options.CalibrationSampleSize, usable.Count);
            var step = Math.Max(1, usable.Count / sampleSize);
            var sample = new List<WdbCacheRecord>();
            for (int i = 0; i < usable.Count && sample.Count < sampleSize; i += step)
                sample.Add(usable[i]);

            return sample;
        }

        /// <summary>
        /// Candidate layout for <see cref="QuestCacheLayoutMode.HeaderAtFixedOffset"/>:
        /// votes for every header offset that consistently produces valid UTF-8 for all
        /// string fields, weighted by decoded byte count so coincidental matches lose.
        /// </summary>
        private static QuestCacheLayout CalibrateFixedOffset(
            List<WdbCacheRecord> sample,
            QuestStringBlockSpec spec,
            QuestCacheParseOptions options,
            IReadOnlyDictionary<int, byte[]> corpusTitleBytes)
        {
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
                return null;

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

            return new QuestCacheLayout
            {
                Spec = spec,
                Mode = QuestCacheLayoutMode.HeaderAtFixedOffset,
                BaseStringHeaderOffset = peak.Key,
                TrailingSize = trailing,
                HasHeaderOffsetDrift = cluster.Count > 1,
                Confidence = totalWeight == 0 ? 0 : (double)clusterWeight / totalWeight,
                SampleSize = sample.Count,
                SupportingRecords = supporting,
                OffsetWeights = offsetWeights,
            };
        }

        /// <summary>
        /// Candidate layout for <see cref="QuestCacheLayoutMode.HeaderBeforeStrings"/>:
        /// per record the block offset solves offset + blockSize + sum(lengths) + trailing
        /// == payload length, so only the trailing size needs calibrating.
        /// </summary>
        private static QuestCacheLayout CalibrateHeaderBeforeStrings(
            List<WdbCacheRecord> sample,
            QuestStringBlockSpec spec,
            QuestCacheParseOptions options,
            IReadOnlyDictionary<int, byte[]> corpusTitleBytes)
        {
            var headerSize = spec.HeaderSizeBytes;
            var trailingCounts = new Dictionary<int, int>();
            var supporting = 0;
            var lengths = new int[spec.Fields.Count];

            foreach (var record in sample)
            {
                var payload = record.Payload;
                byte[] titleBytes = null;
                if (corpusTitleBytes != null)
                    corpusTitleBytes.TryGetValue(record.Id, out titleBytes);

                var contributed = false;
                if (titleBytes != null && titleBytes.Length > 0)
                {
                    // The title starts right after the block: offset = titlePos - blockSize.
                    var searchFrom = 0;
                    for (int occurrence = 0; occurrence < 8; occurrence++)
                    {
                        var titlePos = IndexOf(payload, titleBytes, searchFrom);
                        if (titlePos < 0)
                            break;

                        searchFrom = titlePos + 1;

                        var offset = titlePos - headerSize;
                        if (offset < 0 || !spec.TryDecodeLengths(payload, offset, lengths))
                            continue;

                        if (lengths[0] != titleBytes.Length)
                            continue;

                        var sum = Sum(lengths);
                        var trailing = payload.Length - (titlePos + sum);
                        if (trailing < 0 || trailing > options.MaxTrailingScan)
                            continue;

                        if (!AllFieldsValid(payload, titlePos, lengths))
                            continue;

                        int count;
                        trailingCounts.TryGetValue(trailing, out count);
                        trailingCounts[trailing] = count + 1;
                        contributed = true;
                    }
                }
                else
                {
                    int offset, trailing;
                    if (TrySolveEndAnchor(payload, spec, lengths, options.MaxTrailingScan, out offset, out trailing))
                    {
                        int count;
                        trailingCounts.TryGetValue(trailing, out count);
                        trailingCounts[trailing] = count + 1;
                        contributed = true;
                    }
                }

                if (contributed)
                    supporting++;
            }

            if (supporting == 0)
                return null;

            return new QuestCacheLayout
            {
                Spec = spec,
                Mode = QuestCacheLayoutMode.HeaderBeforeStrings,
                BaseStringHeaderOffset = -1,
                TrailingSize = trailingCounts.OrderByDescending(kv => kv.Value).First().Key,
                HasHeaderOffsetDrift = false,
                Confidence = (double)supporting / sample.Count,
                SampleSize = sample.Count,
                SupportingRecords = supporting,
                OffsetWeights = null,
            };
        }

        /// <summary>
        /// Finds the best block position satisfying the end-anchor equation. Preference
        /// order: header bytes that do not read as text (the true block is bit noise while
        /// false hits sit inside the text), then the largest explained byte count.
        /// </summary>
        internal static bool TrySolveEndAnchor(
            byte[] payload,
            QuestStringBlockSpec spec,
            int[] lengths,
            int maxTrailing,
            out int bestOffset,
            out int bestTrailing)
        {
            var headerSize = spec.HeaderSizeBytes;
            bestOffset = -1;
            bestTrailing = 0;
            var bestSum = -1;
            var bestHeaderIsText = true;

            for (int offset = 0; offset + headerSize <= payload.Length; offset++)
            {
                if (!spec.TryDecodeLengths(payload, offset, lengths))
                    break;

                if (lengths[0] == 0)
                    continue;

                var sum = Sum(lengths);
                var trailing = payload.Length - offset - headerSize - sum;
                if (trailing < 0 || trailing > maxTrailing)
                    continue;

                if (!AllFieldsValid(payload, offset + headerSize, lengths))
                    continue;

                string title;
                if (!TextValidation.TryDecodeUtf8(payload, offset + headerSize, lengths[0], out title) ||
                    !TextValidation.IsPlausibleTitle(title))
                    continue;

                var headerIsText = TextValidation.IsValidUtf8(payload, offset, headerSize);
                var better = bestOffset < 0 ||
                             !headerIsText && bestHeaderIsText ||
                             headerIsText == bestHeaderIsText && sum > bestSum;

                if (better)
                {
                    bestOffset = offset;
                    bestTrailing = trailing;
                    bestSum = sum;
                    bestHeaderIsText = headerIsText;
                }
            }

            if (bestOffset < 0)
                return false;

            spec.TryDecodeLengths(payload, bestOffset, lengths);
            return true;
        }

        /// <summary>
        /// Scores a candidate layout by direct extraction over the sample: the sum of string
        /// bytes it explains (with corpus agreement where known), averaged per record.
        /// </summary>
        private static void Verify(
            List<WdbCacheRecord> sample,
            QuestCacheLayout layout,
            QuestCacheParseOptions options,
            IReadOnlyDictionary<int, byte[]> corpusTitleBytes)
        {
            long explained = 0;
            var accepted = 0;

            foreach (var record in sample)
            {
                byte[] titleBytes = null;
                if (corpusTitleBytes != null)
                    corpusTitleBytes.TryGetValue(record.Id, out titleBytes);

                var bytes = QuestRecordExtractor.MeasureDirect(record, layout, options, titleBytes);
                if (bytes > 0)
                {
                    explained += bytes;
                    accepted++;
                }
            }

            layout.VerificationRate = sample.Count == 0 ? 0 : (double)accepted / sample.Count;
            layout.VerificationScore = sample.Count == 0 ? 0 : (double)explained / sample.Count;
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
                    int firstLength;
                    if (!spec.TryDecodeFirstLength(payload, offset, out firstLength))
                        break;

                    if (firstLength != titleBytes.Length)
                        continue;

                    if (!spec.TryDecodeLengths(payload, offset, lengths))
                        break;

                    var sum = Sum(lengths);
                    var trailing = payload.Length - (titlePos + sum);
                    if (trailing < 0 || trailing > options.MaxTrailingScan)
                        continue;

                    if (!AllFieldsValid(payload, titlePos, lengths))
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

                if (!AllFieldsValid(payload, start, lengths))
                    continue;

                string title;
                if (!TextValidation.TryDecodeUtf8(payload, start, lengths[0], out title) ||
                    !TextValidation.IsPlausibleTitle(title))
                    continue;

                long weight;
                offsetWeights.TryGetValue(offset, out weight);
                offsetWeights[offset] = weight + sum + 1;
                contributed = true;
            }

            return contributed;
        }

        /// <summary>Validates every string field as UTF-8 without allocating strings.</summary>
        internal static bool AllFieldsValid(byte[] payload, int stringsStart, int[] lengths)
        {
            var pos = stringsStart;
            for (int i = 0; i < lengths.Length; i++)
            {
                if (lengths[i] > 0 && !TextValidation.IsValidUtf8(payload, pos, lengths[i]))
                    return false;
                pos += lengths[i];
            }

            return pos <= payload.Length;
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
