using System;
using System.CodeDom;
using System.Collections.Generic;
using System.Collections.Specialized;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using TextContentToolkit.Configs;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;
using TextContentToolkit.Utils;

namespace TextContentToolkit
{
    public class ItemReader : TooltipsReader
    {
        public ItemReader(ItemConfig itemConfig)
        {
            TooltipsConfig = itemConfig;
        }

        private static readonly List<string> BlackListedText = new List<string>
        {
            "你尚未收藏过此外观",
        };

        private void Read(string tooltipPath, Dictionary<string, Tooltip> itemTipsList)
        {
            var lines = File.ReadAllLines(tooltipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var itemTips = new Tooltip();
                var text = line.Trim();
                if (string.IsNullOrEmpty(text) || !text.StartsWith("["))
                    continue;

                var id = text.Split(new string[] {"[\""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\"]"}, StringSplitOptions.None)[0]
                    .Trim();

                var type = text.FirstBetween("{{{", "}}}");

                if (usedId.Contains(id))
                    continue;
                else
                {
                    usedId.Add(id);
                }

                itemTips.Id = id;
                itemTips.Type = type;
                if (!text.Contains("{{"))
                    continue;
                text = text.Replace("]] \"","]]\"").Replace("]]  \"", "]]\"");
                var textContent = text.Split(new string[] {"= \""}, StringSplitOptions.None)[1]
                    .Split(new[] { "]]\"," }, StringSplitOptions.None)[0]
                    .Trim() + "]]";

                var currentIndex = 0;
                while (!string.IsNullOrEmpty(textContent) && !textContent.TrimStart().StartsWith("{{{"))
                {
                    currentIndex++;
                    textContent = textContent.TrimTextAfter("{{");

                    var tipLine = textContent.GetTextBefore("}}");
                    textContent = textContent.TrimTextAfter("[[");
                    var r = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("[[");
                    var g = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("[[");
                    var b = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("]]");

                    var itemTipLine = new TooltipLine();

                    itemTipLine.Line = tipLine;
                    itemTipLine.R = Math.Round(double.Parse(r), 2);
                    itemTipLine.G = Math.Round(double.Parse(g), 2);
                    itemTipLine.B = Math.Round(double.Parse(b), 2);
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
                        //if (r == "0.99999779462814" && g == "0.82352757453918" && b == "0")
                        if (itemTipLine.Line.StartsWith("\\\""))
                            gearApproved = true;
                    }

                    if (!gearApproved)
                        continue;

                    // blacklisted
                    if (BlackListedText.Contains(itemTipLine.Line))
                        continue;

                    // red
                    if (r == "0.99999779462814" && g == "0.12548992037773" && b == "0.12548992037773")
                        continue;

                    if (r == "1" && g == "0.12549020349979" && b == "0.12549020349979")
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
                    itemTips.TooltipLines.Add(new TooltipLine() { Line = " " });

                itemTipsList[id] = itemTips;
            }
        }

        protected override void Write(string outputPath, List<string> inputPaths, OutputMode outputMode = OutputMode.WoWeuCN, string locale = "zhCN")
        {
            var itemTipList = new Dictionary<string, Tooltip>();

            foreach (var inputPath in inputPaths)
            {
                Read(inputPath, itemTipList);
            }

            if (outputMode == OutputMode.WoWeuCN)
                WriteToWoWEuCN(outputPath, itemTipList);
            else
                WriteToQuestie(outputPath, locale, itemTipList);
        }

        private void WriteToQuestie(string outputPath, string locale, Dictionary<string, Tooltip> itemTipList)
        {
            var filterPath = TooltipsConfig.QuestieFilterPath;

            var useFilter = !string.IsNullOrEmpty(filterPath);

            var validIds = new HashSet<string>();
            if (useFilter)
            {
                var lines = File.ReadAllLines(filterPath);
                foreach (var line in lines)
                {
                    if (!line.Trim().StartsWith("["))
                        continue;

                    var id = line.FirstBetween("[", "]");
                    validIds.Add(id);
                }
            }

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

                validIds.Remove(itemTips.Id);

                if (!itemTips.TooltipLines.Any())
                    continue;

                sb.Append("[").Append(itemTips.Id).Append("] = \"");
                sb.Append(itemTips.TooltipLines.First().Line);
                sb.Append("\",");
                validIds.Remove(itemTips.Id);
                sb.AppendLine();
            }

