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
    public class AchievementReader : TooltipsReader
    {
        public AchievementReader(AchievementConfig achievementConfig)
        {
            TooltipsConfig = achievementConfig;
        }

        private void Read(string achievementTipPath, Dictionary<string, Tooltip> achievementTipsList)
        {
            var lines = File.ReadAllLines(achievementTipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var achievementTips = new Tooltip();
                var text = line.Trim();

                if (string.IsNullOrEmpty(text) || !text.StartsWith("["))
                    continue;

                var id = text.Split(new string[] { "[\"" }, StringSplitOptions.None)[1]
                    .Split(new[] { "\"]" }, StringSplitOptions.None)[0]
                    .Trim();

                achievementTips.Id = id;
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
                    if (tipLine.StartsWith("获取数据"))
                        continue;

                    // red
                    achievementTips.TooltipLines.Add(spellTipLine);
                    if (achievementTips.TooltipLines.Count == 2)
                        break;
                }

                achievementTipsList[id] = achievementTips;
            }
        }
        
        protected override void Write(string outputPath, List<string> inputPaths, OutputMode outputMode = OutputMode.WoWeuCN, string locale = "zhCN")
        {
            var achievementTipList = new Dictionary<string, Tooltip>();

            foreach (var inputPath in inputPaths)
            {
                Read(inputPath, achievementTipList);
            }

            if (outputMode == OutputMode.WoWeuCN)
                WriteToWoWEuCN(outputPath, achievementTipList);
        }

        private static void WriteToWoWEuCN(string outputPath, Dictionary<string, Tooltip> achievementTipList)
        {
            var sb = new StringBuilder();
            var achievementTipOrderedList = achievementTipList.Select(u => u.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxAchievementId = 1;
            var countA = 0;
            int countB = 0;
            var text = "";
            var idIndexMapping = new int[100001];
            foreach (var achievementTips in achievementTipOrderedList)
            {
                if (int.Parse(achievementTips.Id) >= currentBlock + 100000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();

                    sb.AppendLine("WoWeuCN_Tooltips_AchievementIndexData_" + currentBlock + " = {");
                    for (int i = 1; i <= maxAchievementId; ++i)
                    {
                        if (idIndexMapping[i] != 0)
                            sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                        else
                            sb.Append("nil,");
                    }

                    sb.AppendLine().Append("};").AppendLine();
                    maxAchievementId = 1;
                    idIndexMapping = new int[100001];

                    currentBlock += 100000;
                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadAchievementData" + currentBlock + "()");
                    sb.AppendLine("  WoWeuCN_Tooltips_AchievementData_" + currentBlock + " = {");
                    currentIndex = 1;
                }

                var tempSb = new StringBuilder();
                tempSb.Append("\"");
                foreach (var spellTipLine in achievementTips.TooltipLines)
                {
                    tempSb.Append(spellTipLine.Line).Append("£");
                }

                // remove empty spelltips
                if (!achievementTips.TooltipLines.Any())
                {
                    countA++;
                    continue;
                }

                if (achievementTips.TooltipLines[0].Line.All(c => c < 256))
                {
                    text += achievementTips.TooltipLines[0].Line;
                    countB++;
                    continue;
                }

                sb.Append(tempSb);
                sb.Remove(sb.Length - 1, 1);

                sb.Append("\",").Append(" --" + achievementTips.Id).AppendLine();

                idIndexMapping[int.Parse(achievementTips.Id) - currentBlock] = currentIndex;
                maxAchievementId = int.Parse(achievementTips.Id) - currentBlock;
                currentIndex++;
            }

            sb.Append("};").AppendLine();
            sb.AppendLine("WoWeuCN_Tooltips_AchievementIndexData_" + currentBlock + " = {");
            for (int i = 1; i <= maxAchievementId; ++i)
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
