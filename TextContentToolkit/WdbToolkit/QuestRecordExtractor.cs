using System;
using System.Collections.Generic;

namespace WdbToolkit
{
    internal enum ExtractOutcome
    {
        Extracted,
        Empty,
        Failed,
    }

    /// <summary>
    /// Extracts the string fields of a single record using the calibrated layout,
    /// falling back to progressively broader searches when the record deviates
    /// (variable-length arrays before the header, trailing conditional texts,
    /// untitled hidden quests, ...).
    /// </summary>
    internal static class QuestRecordExtractor
    {
        public static ExtractOutcome TryExtract(
            WdbCacheRecord record,
            QuestCacheLayout layout,
            QuestCacheParseOptions options,
            byte[] expectedTitleBytes,
            string expectedTitle,
            out QuestRecordText text,
            out string failureReason)
        {
            text = null;
            failureReason = null;

            var payload = record.Payload;
            var spec = layout.Spec;
            var headerSize = spec.HeaderSizeBytes;
            var lengths = new int[spec.Fields.Count];

            if (payload.Length < headerSize)
            {
                failureReason = "payload too small (" + payload.Length + " bytes)";
                return ExtractOutcome.Failed;
            }

            // Fallback candidates by decreasing structural confidence:
            //  - a valid non-empty title that differs from the corpus (text revision in cache),
            //  - an untitled record (hidden quests have title length 0 but real descriptions),
            // each tracked separately for the direct pass (tier 1) and the scans (tier 2).
            QuestRecordText tier1Titled = null, tier1Untitled = null;
            QuestRecordText tier2Titled = null, tier2Untitled = null;
            var sawEmptyInterpretation = false;

            // 1) Calibrated offset, then +-4 byte shifts (a variable-length array may precede
            //    the string header and grow record by record), at the calibrated trailing size.
            foreach (var offset in HeaderOffsetCandidates(layout, options, payload.Length))
            {
                var candidate = TryCandidate(record, spec, lengths, offset, layout.TrailingSize,
                    expectedTitle, offset == layout.BaseStringHeaderOffset
                        ? ExtractionStrategy.Calibrated
                        : ExtractionStrategy.HeaderShift,
                    ref sawEmptyInterpretation);

                if (Accept(candidate, expectedTitle, ref tier1Titled, ref tier1Untitled))
                {
                    text = candidate;
                    return ExtractOutcome.Extracted;
                }
            }

            // 2) Trailing-size scan around the calibrated offset (records with conditional
            //    quest texts or other data appended after the strings).
            for (int shift = -16; shift <= 32; shift += 4)
            {
                var offset = layout.BaseStringHeaderOffset + shift;
                if (offset < 0 || offset + headerSize > payload.Length)
                    continue;

                var maxTrailing = Math.Min(options.MaxTrailingScan, payload.Length - offset - headerSize);
                for (int trailing = 0; trailing <= maxTrailing; trailing++)
                {
                    if (trailing == layout.TrailingSize)
                        continue;

                    var candidate = TryCandidate(record, spec, lengths, offset, trailing,
                        expectedTitle, ExtractionStrategy.TrailingScan, ref sawEmptyInterpretation);

                    if (Accept(candidate, expectedTitle, ref tier2Titled, ref tier2Untitled))
                    {
                        text = candidate;
                        return ExtractOutcome.Extracted;
                    }
                }
            }

            // 3) Locate the expected title bytes directly (strongest evidence, needs the corpus).
            if (expectedTitleBytes != null && expectedTitleBytes.Length > 0)
            {
                var searchFrom = 0;
                while (true)
                {
                    var titlePos = QuestCacheCalibrator.IndexOf(payload, expectedTitleBytes, searchFrom);
                    if (titlePos < 0)
                        break;

                    searchFrom = titlePos + 1;

                    var maxOffset = Math.Min(titlePos - headerSize, options.MaxHeaderOffset);
                    for (int offset = 0; offset <= maxOffset; offset++)
                    {
                        if (!spec.TryDecodeLengths(payload, offset, lengths))
                            break;

                        if (lengths[0] != expectedTitleBytes.Length)
                            continue;

                        var sum = QuestCacheCalibrator.Sum(lengths);
                        var trailing = payload.Length - (titlePos + sum);
                        if (trailing < 0)
                            continue;

                        var candidate = BuildCandidate(record, spec, lengths, offset, titlePos, trailing,
                            expectedTitle, ExtractionStrategy.CorpusLocate);

                        if (candidate != null && candidate.LogTitle == expectedTitle)
                        {
                            text = candidate;
                            return ExtractOutcome.Extracted;
                        }
                    }
                }
            }

            // No corpus-confirmed interpretation; fall back by structural confidence.
            text = tier1Titled ?? tier1Untitled ?? tier2Titled ?? tier2Untitled;
            if (text != null)
                return ExtractOutcome.Extracted;

            if (sawEmptyInterpretation)
                return ExtractOutcome.Empty;

            failureReason = DescribeFailure(payload, spec, lengths, layout);
            return ExtractOutcome.Failed;
        }

