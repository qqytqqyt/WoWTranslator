using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;
using TextContentToolkit.Utils;

namespace TextContentToolkit
{
    public class ItemReader : TooltipsReader
    {
        private static readonly List<string> BlackListedText = new List<string>
        {
            "你尚未收藏过此外观",
        };

        internal override WoWeuCNWriterProfile Profile
        {
            get
            {
                return new WoWeuCNWriterProfile
                {
                    EntityName = "Item",
                    HeaderIndent = string.Empty,
                    EncodeColors = true,
                    RoundColorChannels = false
                };
            }
        }

        protected override bool IsRelevantSection(string tableName)
        {
            return tableName.Contains("ItemToolTips");
        }

        protected override void Read(string inputPath, Dictionary<string, Tooltip> tips)
        {
            var usedId = new HashSet<string>();
            foreach (var line in ReadCategoryLines(inputPath))
            {
                var raw = ScannerTooltipParser.TryParse(line, stripRedColorCodes: false, hasTypeMarker: true);
                if (raw == null)
                    continue;

                if (usedId.Contains(raw.Id))
                    continue;
                usedId.Add(raw.Id);

                if (!raw.HasBody)
                    continue;

                var itemTips = new Tooltip { Id = raw.Id, Type = raw.Type };
                var currentIndex = 0;
                foreach (var entry in raw.Entries)
                {
                    currentIndex++;

                    var itemTipLine = new TooltipLine
                    {
                        Line = entry.Line,
                        R = Math.Round(double.Parse(entry.R), 2),
                        G = Math.Round(double.Parse(entry.G), 2),
                        B = Math.Round(double.Parse(entry.B), 2)
                    };

                    var gearApproved = true;
                    var isGear = itemTips.Type == "4" || itemTips.Type == "2";
                    if (isGear)
                    {
                        gearApproved = false;

                        // name
                        if (currentIndex == 1)
                            gearApproved = true;

                        // usage description
                        if (itemTipLine.Line.StartsWith(@"装备：") || itemTipLine.Line.StartsWith(@"使用："))
                            gearApproved = true;

                        // yellow description
                        if (itemTipLine.Line.StartsWith("\\\""))
                            gearApproved = true;
                    }

                    if (!gearApproved)
                        continue;

                    // blacklisted
                    if (BlackListedText.Contains(itemTipLine.Line))
                        continue;

                    // red
                    if (entry.R == "0.99999779462814" && entry.G == "0.12548992037773" && entry.B == "0.12548992037773")
                        continue;

                    if (entry.R == "1" && entry.G == "0.12549020349979" && entry.B == "0.12549020349979")
                        continue;

                    if (isGear)
                    {
                        foreach (var grayedOutIndicator in StringUtils.GrayedOutIndicatorText)
                        {
                            var matches = Regex.Matches(itemTipLine.Line, @"(\d+(,\d+)*)" + grayedOutIndicator).OfType<Match>().ToList();
                            var orderedMatches = matches.OrderByDescending(m => m.Length);
                            foreach (var match in orderedMatches)
                            {
                                var result = match.Result("$1");
                                result = "|cff7f7f7f" + result + "|r";
                                itemTipLine.Line = itemTipLine.Line.Replace(match.Value, result + grayedOutIndicator);
                            }
                        }
                    }

                    itemTips.TooltipLines.Add(itemTipLine);
                }

                if (itemTips.TooltipLines.Any(t => t.Line == @"炉石"))
                    continue;

                if (itemTips.TooltipLines.Count == 1)
                    itemTips.TooltipLines.Add(new TooltipLine { Line = " " });

                Store(tips, itemTips);
            }
        }

        public void WriteToQuestie(string outputPath, string locale, Dictionary<string, Tooltip> itemTipList, string filterPath = null)
        {
            var validIds = ReadQuestieFilter(filterPath);
            var useFilter = validIds.Count > 0;

            var sb = new StringBuilder();
            var preText = @"if GetLocale() ~= ""localeCode"" then
    return
end

-- - @type l10n
local l10n = QuestieLoader:ImportModule(""l10n"")

l10n.itemLookup[""localeCode""] = { ";
            preText = preText.Replace("localeCode", locale);
            sb.AppendLine(preText);
            var itemTipOrderedList = itemTipList.Select(i => i.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            foreach (var itemTips in itemTipOrderedList)
            {
                if (useFilter && !validIds.Contains(itemTips.Id))
                    continue;

                if (!itemTips.TooltipLines.Any())
                    continue;

                sb.Append("[").Append(itemTips.Id).Append("] = \"");
                sb.Append(itemTips.TooltipLines.First().Line);
                sb.Append("\",");
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
