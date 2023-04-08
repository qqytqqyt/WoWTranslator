using System;
using System.CodeDom;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using System.Web;
using HtmlAgilityPack;
using TextContentToolkit.Crawlers;
using TextContentToolkit.Extensions;
using TextContentToolkit.Models;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    public class ScriptReader
    {
        public static List<string> Removed_Text = new List<string> { "Druid", "Hunter", "Mage", "Paladin", "Priest", "Rogue", "Shaman", "Warlock", "Warrior", "Blood Elf", "Draenei", "Gnome", "Dwarf", "Night Elf", "Orc", "Undead", "Tauren", "Troll", "Death Knight" };

        public static long GetHash(string text)
        {
            text = text.Replace(" ", "");
            long counter = 1;
            var pomoc = 0;
            var length = text.Length;
            for (int i = 0; i < length; i += 3)
            {
                counter = (counter * 8161) % 4294967279; //2 ^ 32 - 17: Prime!
                pomoc = (text[i]) * 16776193;
                counter = counter + pomoc;
                pomoc = (i + 1 < length ? text[i + 1] : (length - (i + 1) + 256)) * 8372226;
                counter = counter + pomoc;
                pomoc = (i + 2 < length ? text[i + 2] : (length - (i + 1) + 256)) * 3932164;
                counter = counter + pomoc;
            }

            return counter % 4294967291; // 2 ^ 32 - 5: Prime(and different from the prime in the loop)
        }
        
        public void Execute(string outputPath)
        {
            var content = File.ReadAllText(
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\scripts\dbscripts_wlk.xml");
            var scriptList = content.FromXml<List<Script>>();
            var scriptObjects = new List<ScriptObject>();
            var usedHash = new HashSet<long>();
            foreach (var script in scriptList)
            {
                script.NameEN = HtmlEntity.DeEntitize(script.NameEN);
                script.NameCN = HtmlEntity.DeEntitize(script.NameCN);
                for (int i = 0; i < script.ScriptListEN.Count; ++i)
                {
                    script.ScriptListEN[i] = HtmlEntity.DeEntitize(script.ScriptListEN[i]);
                    script.ScriptListCN[i] = HtmlEntity.DeEntitize(script.ScriptListCN[i]);
                    var originalText = script.ScriptListEN[i].Replace(@"<name>", string.Empty).Replace(@"<NAME>", string.Empty).
                        Replace(@"<race>", string.Empty).Replace(@"<RACE>", string.Empty).Replace(@"<class>", string.Empty).Replace(@"<CLASS>", string.Empty);

                    originalText = originalText.Replace("[Common] ", string.Empty).Replace("[Orcish] ", string.Empty).Replace("[Dwarvish] ", string.Empty).Replace("[Draenei] ", string.Empty)
                        .Replace("[Gutterspeak] ", string.Empty).Replace("[Kalimag] ", string.Empty).Replace("[Demonic] ", string.Empty)
                        .Replace("[Troll] ", string.Empty).Replace("[Taurahe] ", string.Empty).Replace("[Darnassian] ", string.Empty).Replace("[Thalassian] ", string.Empty)
                        .Replace("[Furbolg] ", string.Empty).Replace("[Draconic] ", string.Empty);

                    foreach (var replaceText in Removed_Text)
                    {
                        originalText = originalText.Replace(replaceText, string.Empty);
                        originalText = originalText.Replace(replaceText.ToLower(), string.Empty);
                        originalText = originalText.Replace(replaceText.ToUpper(), string.Empty);
                    }

                    var originalIndex = originalText.IndexOf(":", StringComparison.Ordinal);
                    if (originalIndex == -1)
                    {
                        if (originalText.Contains(script.NameEN))
                        {
                            originalText = originalText.Substring(script.NameEN.Length);
                            originalText = "%s" + originalText;
                        }
                    }
                    else
                    {
                        originalText = originalText.Substring(originalIndex + 1);
                    }

                    var text = script.ScriptListCN[i].Replace(@"<名字>", "{name}").Replace(@"<NAME>", "{NAME}").
                        Replace(@"<种族>", "{race}").Replace(@"<RACE>", "{race}").Replace(@"<职业>", "{class}").Replace(@"<CLASS>", "{class}");

                    text = text.Replace("[通用语] ", string.Empty).Replace("[兽人语] ", string.Empty).Replace("[矮人语] ", string.Empty).Replace("[德莱尼语] ", string.Empty)
                        .Replace("[亡灵语] ", string.Empty).Replace("[卡利姆多语] ", string.Empty).Replace("[恶魔语] ", string.Empty)
                        .Replace("[巨魔语] ", string.Empty).Replace("[牛头人语] ", string.Empty).Replace("[达纳苏斯语] ", string.Empty).Replace("[萨拉斯语] ", string.Empty)
                        .Replace("[熊怪语] ", string.Empty).Replace("[龙语] ", string.Empty);

                    text = text.Replace(@"&middot;", "·");
                    script.NameCN = script.NameCN.Replace(@"&middot;", "·");
                    var index = text.IndexOf("：", StringComparison.Ordinal);
                    if (index == -1)
                    {
                        if (!text.Contains(script.NameCN))
                        {
                            text = "%o" + text;
                        }
                        else
                        {
                            text = text.Substring(script.NameCN.Length);
                            text = "%s" + text;
                        }
                    }
                    else
                    {
                        text = text.Substring(index + 1);
                    }

                    if (text.Contains("带我们的客人去沙塔斯城里走走吧"))
                        Console.Write(true);

                    var regEx = new Regex("<([^\\/]?)+\\/([^\\/]?)+>");
                    var match = regEx.Match(originalText);
                    if (match.Success)
                    {
                        var originalText1 = originalText.Replace(match.Value, match.Value.FirstBetween(@"<", "/"));
                        var originalText2 = originalText.Replace(match.Value, match.Value.FirstBetween(@"/", ">"));
                        
                        var scriptObject1 = new ScriptObject();
                        var scriptObject2 = new ScriptObject();
                        scriptObject1.Hash = GetHash(originalText1);
                        scriptObject2.Hash = GetHash(originalText2);

                        var matchTranslated = regEx.Match(text);
                        var text1 = text;
                        var text2 = text;
                        if (matchTranslated.Success)
                        {
                            text1 = text.Replace(matchTranslated.Value, matchTranslated.Value.FirstBetween(@"<", "/"));
                            text2 = text.Replace(matchTranslated.Value, matchTranslated.Value.FirstBetween(@"/", ">"));
                        }
                        scriptObject1.Text = text1;
                        scriptObject2.Text = text2;
                        if (!usedHash.Contains(scriptObject1.Hash))
                            scriptObjects.Add(scriptObject1);

                        usedHash.Add(scriptObject1.Hash);

                        if (!usedHash.Contains(scriptObject2.Hash))
                            scriptObjects.Add(scriptObject2);

                        usedHash.Add(scriptObject2.Hash);
                    }
                    else
                    {
                        var matchTranslated = regEx.Match(text);
                        if (matchTranslated.Success)
                        {
                            text = text.Replace(matchTranslated.Value, "YOUR_GENDER(" + matchTranslated.Value.FirstBetween(@"<", "/") + ";" + matchTranslated.Value.FirstBetween(@"/", ">") + ")");
                        }

                        var hash = GetHash(originalText);
                        var scriptObject = new ScriptObject();
                        scriptObject.Hash = hash;
                        scriptObject.Text = text;
                        if (usedHash.Contains(scriptObject.Hash))
                            continue;

                        scriptObjects.Add(scriptObject);
                        usedHash.Add(hash);
                    }

                }
            }

            var simpleScripts = ScriptCrawler.ExecuteSql();
            foreach (var simpleScript in simpleScripts)
            {
                var originalText = simpleScript.TextEN;
                var hash = GetHash(originalText);

                if (usedHash.Contains(hash))
                    continue;

                var scriptObject = new ScriptObject();
                scriptObject.Hash = hash;
                scriptObject.Text = simpleScript.TextCN;
                scriptObjects.Add(scriptObject);
            }


            scriptObjects = scriptObjects.OrderBy(s => s.Hash).ToList();
            var sb = new StringBuilder();
            sb.AppendLine("WoWeuCN_Quests_ScriptData = {");
            foreach (var scriptObject in scriptObjects)
            {
                sb.Append(@"[" + scriptObject.Hash + "] = \"").Append(scriptObject.Text).AppendLine("\",");
            }

            sb.AppendLine("}");

            File.WriteAllText(outputPath, sb.ToString());
        }
    }
}
