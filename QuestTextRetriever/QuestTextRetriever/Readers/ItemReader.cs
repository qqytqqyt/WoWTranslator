﻿using System;
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
    public class ItemReader
    {
        public ItemReader()
        {
        }

        private static readonly List<string> BlackListedText = new List<string>
        {
            "你尚未收藏过此外观",
        };

        public void Read(string tooltipPath, List<Tooltip> itemTipsList, HashSet<string> usedIds)
        {
            var lines = File.ReadAllLines(tooltipPath);
            var usedId = new HashSet<string>();
            foreach (var line in lines)
            {
                var itemTips = new Tooltip();
                var text = line.Trim();
                if (string.IsNullOrEmpty(text))
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


                if (usedIds.Contains(id))
                {
                    var otherObjective = itemTipsList.FirstOrDefault(o => o.Id == id);

                    if (otherObjective == null)
                        itemTipsList.Add(itemTips);
                    //else if (otherObjective.TooltipLines.Count > itemTips.TooltipLines.Count && itemTips.TooltipLines.Count == 2 && itemTips.TooltipLines[1].Line == @" ")
                    //{
                    //    Console.Write(true);
                    //}
                    else
                    {
                        itemTipsList.Remove(otherObjective);
                        itemTipsList.Add(itemTips);
                    }
                }
                else
                {
                    usedIds.Add(id);
                    itemTipsList.Add(itemTips);
                }
            }
        }

        public void Write(string outputPath)
        {
            var itemTipList = new List<Tooltip>();
            var usedIds = new HashSet<string>();
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\ptr-item0-200000.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\beta-item0-200000.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\retail_items.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\classic_items.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\ptr_items.36216.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\beta_items.36512.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\beta_items.36532.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\beta_items.36710.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\retail_items_36753.lua", itemTipList, usedIds);
            //Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\ptr_items.37844.lua", itemTipList, usedIds);
            // Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\bc_items.lua", itemTipList, usedIds);
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\tbc_items_38225.lua", itemTipList, usedIds);
            var sb = new StringBuilder();
            var itemTipOrderedList = itemTipList.OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            foreach (var itemTips in itemTipOrderedList)
            {
                if (int.Parse(itemTips.Id) >= currentBlock + 100000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();
                    currentBlock += 100000;
                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadItemData" + currentBlock + "()");
                    sb.AppendLine("WoWeuCN_Tooltips_ItemData_" + currentBlock + " = {");
                }

                sb.Append("[\"").Append(itemTips.Id).Append("\"]={");
                foreach (var itemTipLine in itemTips.TooltipLines)
                {
                    int r = (int)(itemTipLine.R * 255);
                    int g = (int)(itemTipLine.G * 255);
                    int b = (int)(itemTipLine.B * 255);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        sb.Append("\"").Append(itemTipLine.Line).Append("\",");
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
                        sb.Append("\"").Append(text).Append("\",");
                    }
                }

                if (itemTips.TooltipLines.Any())
                    sb.Remove(sb.Length - 1, 1);

                sb.Append("},");
                sb.AppendLine();

                currentIndex++;
            }
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

            sb.Append("};").AppendLine();
            sb.Append("end");
            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}