            sb.AppendLine("}");

            File.WriteAllText(outputPath, sb.ToString());
        }

        private static void WriteToWoWEuCN(string outputPath, Dictionary<string, Tooltip> itemTipList)
        {
            var sb = new StringBuilder();
            var itemTipOrderedList = itemTipList.Select(i => i.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var idIndexMapping = new int[100001];
            var maxItemId = 1;
            foreach (var itemTips in itemTipOrderedList)
            {
                if (int.Parse(itemTips.Id) >= currentBlock + 100000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();
                    sb.AppendLine("WoWeuCN_Tooltips_ItemIndexData_" + currentBlock + " = {");
                    for (int i = 1; i <= maxItemId; ++i)
                    {
                        if (idIndexMapping[i] != 0)
                            sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                        else
                            sb.Append("nil,");
                    }

                    sb.AppendLine().Append("};").AppendLine();
                    maxItemId = 1;
                    idIndexMapping = new int[100001];
                    while (int.Parse(itemTips.Id) >= currentBlock + 100000)
                    {
                        currentBlock += 100000;
                    }

                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadItemData" + currentBlock + "()");
                    sb.AppendLine("WoWeuCN_Tooltips_ItemData_" + currentBlock + " = {");
                }

                // sb.Append("[\"").Append(itemTips.Id).Append("\"]={");

                sb.Append("\"");
                foreach (var itemTipLine in itemTips.TooltipLines)
                {
                    if (itemTipLine.Line.Contains(@"需要等级"))
                        Console.Write(true);
                    int r = (int) (itemTipLine.R * 255);
                    int g = (int) (itemTipLine.G * 255);
                    int b = (int) (itemTipLine.B * 255);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        sb.Append(itemTipLine.Line).Append("£");
                    }
                    else
                    {
                        var rText = Convert.ToString(r, 16);
                        while (rText.Length < 2)
                        {
                            rText = "0" + rText;
                        }

                        var gText = Convert.ToString(g, 16);
                        while (gText.Length < 2)
                        {
                            gText = "0" + rText;
                        }

                        var bText = Convert.ToString(b, 16);
                        while (bText.Length < 2)
                        {
                            bText = "0" + bText;
                        }

                        var colourText = "|c" + "ff" + rText + gText + bText;
                        var text = itemTipLine.Line.Replace("|c", "|#|c").Replace("|r", "|r" + colourText)
                            .Replace("|#", "|r");

                        text = colourText + text + "|r";
                        text = text.Replace(colourText + "|r", string.Empty);
                        sb.Append(text).Append("£");
                    }
                }

                if (itemTips.TooltipLines.Any())
                    sb.Remove(sb.Length - 1, 1);

                sb.Append("\",").Append(" --" + itemTips.Id).AppendLine();

                currentIndex++;
                idIndexMapping[int.Parse(itemTips.Id) - currentBlock] = currentIndex;
                maxItemId = int.Parse(itemTips.Id) - currentBlock;
            }

            sb.Append("};").AppendLine();

            // last block index
            sb.AppendLine("WoWeuCN_Tooltips_ItemIndexData_" + currentBlock + " = {");
            for (int i = 1; i <= maxItemId; ++i)
            {
                if (idIndexMapping[i] != 0)
                    sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                else
                    sb.Append("nil,");
            }

            sb.AppendLine().Append("};").AppendLine();


            sb.Append("end");

            //foreach (var itemTips in itemTipList.OrderBy(q => int.Parse(q.Id)))
            //{
            //    sb.Append("[\"").Append(itemTips.Id).Append("\"]={");
            //    foreach (var itemTipLine in itemTips.SpellTipLines)
            //    {
            //        sb.Append("{\"").Append(itemTipLine.Line).Append("\",").Append(itemTipLine.R).Append(",")
            //            .Append(itemTipLine.G).Append(",").Append(itemTipLine.B).Append("},");
            //    }
            //    if (itemTips.SpellTipLines.Any())
            //        sb.Remove(sb.Length - 1, 1);

            //    sb.Append("},");
            //    sb.AppendLine();
            //}

            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}
