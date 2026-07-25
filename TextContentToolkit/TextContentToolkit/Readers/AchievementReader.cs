using System.Collections.Generic;
using System.IO;
using System.Linq;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;

namespace TextContentToolkit
{
    public class AchievementReader : TooltipsReader
    {
        internal override WoWeuCNWriterProfile Profile
        {
            get
            {
                return new WoWeuCNWriterProfile
                {
                    EntityName = "Achievement",
                    HeaderIndent = "  ",
                    EncodeColors = false,
                    SkipRecord = ShouldSkip
                };
            }
        }

        private static bool ShouldSkip(Tooltip achievementTips)
        {
            if (!achievementTips.TooltipLines.Any())
                return true;

            // pure ASCII first line means the name was never localized
            return achievementTips.TooltipLines[0].Line.All(c => c < 256);
        }

        protected override bool IsRelevantSection(string tableName)
        {
            // "Achivements" is the addon's own spelling; excludes AchivementNameData
            return tableName.Contains("Achivements") || tableName.Contains("Achievements");
        }

        protected override void Read(string inputPath, Dictionary<string, Tooltip> tips)
        {
            var usedId = new HashSet<string>();
            foreach (var line in ReadCategoryLines(inputPath))
            {
                var raw = ScannerTooltipParser.TryParse(line, stripRedColorCodes: true, hasTypeMarker: false);
                if (raw == null)
                    continue;

                if (usedId.Contains(raw.Id))
                    continue;
                usedId.Add(raw.Id);

                if (!raw.HasBody)
                    continue;

                var achievementTips = new Tooltip { Id = raw.Id };
                foreach (var entry in raw.Entries)
                {
                    if (entry.Line.StartsWith("获取数据"))
                        continue;

                    achievementTips.TooltipLines.Add(new TooltipLine { Line = entry.Line });
                    if (achievementTips.TooltipLines.Count == 2)
                        break;
                }

                Store(tips, achievementTips);
            }
        }
    }
}