        private static IEnumerable<int> HeaderOffsetCandidates(
            QuestCacheLayout layout, QuestCacheParseOptions options, int payloadLength)
        {
            var baseOffset = layout.BaseStringHeaderOffset;
            if (baseOffset + layout.Spec.HeaderSizeBytes <= payloadLength)
                yield return baseOffset;

            for (int step = 1; step <= options.MaxHeaderShiftSteps; step++)
            {
                var offset = baseOffset + step * 4;
                if (offset + layout.Spec.HeaderSizeBytes > payloadLength)
                    break;
                yield return offset;
            }

            for (int step = 1; step <= 16; step++)
            {
                var offset = baseOffset - step * 4;
                if (offset < 0)
                    break;
                if (offset + layout.Spec.HeaderSizeBytes <= payloadLength)
                    yield return offset;
            }
        }

        /// <summary>
        /// A candidate matching the expected title (or any candidate when no expectation
        /// exists) is accepted immediately; otherwise it is remembered as a fallback.
        /// </summary>
        private static bool Accept(
            QuestRecordText candidate,
            string expectedTitle,
            ref QuestRecordText titledFallback,
            ref QuestRecordText untitledFallback)
        {
            if (candidate == null)
                return false;

            if (expectedTitle == null || candidate.LogTitle == expectedTitle)
                return true;

            if (candidate.LogTitle.Length > 0)
            {
                if (titledFallback == null)
                    titledFallback = candidate;
            }
            else if (untitledFallback == null)
            {
                untitledFallback = candidate;
            }

            return false;
        }

        private static QuestRecordText TryCandidate(
            WdbCacheRecord record,
            QuestStringBlockSpec spec,
            int[] lengths,
            int offset,
            int trailing,
            string expectedTitle,
            ExtractionStrategy strategy,
            ref bool sawEmptyInterpretation)
        {
            var payload = record.Payload;
            if (offset < 0 || !spec.TryDecodeLengths(payload, offset, lengths))
                return null;

            var sum = QuestCacheCalibrator.Sum(lengths);
            if (sum == 0)
            {
                // All string lengths zero: a consistent "record without text" interpretation
                // as long as the header itself fits before the trailing data.
                if (offset + spec.HeaderSizeBytes <= payload.Length - trailing)
                    sawEmptyInterpretation = true;
                return null;
            }

            var stringsStart = payload.Length - trailing - sum;
            if (stringsStart < offset + spec.HeaderSizeBytes)
                return null;

            return BuildCandidate(record, spec, lengths, offset, stringsStart, trailing, expectedTitle, strategy);
        }

        private static QuestRecordText BuildCandidate(
            WdbCacheRecord record,
            QuestStringBlockSpec spec,
            int[] lengths,
            int offset,
            int stringsStart,
            int trailing,
            string expectedTitle,
            ExtractionStrategy strategy)
        {
            var payload = record.Payload;
            var values = new string[lengths.Length];
            var pos = stringsStart;

            for (int i = 0; i < lengths.Length; i++)
            {
                if (!TextValidation.TryDecodeUtf8(payload, pos, lengths[i], out values[i]))
                    return null;
                pos += lengths[i];
            }

            if (values[0].Length > 0)
            {
                if (!TextValidation.IsPlausibleTitle(values[0]))
                    return null;
            }
            else
            {
                // Untitled records exist (hidden auto-quests) but demand stricter checks on
                // the remaining fields, since the title can no longer anchor the validation.
                for (int i = 1; i < values.Length; i++)
                {
                    if (values[i].Length > 0 && !TextValidation.IsLegalUnicode(values[i]))
                        return null;
                }
            }

            bool? matchesCorpus = null;
            if (expectedTitle != null && values[0].Length > 0)
                matchesCorpus = values[0] == expectedTitle;

            return new QuestRecordText
            {
                Id = record.Id,
                LogTitle = values[0],
                LogDescription = values[1],
                QuestDescription = values[2],
                AreaDescription = values[3],
                PortraitGiverText = values[4],
                PortraitGiverName = values[5],
                PortraitTurnInText = values[6],
                PortraitTurnInName = values[7],
                QuestCompletionLog = values[8],
                StringHeaderOffset = offset,
                TrailingSize = trailing,
                Strategy = strategy,
                MatchesCorpus = matchesCorpus,
            };
        }

        private static string DescribeFailure(
            byte[] payload, QuestStringBlockSpec spec, int[] lengths, QuestCacheLayout layout)
        {
            if (spec.TryDecodeLengths(payload, layout.BaseStringHeaderOffset, lengths))
            {
                var sum = QuestCacheCalibrator.Sum(lengths);
                return string.Format(
                    "no consistent interpretation (calibrated offset {0} decodes lengths [{1}] over {2} payload bytes)",
                    layout.BaseStringHeaderOffset, string.Join(",", ToStrings(lengths)), payload.Length);
            }

            return "payload smaller than calibrated string header offset (" + payload.Length + " bytes)";
        }

        private static string[] ToStrings(int[] values)
        {
            var result = new string[values.Length];
            for (int i = 0; i < values.Length; i++)
                result[i] = values[i].ToString();
            return result;
        }
    }
}
