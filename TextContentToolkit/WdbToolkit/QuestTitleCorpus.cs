using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

namespace WdbToolkit
{
    /// <summary>
    /// Loads quest id -> expected title maps from the Lua files produced by the
    /// in-game scanner addon (WoWeuCN_Scanner_QuestToolTips entries of the form
    /// ["12345"] = "{{title}}...{{objectives}}...").
    /// </summary>
    public static class QuestTitleCorpus
    {
        private static readonly Regex EntryPattern = new Regex(
            "^\\s*\\[\"(?<id>\\d+)\"\\]\\s*=\\s*\"\\{\\{(?<title>.*?)\\}\\}",
            RegexOptions.Compiled);

        public static Dictionary<int, string> LoadFromScannerLua(string filePath)
        {
            return LoadFromScannerLua(File.ReadLines(filePath));
        }

        public static Dictionary<int, string> LoadFromScannerLua(IEnumerable<string> lines)
        {
            var result = new Dictionary<int, string>();
            foreach (var line in lines)
            {
                var match = EntryPattern.Match(line);
                if (!match.Success)
                    continue;

                int id;
                if (!int.TryParse(match.Groups["id"].Value, out id))
                    continue;

                var title = match.Groups["title"].Value.Replace("\\\"", "\"");
                if (title.Length > 0)
                    result[id] = title;
            }

            return result;
        }
    }
}
