﻿using QuestTextRetriever.Models;
using QuestTextRetriever.Utils;
using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;

namespace QuestTextRetriever
{
    public class UnitReader
    {
        public UnitReader()
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
                var unitTips = new Tooltip();
                var text = line.Trim();
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
                    if (tipLine.StartsWith("等級") || tipLine.StartsWith("等级"))
                        break;

                    // red
                    unitTips.TooltipLines.Add(spellTipLine);
                    
                }

                if (usedIds.Contains(id))
                {
                    var otherObjective = spellTipsList.FirstOrDefault(o => o.Id == id);

                    if (otherObjective == null)
                        spellTipsList.Add(unitTips);
                    else
                    {
                        spellTipsList.Remove(otherObjective);
                        spellTipsList.Add(unitTips);
                    }
                }
                else
                {
                    usedIds.Add(id);
                    spellTipsList.Add(unitTips);
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
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\retail_spells_36753.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\ptr_spells.37844.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\units\retail_units_905.lua", spellTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\units\ptr_units_39170_100000.lua", spellTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\units\bc_units_38339_zhcn.lua", spellTipList, usedIds);
            var sb = new StringBuilder();
            var spellTipOrderedList = spellTipList.OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxUnitId = 1;
            var countA = 0;
            int countB = 0;
            var text = "";
            var idIndexMapping = new int[100001];
            foreach (var unitTips in spellTipOrderedList)
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

                    currentBlock += 100000;
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
