using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using QuestTextRetriever.Models;
using QuestTextRetriever.Utils;

namespace QuestTextRetriever
{
    public class SpellReader
    {
        public SpellReader()
        {
        }

        private readonly static List<string> BlackListedPostfix = new List<string>()
        {
            "瞬发",
            "冷却时间",
            "施法时间",
            "需引导",
            "被动"
        };

        public void Read(string spellTipPath, List<Tooltip> spellTipsList, HashSet<string> usedIds)
        {
            var lines = File.ReadAllLines(spellTipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var spellTips = new Tooltip();
                var text = line.Trim();
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

                    // red
                    if (r == "0.99999779462814" && g == "0.12548992037773" && b == "0.12548992037773")
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

                if (usedIds.Contains(id))
                {
                    var otherObjective = spellTipsList.FirstOrDefault(o => o.Id == id);

                    if (otherObjective == null)
                        spellTipsList.Add(spellTips);
                    else
                    {
                        spellTipsList.Remove(otherObjective);
                        spellTipsList.Add(spellTips);
                    }
                }
                else
                {
                    usedIds.Add(id);
                    spellTipsList.Add(spellTips);
                }
            }
        }

        public void Write(string outputPath)
        {
            var spellTipList = new List<Tooltip>();
            var usedIds = new HashSet<string>();
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spell0-400000.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\retail_spells.lua", spellTipList, usedIds
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\classic_spells.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\ptr_spells.36216.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\beta_spells_36512.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\beta_spells_36532.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\beta_spells_36710.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\retail_spells_36753.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\ptr_spells.37844.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\ptr_spells_39185_1-168601.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\ptr_spells_39170_250000.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\units\bc_units.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\tbc_spells_38225.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\tbc_spells_38537.lua", spellTipList, usedIds);
            var sb = new StringBuilder();
            var spellTipOrderedList = spellTipList.OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxSpellId = 1;
            var idIndexMapping = new int[100001];
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

                    currentBlock += 100000;
                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadSpellData" + currentBlock + "()");
                    sb.AppendLine("  WoWeuCN_Tooltips_SpellData_" + currentBlock + " = {");
                    currentIndex = 1;
                }

                var tempSb = new StringBuilder();
                tempSb.Append("\"");
                foreach (var spellTipLine in spellTips.TooltipLines)
                {
                    int r = (int)(spellTipLine.R * 255);
                    int g = (int)(spellTipLine.G * 255);
                    int b = (int)(spellTipLine.B * 255);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        tempSb.Append(spellTipLine.Line).Append("£");
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

                sb.Append(tempSb);
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
