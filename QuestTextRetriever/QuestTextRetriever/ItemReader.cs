using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

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

        private static string TrimTextAfter(string textContent, string separator)
        {
            var content = textContent.Split(new string[] { separator }, StringSplitOptions.None)[0];
            return textContent.Substring(content.Length + separator.Length);
        }

        private static string FirstBetween(string textContent, string start, string end)
        {
            if (!textContent.Contains(start))
                return string.Empty;

            return textContent.Split(new string[] { start }, StringSplitOptions.None)[1].Split(new string[] { end }, StringSplitOptions.None)[0];
        }

        public void Read(string tooltipPath, List<Tooltip> spellTipsList)
        {
            var lines = File.ReadAllLines(tooltipPath);
            foreach (var line in lines)
            {
                var spellTips = new Tooltip();
                var text = line.Trim();
                var id = text.Split(new string[] {"[\""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\"]"}, StringSplitOptions.None)[0]
                    .Trim();

                var type = FirstBetween(text, "{{{", "}}}");

                spellTips.Id = id;
                spellTips.Type = type;
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
                    textContent = TrimTextAfter(textContent, "{{");

                    var tipLine = textContent.Split(new string[] { "}}" }, StringSplitOptions.None)[0];
                    textContent = TrimTextAfter(textContent, "[[");
                    var r = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    textContent = TrimTextAfter(textContent, "[[");
                    var g = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    textContent = TrimTextAfter(textContent, "[[");
                    var b = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    textContent = TrimTextAfter(textContent, "]]");

                    var spellTipLine = new TooltipLine();

                    spellTipLine.Line = tipLine;
                    spellTipLine.R = Math.Round(double.Parse(r), 2);
                    spellTipLine.G = Math.Round(double.Parse(g), 2);
                    spellTipLine.B = Math.Round(double.Parse(b), 2);
                    var gearApproved = true;
                    if (spellTips.Type == "4" || spellTips.Type == "2")
                    {
                        gearApproved = false;
                        // name
                        if (currentIndex == 1)
                            gearApproved = true;

                        // usage description
                        if (spellTipLine.Line.StartsWith(@"装备：") || spellTipLine.Line.StartsWith(@"使用："))
                            gearApproved = true;

                        // yellow description
                        //if (r == "0.99999779462814" && g == "0.82352757453918" && b == "0")
                        if (spellTipLine.Line.StartsWith("\\\""))
                            gearApproved = true;
                    }

                    if (!gearApproved)
                        continue;

                    // blacklisted
                    if (BlackListedText.Contains(spellTipLine.Line))
                        continue;

                    // red
                    if (r == "0.99999779462814" && g == "0.12548992037773" && b == "0.12548992037773")
                        continue;

                    spellTips.TooltipLines.Add(spellTipLine);
                }

                spellTipsList.Add(spellTips);
            }
        }

        public void Write(string outputPath)
        {
            var spellTipList = new List<Tooltip>();
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\item0-100000.lua", spellTipList);

            var sb = new StringBuilder();
            var spellTipOrderedList = spellTipList.OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            foreach (var spellTips in spellTipOrderedList)
            {
                if (int.Parse(spellTips.Id) >= currentBlock + 100000)
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

                sb.Append("[\"").Append(spellTips.Id).Append("\"]={");
                foreach (var spellTipLine in spellTips.TooltipLines)
                {
                    int r = (int)(spellTipLine.R * 255);
                    int g = (int)(spellTipLine.G * 255);
                    int b = (int)(spellTipLine.B * 255);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        sb.Append("\"").Append(spellTipLine.Line).Append("\",");
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
                        sb.Append("\"").Append(text).Append("\",");
                    }
                }

                if (spellTips.TooltipLines.Any())
                    sb.Remove(sb.Length - 1, 1);

                sb.Append("},");
                sb.AppendLine();

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
            sb.Append("end");
            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}
