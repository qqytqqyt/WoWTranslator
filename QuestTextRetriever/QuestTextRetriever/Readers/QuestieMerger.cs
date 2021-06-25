using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using QuestTextRetriever.Utils;

namespace QuestTextRetriever.Readers
{
    public class QuestieMerger
    {
        public void Execute()
        {
            var oldLines =
                File.ReadAllLines(
                    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\Questie\Localization\lookups\TBC\lookupQuests\zhCN.lua");
            var newLines =
                File.ReadAllLines(
                    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\questie\TBC\lookupQuests\zhCN.lua");

            var sb = new StringBuilder();
            var items = new SortedDictionary<string, string>();
            var items2 = new SortedDictionary<string, string>();
            foreach (var oldLine in oldLines)
            {
                if (oldLine.Length < 4)
                    sb.AppendLine(oldLine);

                var id = oldLine.FirstBetween("[", "]");
                if (string.IsNullOrEmpty(id) || !int.TryParse(id, out int _))
                    continue;

                items[id] = oldLine;
            }

            foreach (var newLine in newLines)
            {
                if (newLine.Length < 4)
                    sb.AppendLine(newLine);

                var id = newLine.FirstBetween("[", "]");
                if (string.IsNullOrEmpty(id) || !int.TryParse(id, out int _))
                    continue;

                items[id] = newLine;
            }

            foreach (var item in items)
            {
                var text = item.Value;
                if (text.Contains(", nil,") || text.Contains(",nil,"))
                {
                    items2[item.Key] = text;
                    continue;
                }

                var removedText = text.FirstBetween(@", {", "},");
                text = text.Replace("{" + removedText, "nil");
                text = text.Replace("nil}, ", "nil, ");
                items2[item.Key] = text;
            }

            foreach (var item in items2.OrderBy(t => int.Parse(t.Key)))
            {
                sb.AppendLine(item.Value);
            }

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\questie\TBC\lookupQuests\outputn.lua", sb.ToString());
        }
    }
}
