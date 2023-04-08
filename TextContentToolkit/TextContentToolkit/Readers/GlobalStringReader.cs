using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Runtime.InteropServices;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    public class GlobalStringReader
    {
        public static string FullText = string.Empty;
        public static string TbcText = string.Empty;

        private static string[] GetFiles(string sourceFolder, string filters, System.IO.SearchOption searchOption)
        {
            return filters.Split('|').SelectMany(filter => System.IO.Directory.GetFiles(sourceFolder, filter, searchOption)).ToArray();
        }

        public void PopulateProtectedGlobals(HashSet<string> protectedGlobals)
        {
            var dir = new DirectoryInfo(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\framexml\tbc\");
            foreach (var file in GetFiles(dir.FullName, "ChatFrame.*|PaperDollFrame.*", SearchOption.AllDirectories))
            {
                var content = File.ReadAllText(file);
                FullText += content;
                if (file.Contains("Interface_TBC"))
                    TbcText += content;
                while (content.Contains("_G[\""))
                {
                    var gIndex = content.IndexOf("_G[\"", StringComparison.Ordinal);
                    content = content.Substring(gIndex);
                    var gEndInex = content.IndexOf("]");
                    var global = content.Substring(0, gEndInex + 1);
                    content = content.Substring(gEndInex + 1);
                    if (char.IsUpper(global[5]))
                        protectedGlobals.Add(global);
                }
            }

        }

        public bool CheckExistence(string key)
        {
            // GUILD_TOTAL GUILD_TOTALONLINE SEND_MESSAGE GROUP_INVITE LFG_LIST_SPAM GUILDBANK_TAB_NUMBER
            // SPELL_STAT2_NAME
            if (Regex.Match(FullText, @"\b" + key + @"\b").Success)
            {
                return true;
            };

            //return false; //
            return FullText.Contains("= " + key);
        }


        public void Execute()
        {
            var lines = File.ReadAllLines(
                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\globalstrings\GlobalStrings (1).lua");
            var sb = new StringBuilder();
            foreach (var line in lines)
            {
                var keyIndex = line.IndexOf(" ");
                var key = line.Substring(0, keyIndex);
                var text = line.Replace(" = \"", "\"] = \"");
                

                text = "_G[\"" + text;
                text = "if _G[\"" + key + "\"] ~= nil then " + text.Substring(0, text.Length - 1) + " end;";
                sb.AppendLine(text);
            }

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\globalstrings\out.lua", sb.ToString());
        }


        public void Execute2()
        {
            var lines = File.ReadAllLines(
                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\globalstrings\globalstrings.csv");
            var protectedGlobals = new HashSet<string>();
            PopulateProtectedGlobals(protectedGlobals);
            CheckExistence("SPELL_STAT2_NAME");
            var protectedPrefix = new HashSet<string>();
            foreach (var protectedGlobal in protectedGlobals)
            {
                var index = protectedGlobal.IndexOf("..");
                if (index < 0)
                    continue;
                var content = protectedGlobal.Substring(0, index - 1).Trim();
                protectedPrefix.Add(content);
            }
            var sb = new StringBuilder();
            var indexA = 1;
            foreach (var line in lines)
            {
                var keys = line.Split(',');
                if (keys.Length!=3 || keys[2].Length != 1)
                    continue;
                var key = keys[0];
                string value = keys[1];
                value = value.Trim('\"').Replace("\"\"", "\\\"").Replace("\\\\\"", "\\\"");

                var completeKey = "_G[\"" + key + "\"]";
                if (key == "PLAYERSTAT_BASE_STATS")
                    Console.Write(true);

                //if (protectedGlobals.Contains(completeKey))
                //    continue;
                //if (protectedPrefix.Any(p => completeKey.StartsWith(p)))
                //    continue;

                //if (CheckExistence(key))
                //    continue;

                if (!protectedGlobals.Contains(completeKey) && !protectedPrefix.Any(p => completeKey.StartsWith(p)) && !CheckExistence(key))
                    continue;


                if (value.EndsWith("\\") && !value.EndsWith("\\\\"))
                    value += "\"";

                var text = "if _G[\"" + key + "\"] ~= nil then _G[\"" + key + "\"] = \"" + value + "\" end;";
                Console.WriteLine(indexA++);
                sb.AppendLine(text);
            }

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\globalstrings\out2.lua", sb.ToString());
        }
    }
}
