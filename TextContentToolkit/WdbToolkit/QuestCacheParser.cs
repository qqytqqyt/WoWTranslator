using System.Collections.Generic;
using System.Text;

namespace WdbToolkit
{
    /// <summary>
    /// High level entry point: reads a quest cache (questcache.wdb) of any supported
    /// client build, infers the record layout automatically and extracts all texts.
    /// </summary>
    public static class QuestCacheParser
    {
        public static QuestCacheParseResult ParseFile(string filePath, QuestCacheParseOptions options = null)
        {
            return Parse(WdbCacheFile.Load(filePath), options);
        }

        public static QuestCacheParseResult Parse(WdbCacheFile file, QuestCacheParseOptions options = null)
        {
            options = options ?? new QuestCacheParseOptions();

            var result = new QuestCacheParseResult
            {
                FilePath = file.FilePath,
                Header = file.Header,
            };
            result.Warnings.AddRange(file.Warnings);

            var corpusTitleBytes = BuildCorpusBytes(options.ExpectedTitles);
            result.Stats.CorpusEntries = corpusTitleBytes == null ? 0 : corpusTitleBytes.Count;
            result.Stats.TotalRecords = file.Records.Count;

            var layout = QuestCacheCalibrator.Calibrate(file.Records, options, corpusTitleBytes);
            result.Layout = layout;

            foreach (var record in file.Records)
            {
                if (record.Payload.Length < layout.Spec.HeaderSizeBytes)
                {
                    result.Stats.EmptyRecords++;
                    continue;
                }

                byte[] titleBytes = null;
                string expectedTitle = null;
                if (corpusTitleBytes != null && corpusTitleBytes.TryGetValue(record.Id, out titleBytes))
                    expectedTitle = options.ExpectedTitles[record.Id];

                QuestRecordText text;
                string failureReason;
                var outcome = QuestRecordExtractor.TryExtract(record, layout, options, titleBytes, expectedTitle,
                    out text, out failureReason);

                if (outcome == ExtractOutcome.Extracted)
                {
                    result.Quests.Add(text);
                    result.Stats.Parsed++;
                    Increment(result.Stats.HeaderOffsetHistogram, text.StringHeaderOffset);
                    Increment(result.Stats.TrailingSizeHistogram, text.TrailingSize);

                    int strategyCount;
                    result.Stats.StrategyHistogram.TryGetValue(text.Strategy, out strategyCount);
                    result.Stats.StrategyHistogram[text.Strategy] = strategyCount + 1;

                    if (text.MatchesCorpus == true)
                        result.Stats.CorpusMatched++;
                    else if (text.MatchesCorpus == false)
                        result.Stats.CorpusMismatched++;
                }
                else if (outcome == ExtractOutcome.Empty)
                {
                    result.Stats.EmptyRecords++;
                }
                else
                {
                    result.Stats.Failed++;
                    result.Failures.Add(new QuestRecordFailure
                    {
                        Id = record.Id,
                        PayloadLength = record.Payload.Length,
                        FileOffset = record.FileOffset,
                        Reason = failureReason,
                    });
                }
            }

            return result;
        }

        private static Dictionary<int, byte[]> BuildCorpusBytes(IReadOnlyDictionary<int, string> expectedTitles)
        {
            if (expectedTitles == null || expectedTitles.Count == 0)
                return null;

            var result = new Dictionary<int, byte[]>(expectedTitles.Count);
            foreach (var pair in expectedTitles)
            {
                if (!string.IsNullOrEmpty(pair.Value))
                    result[pair.Key] = Encoding.UTF8.GetBytes(pair.Value);
            }

            return result;
        }

        private static void Increment(Dictionary<int, int> histogram, int key)
        {
            int count;
            histogram.TryGetValue(key, out count);
            histogram[key] = count + 1;
        }
    }
}
