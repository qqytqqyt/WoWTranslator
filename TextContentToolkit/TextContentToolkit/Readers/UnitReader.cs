using TextContentToolkit.Models;
using TextContentToolkit.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using TextContentToolkit.Configs;
using TextContentToolkit.Readers;

namespace TextContentToolkit
{
    public class UnitReader : TooltipsReader
    {
        public UnitReader(UnitConfig unitConfig)
        {
            TooltipsConfig = unitConfig;
        }

        private void Read(string unitTipPath, Dictionary<string, Tooltip> unitTipsList)
        {
            var lines = File.ReadAllLines(unitTipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var unitTips = new Tooltip();
                var text = line.Trim();

                if (string.IsNullOrEmpty(text) || !text.StartsWith("["))
                    continue;

                var id = text.Split(new string[] { "[\"" }, StringSplitOptions.None)[1]
                    .Split(new[] { "\"]" }, StringSplitOptions.None)[0]
                    .Trim();

                unitTips.Id = id;
                if (usedId.Contains(id))
                    continue;
                else
                {
                    usedId.Add(id);
                }

                if (!text.Contains("{{"))
                    continue;
                text = text.Replace("]] \"", "]]\"").Replace("]]  \"", "]]\"");
                var textContent = text.Split(new string[] { "= \"" }, StringSplitOptions.None)[1]
                    .Split(new[] { "]]\"," }, StringSplitOptions.None)[0]
                    .Trim() + "]]";

                while (!string.IsNullOrEmpty(textContent))
                {
                    textContent = textContent.TrimTextAfter("{{");

                    // remove red text
                    if (textContent.Contains(@"|cffff2020"))
                        textContent = textContent.Replace(@"|cffff2020", string.Empty).Replace(@"|r", string.Empty);
                    if (textContent.Contains(@"|cffff2121"))
                        textContent = textContent.Replace(@"|cffff2121", string.Empty).Replace(@"|r", string.Empty);

                    var tipLine = textContent.GetTextBefore("}}");
                    textContent = textContent.TrimTextAfter("[[");
                    var r = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("[[");
                    var g = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("[[");
                    var b = textContent.GetTextBefore("]]");
                    textContent = textContent.TrimTextAfter("]]");

                    var spellTipLine = new TooltipLine();
                    spellTipLine.Line = tipLine;
                    if (tipLine.StartsWith("等級") || tipLine.StartsWith("等级") || tipLine.Contains("??"))
                        break;

                    // red
                    unitTips.TooltipLines.Add(spellTipLine);
                    
                }

                unitTipsList[id] = unitTips;
            }
        }
        
        protected override void Write(string outputPath, List<string> inputPaths, OutputMode outputMode, string locale = "zhCN")
        {
            var unitTipList = new Dictionary<string, Tooltip>();

            foreach (var inputPath in inputPaths)
            {
                Read(inputPath, unitTipList);
            }

            if (outputMode == OutputMode.WoWeuCN)
                WriteToWoWEuCN(outputPath, unitTipList);
            else
                WriteToQuestie(outputPath, locale, unitTipList);
        }

        private void WriteToQuestie(string outputPath, string locale, Dictionary<string, Tooltip> unitTipList)
        {

            var useFilter = !string.IsNullOrEmpty(TooltipsConfig.QuestieFilterPath);

            var validIds = new HashSet<string>();
            if (useFilter)
            {
                var lines = File.ReadAllLines(TooltipsConfig.QuestieFilterPath);
                foreach (var line in lines)
                {
                    if (!line.Trim().StartsWith("["))
                        continue;

                    var id = line.FirstBetween("[", "]");
                    validIds.Add(id);
                }
            }

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

                validIds.Remove(unitTips.Id);
                sb.AppendLine();
            }

            sb.AppendLine("}");

            File.WriteAllText(outputPath, sb.ToString());
        }

        private static void WriteToWoWEuCN(string outputPath, Dictionary<string, Tooltip> unitTipList)
        {
            var sb = new StringBuilder();
            var unitTipOrderedList = unitTipList.Select(u => u.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxUnitId = 1;
            var countA = 0;
            int countB = 0;
            var text = "";
            var idIndexMapping = new int[100001];
            foreach (var unitTips in unitTipOrderedList)
            {
                if (int.Parse(unitTips.Id) >= currentBlock + 100000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();

                    sb.AppendLine("WoWeuCN_Tooltips_UnitIndexData_" + currentBlock + " = {");
                    for (int i = 1; i <= maxUnitId; ++i)
                    {
                        if (idIndexMapping[i] != 0)
                            sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                        else
                            sb.Append("nil,");
                    }

                    sb.AppendLine().Append("};").AppendLine();
                    maxUnitId = 1;
                    idIndexMapping = new int[100001];

                    while (int.Parse(unitTips.Id) >= currentBlock + 100000)
                    {
                        currentBlock += 100000;
                    }

                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadUnitData" + currentBlock + "()");
                    sb.AppendLine("  WoWeuCN_Tooltips_UnitData_" + currentBlock + " = {");
                    currentIndex = 1;
                }

                var tempSb = new StringBuilder();
                tempSb.Append("\"");
                foreach (var spellTipLine in unitTips.TooltipLines)
                {
                    tempSb.Append(spellTipLine.Line).Append("£");
                }

                // remove empty spelltips
                if (!unitTips.TooltipLines.Any())
                {
                    countA++;
                    continue;
                }

                if (unitTips.TooltipLines[0].Line.All(c => c < 256))
                {
                    text += unitTips.TooltipLines[0].Line;
                    countB++;
                    continue;
                }

                sb.Append(tempSb);
                sb.Remove(sb.Length - 1, 1);

                sb.Append("\",").Append(" --" + unitTips.Id).AppendLine();

                idIndexMapping[int.Parse(unitTips.Id) - currentBlock] = currentIndex;
                maxUnitId = int.Parse(unitTips.Id) - currentBlock;
                currentIndex++;
            }

            sb.Append("};").AppendLine();
            sb.AppendLine("WoWeuCN_Tooltips_UnitIndexData_" + currentBlock + " = {");
            for (int i = 1; i <= maxUnitId; ++i)
            {
                if (idIndexMapping[i] != 0)
                    sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                else
                    sb.Append("nil,");
            }

            sb.AppendLine().Append("};").AppendLine();

            sb.Append("end");
            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}
