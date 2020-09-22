using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestTextRetriever
{
    public class SpellReader
    {
        public SpellReader()
        {
        }

        private static string TrimTextAfter(string textContent, string separator)
        {
            var content = textContent.Split(new string[] { separator }, StringSplitOptions.None)[0];
            return textContent.Substring(content.Length + separator.Length);
        }

        public void Read(string spellTipPath, List<Tooltip> spellTipsList)
        {
            var lines = File.ReadAllLines(spellTipPath);
            foreach (var line in lines)
            {
                var spellTips = new Tooltip();
                var text = line.Trim();
                var id = text.Split(new string[] {"[\""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\"]"}, StringSplitOptions.None)[0]
                    .Trim();

                spellTips.Id = id;
                if (!text.Contains("{{"))
                    continue;
                text = text.Replace("]] \"","]]\"").Replace("]]  \"", "]]\"");
                var textContent = text.Split(new string[] {"= \""}, StringSplitOptions.None)[1]
                    .Split(new[] { "]]\"," }, StringSplitOptions.None)[0]
                    .Trim() + "]]";

                while (!string.IsNullOrEmpty(textContent))
                {
                    textContent = TrimTextAfter(textContent, "{{");

                    var tipLine = textContent.Split(new string[] { "}}" }, StringSplitOptions.None)[0];
                    textContent = TrimTextAfter(textContent, "[[");
                    var r = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    if (r.Length > 5)
                        r = r.Substring(0, 5);
                    textContent = TrimTextAfter(textContent, "[[");
                    var g = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    if (r.Length > 5)
                        g = g.Substring(0, 5);
                    textContent = TrimTextAfter(textContent, "[[");
                    var b = textContent.Split(new string[] { "]]" }, StringSplitOptions.None)[0];
                    if (r.Length > 5)
                        b = b.Substring(0, 5);
                    textContent = TrimTextAfter(textContent, "]]");
                    var spellTipLine = new TooltipLine();
                    spellTipLine.Line = tipLine;

                    spellTipLine.R = Math.Round(double.Parse(r), 2);
                    spellTipLine.G = Math.Round(double.Parse(g), 2);
                    spellTipLine.B = Math.Round(double.Parse(b), 2);
                    spellTips.TooltipLines.Add(spellTipLine);
                }

                spellTipsList.Add(spellTips);
            }
        }

        public void Write(string outputPath)
        {
            var spellTipList = new List<Tooltip>();
            Read(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\ITEMdata.txt", spellTipList);

            var sb = new StringBuilder();
            var spellTipOrderedList = spellTipList.OrderBy(q => int.Parse(q.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            foreach (var spellTips in spellTipOrderedList)
            {
                if (int.Parse(spellTips.Id) >= currentBlock + 50000)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();
                    currentBlock += 50000;
                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function loadSpellData" + currentBlock + "()");
                    sb.AppendLine("WoWeuCN_Tooltips_SpellData_" + currentBlock + " = {");
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

            sb.Append("};");
            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}
