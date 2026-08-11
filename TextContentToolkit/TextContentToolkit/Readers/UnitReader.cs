using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;

namespace TextContentToolkit
{
    public class UnitReader : TooltipsReader
    {
        internal override WoWeuCNWriterProfile Profile
        {
            get
            {
                return new WoWeuCNWriterProfile
                {
                    EntityName = "Unit",
                    HeaderIndent = "  ",
                    EncodeColors = false,
                    SkipRecord = ShouldSkip
                };
            }
        }

        private static bool ShouldSkip(Tooltip unitTips)
        {
            if (!unitTips.TooltipLines.Any())
                return true;

            // pure ASCII first line means the name was never localized
            return unitTips.TooltipLines[0].Line.All(c => c < 256);
        }

        protected override bool IsRelevantSection(string tableName)
        {
            return tableName.Contains("UnitToolTips");
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

                var unitTips = new Tooltip { Id = raw.Id };
                foreach (var entry in raw.Entries)
                {
                    if (entry.Line.StartsWith("等級") || entry.Line.StartsWith("等级") || entry.Line.Contains("??"))
                        break;

                    unitTips.TooltipLines.Add(new TooltipLine { Line = entry.Line });
                }

                Store(tips, unitTips);
            }
        }

        public void WriteToQuestie(string outputPath, string locale, Dictionary<string, Tooltip> unitTipList, string filterPath = null)
        {
            var validIds = ReadQuestieFilter(filterPath);
            var useFilter = validIds.Count > 0;

            var unitTipOrderedList = unitTipList.Select(u => u.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            var sb = new StringBuilder();

            var preText = @"if GetLocale() ~= ""localeCode"" then
    return
end

-- - @type l10n
local l10n = QuestieLoader:ImportModule(""l10n"")

l10n.npcNameLookup[""localeCode""] = { ";
            preText = preText.Replace("localeCode", locale);

            sb.AppendLine(preText);

            foreach (var unitTips in unitTipOrderedList)
            {
                if (useFilter && !validIds.Contains(unitTips.Id))
                    continue;

                if (!unitTips.TooltipLines.Any())
                    continue;

                sb.Append("[").Append(unitTips.Id).Append("] = {\"");
                sb.Append(unitTips.TooltipLines.First().Line);
                sb.Append("\",");
                if (unitTips.TooltipLines.Count >= 2)
                {
                    sb.Append("\"").Append(unitTips.TooltipLines[1].Line).Append("\"},");
                }
                else
                {
                    sb.Append("nil},");
                }

                sb.AppendLine();
            }

            sb.AppendLine("}");

            File.WriteAllText(outputPath, sb.ToString());
        }

        public void ReadForQuestie(string inputPath, Dictionary<string, Tooltip> tips)
        {
            Read(inputPath, tips);
        }
    }
}
