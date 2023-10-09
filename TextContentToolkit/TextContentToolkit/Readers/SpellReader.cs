using System;
using System.Collections.Generic;
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
    public class SpellReader : TooltipsReader
    {
        public SpellReader(SpellConfig spellConfig)
        {
            TooltipsConfig = spellConfig;
        }

        private readonly static List<string> BlackListedPostfix = new List<string>()
        {
            "瞬发",
            "冷却时间",
            "施法时间",
            "需引导",
            "被动"
        };

        private readonly Dictionary<string, string> TextToSim = new Dictionary<string, string>
        {
            { "瞬发", "À" },
            { "施法时间", "Á" },
            { "码射程", "Â" },
            { "秒", "Ã" },
            { "冷却时间", "Ä" },
            { "|cffffd100", "Å" },
            { "|r|cff7f7f7f", "Æ" },
            { "|r", "Ç" },
            { "近战范围", "È" },
            { "持续", "É" },
            { "造成", "Ê" },

            { "点伤害", "Ë" },
            { "点治疗", "Ì" },
            { "点生命值", "Í" },
            { "点法力值", "Î" },
            { "点物理伤害", "Ï" },
            { "点魔法伤害", "Ð" },
            { "点火焰伤害", "Ñ" },
            { "点冰霜伤害", "Ò" },
            { "点暗影伤害", "Ó" },
            { "点神圣伤害", "Ô" },
            { "点奥术伤害", "Õ" },
            { "点混乱伤害", "Ö" },
            { "点流血伤害", "Ø" }
        };

        private void Read(string spellTipPath, Dictionary<string, Tooltip> spellTipsList)
        {
            var lines = File.ReadAllLines(spellTipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var spellTips = new Tooltip();
                var text = line.Trim();

                if (string.IsNullOrEmpty(text) || !text.StartsWith("[") || text.Contains("DND"))
                    continue;

                var id = text.Split(new string[] {"[\""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\"]"}, StringSplitOptions.None)[0]
                    .Trim();

                spellTips.Id = id;
                if (usedId.Contains(id))
                    continue;
                else
                {
                    usedId.Add(id);
                }

                if (!text.Contains("{{"))
                    continue;
                text = text.Replace("]] \"","]]\"").Replace("]]  \"", "]]\"");
                var textContent = text.Split(new string[] {"= \""}, StringSplitOptions.None)[1]
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

                    if (!spellTips.TooltipLines.Any() && !tipLine.HasChinese())
                        break;

                    // red
                    if (r == "0.99999779462814" && g == "0.12548992037773" && b == "0.12548992037773")
                        continue;

                    if (r == "1" && g == "0.12549020349979" && b == "0.12549020349979")
                        continue;

                    spellTipLine.R = Math.Round(double.Parse(r), 2);
                    spellTipLine.G = Math.Round(double.Parse(g), 2);
                    spellTipLine.B = Math.Round(double.Parse(b), 2);

                    foreach (var grayedOutIndicator in StringUtils.GrayedOutIndicatorText)
                    {
                        var matches = Regex.Matches(spellTipLine.Line, @"(\d+(,\d+)*)" + grayedOutIndicator).OfType<Match>().ToList();
                        var orderedMatches = matches.OrderByDescending(m => m.Length);
                        foreach (var match in orderedMatches)
                        {
                            var result = match.Result("$1");
                            result = "|cff7f7f7f" + result + "|r";
                            spellTipLine.Line = spellTipLine.Line.Replace(match.Value, result + grayedOutIndicator);
                        }
                    }

                    spellTips.TooltipLines.Add(spellTipLine);
                }

                if (!spellTips.TooltipLines.Any())
                    continue;

                spellTipsList[id] = spellTips;
            }
        }

        protected override void Write(string outputPath, List<string> inputPaths, OutputMode outputMode, string locale = "zhCN")
        {
            var spellTipList = new Dictionary<string, Tooltip>();
            foreach (var inputPath in inputPaths)
            {
                Read(inputPath, spellTipList);
            }

            if (outputMode == OutputMode.WoWeuCN)
                WriteToWoWeuCN(outputPath, spellTipList);
        }

        private void WriteToWoWeuCN(string outputPath, Dictionary<string, Tooltip> spellTipList)
        {
            var sb = new StringBuilder();
            var spellTipOrderedList = spellTipList.Select(s => s.Value).OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxSpellId = 1;
            var idIndexMapping = new int[100001];

            string lastLine = string.Empty;
            string lastId = string.Empty;
            var counter = 0;
            foreach (var spellTips in spellTipOrderedList)
            {
                if (int.Parse(spellTips.Id) >= currentBlock + 100000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();

                    sb.AppendLine("WoWeuCN_Tooltips_SpellIndexData_" + currentBlock + " = {");
                    for (int i = 1; i <= maxSpellId; ++i)
                    {
                        if (idIndexMapping[i] != 0)
                            sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                        else
                            sb.Append("nil,");
                    }
                    sb.AppendLine().Append("};").AppendLine();
                    maxSpellId = 1;
                    idIndexMapping = new int[100001];

                    while (int.Parse(spellTips.Id) >= currentBlock + 100000)
                    {
                        currentBlock += 100000;
                    }

                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    lastLine = string.Empty;
                    lastId = string.Empty;

                    sb.AppendLine("function loadSpellData" + currentBlock + "()");
                    sb.AppendLine("  WoWeuCN_Tooltips_SpellData_" + currentBlock + " = {");
                    currentIndex = 1;
                }

                var tempSb = new StringBuilder();
                tempSb.Append("\"");
                foreach (var spellTipLine in spellTips.TooltipLines)
                {
                    int r = (int)Math.Round(spellTipLine.R * 255);
                    int g = (int)Math.Round(spellTipLine.G * 255);
                    int b = (int)Math.Round(spellTipLine.B * 255);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        var text = spellTipLine.Line;
                        foreach (var textToSim in TextToSim)
                        {
                            text = text.Replace(textToSim.Key, textToSim.Value);
                        }

                        tempSb.Append(text).Append("£");
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
                        var text = spellTipLine.Line.Replace("|c", "|#|c").Replace("|r", "|r" + colourText)
                            .Replace("|#", "|r");

                        text = colourText + text + "|r";
                        text = text.Replace(colourText + "|r", string.Empty);

                        foreach (var textToSim in TextToSim)
                        {
                            text = text.Replace(textToSim.Key, textToSim.Value);
                        }

                        tempSb.Append(text).Append("£");
                    }
                }

                // remove empty spelltips
                if (spellTips.TooltipLines.Count < 2)
                    spellTips.TooltipLines.Clear();
                else if (spellTips.TooltipLines.Count <= 4 && BlackListedPostfix.Any(b => spellTips.TooltipLines.Last().Line.EndsWith(b)))
                    spellTips.TooltipLines.Clear();

                if (!spellTips.TooltipLines.Any())
                    continue;

                if (tempSb.ToString() == lastLine)
                {
                    sb.Append("\"¿" + lastId + "x");
                    counter++;
                }
                else
                {
                    lastLine = tempSb.ToString();
                    lastId = spellTips.Id;
                    sb.Append(tempSb);
                }


                sb.Remove(sb.Length - 1, 1);
                sb.Append("\",").Append(" --" + spellTips.Id).AppendLine();


                idIndexMapping[int.Parse(spellTips.Id) - currentBlock] = currentIndex;
                maxSpellId = int.Parse(spellTips.Id) - currentBlock;
                currentIndex++;
            }
            //foreach (var spellTips in spellTipList.OrderBy(q => int.Parse(q.Id)))
            //{
            //    sb.Append("[\"").Append(spellTips.Id).Append("\"]={");
            //    foreach (var spellTipLine in spellTips.SpellTipLines)
            //    {
            //        sb.Append("{\"").Append(spellTipLine.Line).Append("\",").Append(spellTipLine.R).Append(",")
            //            .Append(spellTipLine.G).Append(",").Append(spellTipLine.B).Append("},");
            //    }
            //    if (spellTips.SpellTipLines.Any())
            //        sb.Remove(sb.Length - 1, 1);

            //    sb.Append("},");
            //    sb.AppendLine();
            //}

            sb.Append("};").AppendLine();
            sb.AppendLine("WoWeuCN_Tooltips_SpellIndexData_" + currentBlock + " = {");
            for (int i = 1; i <= maxSpellId; ++i)
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
