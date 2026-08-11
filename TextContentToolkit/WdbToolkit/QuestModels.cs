using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;

namespace WdbToolkit
{
    /// <summary>How the string block of a record was located.</summary>
    public enum ExtractionStrategy
    {
        /// <summary>The calibrated layout applied directly.</summary>
        Calibrated,

        /// <summary>The string-length header was shifted by a multiple of 4 bytes
        /// (a variable-length array precedes it in this build).</summary>
        HeaderShift,

        /// <summary>The record carries extra trailing data (e.g. conditional quest texts);
        /// found by scanning trailing sizes.</summary>
        TrailingScan,

        /// <summary>Located by searching for the expected (corpus) title bytes.</summary>
        CorpusLocate,
    }

    /// <summary>All text extracted from one quest cache record.</summary>
    public sealed class QuestRecordText
    {
        public int Id { get; internal set; }

        public string LogTitle { get; internal set; }

        /// <summary>The objectives summary text shown in the quest log.</summary>
        public string LogDescription { get; internal set; }

        /// <summary>The long quest description.</summary>
        public string QuestDescription { get; internal set; }

        public string AreaDescription { get; internal set; }

        public string PortraitGiverText { get; internal set; }

        public string PortraitGiverName { get; internal set; }

        public string PortraitTurnInText { get; internal set; }

        public string PortraitTurnInName { get; internal set; }

        public string QuestCompletionLog { get; internal set; }

        /// <summary>Offset of the bit-packed string-length header inside the payload.</summary>
        public int StringHeaderOffset { get; internal set; }

        /// <summary>Bytes following the string block (0 for most records).</summary>
        public int TrailingSize { get; internal set; }

        public ExtractionStrategy Strategy { get; internal set; }

        /// <summary>Whether the title equals the expected title from the corpus
        /// (null when the corpus has no entry for this quest).</summary>
        public bool? MatchesCorpus { get; internal set; }
    }

    /// <summary>A record whose text could not be located.</summary>
    public sealed class QuestRecordFailure
    {
        public int Id { get; internal set; }

        public int PayloadLength { get; internal set; }

        public long FileOffset { get; internal set; }

        public string Reason { get; internal set; }
    }

    public sealed class QuestCacheStats
    {
        public int TotalRecords { get; internal set; }

        public int EmptyRecords { get; internal set; }

        public int Parsed { get; internal set; }

        public int Failed { get; internal set; }

        public int CorpusEntries { get; internal set; }

        public int CorpusMatched { get; internal set; }

        public int CorpusMismatched { get; internal set; }

        public Dictionary<int, int> HeaderOffsetHistogram { get; } = new Dictionary<int, int>();

        public Dictionary<int, int> TrailingSizeHistogram { get; } = new Dictionary<int, int>();

        public Dictionary<ExtractionStrategy, int> StrategyHistogram { get; } = new Dictionary<ExtractionStrategy, int>();
    }

    public sealed class QuestCacheParseOptions
    {
        /// <summary>
        /// Optional quest id -> expected title map (e.g. captured in game by the scanner addon).
        /// Greatly improves calibration confidence and enables recovery of records that the
        /// structural strategies cannot place.
        /// </summary>
        public IReadOnlyDictionary<int, string> ExpectedTitles { get; set; }

        /// <summary>String block layouts to try; defaults to <see cref="QuestStringBlockSpec.Modern"/>.</summary>
        public IList<QuestStringBlockSpec> Specs { get; set; }

        /// <summary>Number of records sampled for layout calibration.</summary>
        public int CalibrationSampleSize { get; set; } = 400;

        /// <summary>Maximum header offset considered during calibration.</summary>
        public int MaxHeaderOffset { get; set; } = 2048;

        /// <summary>Maximum number of +4 byte header shifts tried per record.</summary>
        public int MaxHeaderShiftSteps { get; set; } = 96;

        /// <summary>Maximum trailing byte count scanned per record.</summary>
        public int MaxTrailingScan { get; set; } = 2048;

        /// <summary>Optional sink for concise progress traces (null = silent).</summary>
        public Action<string> Trace { get; set; }
    }

    public sealed class QuestCacheParseResult
    {
        public string FilePath { get; internal set; }

        public WdbCacheHeader Header { get; internal set; }

        public QuestCacheLayout Layout { get; internal set; }

        public List<QuestRecordText> Quests { get; } = new List<QuestRecordText>();

        public List<QuestRecordFailure> Failures { get; } = new List<QuestRecordFailure>();

        public QuestCacheStats Stats { get; } = new QuestCacheStats();

        public List<string> Warnings { get; } = new List<string>();

        /// <summary>Human readable multi-line summary, meant for console/diagnostic output.</summary>
        public string BuildSummary()
        {
            var sb = new StringBuilder();
            sb.AppendLine(string.Format("{0}: {1}", FilePath, Header));
            if (Layout != null)
                sb.AppendLine("  layout: " + Layout.Describe());

            sb.AppendLine(string.Format(
                "  records={0} parsed={1} failed={2} empty={3}",
                Stats.TotalRecords, Stats.Parsed, Stats.Failed, Stats.EmptyRecords));

            if (Stats.CorpusEntries > 0)
                sb.AppendLine(string.Format(
                    "  corpus: entries={0} matched={1} mismatched={2}",
                    Stats.CorpusEntries, Stats.CorpusMatched, Stats.CorpusMismatched));

            if (Stats.StrategyHistogram.Count > 0)
                sb.AppendLine("  strategies: " + string.Join(", ",
                    Stats.StrategyHistogram.OrderByDescending(kv => kv.Value)
                        .Select(kv => kv.Key + "=" + kv.Value)));

            if (Stats.HeaderOffsetHistogram.Count > 1)
                sb.AppendLine("  header offsets: " + HistogramText(Stats.HeaderOffsetHistogram) +
                              "  (offset varies per record => a variable-length array precedes the string header)");

            if (Stats.TrailingSizeHistogram.Count > 1)
                sb.AppendLine("  trailing sizes: " + HistogramText(Stats.TrailingSizeHistogram));

            foreach (var warning in Warnings)
                sb.AppendLine("  warning: " + warning);

            return sb.ToString();
        }

        private static string HistogramText(Dictionary<int, int> histogram)
        {
            var parts = histogram.OrderByDescending(kv => kv.Value).Take(8)
                .Select(kv => kv.Key + "x" + kv.Value);
            var text = string.Join(", ", parts);
            if (histogram.Count > 8)
                text += ", ...";
            return text;
        }
    }
}
