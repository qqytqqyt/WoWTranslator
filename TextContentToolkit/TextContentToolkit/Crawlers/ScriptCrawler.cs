using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Web.Hosting;
using HtmlAgilityPack;
using TextContentToolkit.Extensions;
using TextContentToolkit.Models;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Crawlers
{
    public class ScriptCrawler
    {
        public static List<SimpleScriptObject> ExecuteSql()
        {
            var scripts = new List<SimpleScriptObject>();
            {
                var lines = File.ReadAllLines(
                    @"G:\OneDrive\OwnProjects\WoWTranslator\Data\scripts\scriptdev2_script_full.sql");
                foreach (var line in lines.Where(l => l.StartsWith(@"(-")))
                {
                    var text = line.Replace("\\'", "$$");
                    var script = new SimpleScriptObject();
                    var chat = text.FirstBetween(@"'", @"'");
                    if (string.IsNullOrEmpty(chat))
                        continue;

                    chat = chat.Replace(@"$n", string.Empty).Replace(@"$N", string.Empty).Replace(@"$c", string.Empty)
                        .Replace(@"$C", string.Empty).Replace(@"$R", string.Empty).Replace(@"$r", string.Empty).Replace("$$", "'");
                    var id = text.FirstBetween("(", ",");
                    if (text.Contains(@"EMOTE") && !chat.StartsWith("%s"))
                        script.UseEmote = true;
                    script.TextEN = chat;
                    script.ScriptId = id;
                    scripts.Add(script);
                }
            }

            {
                var lines = File.ReadAllLines(
                    @"G:\OneDrive\OwnProjects\WoWTranslator\Data\scripts\Chinese_Script_Texts.sql");
                foreach (var line in lines.Where(l => l.StartsWith(@"UPDATE `script_texts`")))
                {
                    var text = line.Replace("\\'", "$$");
                    var chat = text.FirstBetween(@"`content_loc4`='", @"'");
                    if (string.IsNullOrEmpty(chat))
                        continue;

                    chat = chat.Replace(@"$n", "{name}").Replace(@"$N", "{name}").Replace(@"$c", "{class}")
                        .Replace(@"$C", "{CLASS}").Replace(@"$R", "{RACE}").Replace(@"$r", "{race}").Replace("$$", "'");

                    var id = text.FirstBetween("`entry`=", ";");
                    var script = scripts.FirstOrDefault(s => s.ScriptId == id);
                    if (script == null)
                        continue;

                    if (script.UseEmote)
                        chat = "%o" + chat;

                    script.TextCN = chat;
                }
            }

            scripts.RemoveAll(s => string.IsNullOrEmpty(s.TextCN));
            return scripts;
        }

        public void ExecuteWowDB()
        {
            var scripts = new List<Script>();
            bool retry = true;
            using (var webClient = new WebClient() { Encoding = System.Text.Encoding.UTF8 })
            {
                for (int id = 13300; id < 42000; id++)
                {
                    Console.WriteLine("Attempt: " + id);
                    var script = new Script();
                    try
                    {
                        {
                            var text = webClient.DownloadString(@"https://80.wowfan.net/en/?npc=" + id);
                            HtmlDocument document = new HtmlDocument();
                            document.LoadHtml(text);
                            var documentNode = document.DocumentNode;
                            var headerNode = documentNode.Descendants("h1").FirstOrDefault();
                            if (headerNode == null)
                                continue;

                            var titleNode = documentNode.Descendants("div")
                                .FirstOrDefault(n =>
                                    n.HasAttributes && n.Attributes["id"] != null &&
                                    n.Attributes["id"].Value == "quotes-generic");

                            if (titleNode == null)
                                continue;

                            script.NpcId = id.ToString();
                            script.NameEN = headerNode.InnerText;
                            foreach (var div in titleNode.Descendants("div"))
                            {
                                script.ScriptListEN.Add(div.InnerText);
                            }
                        }


                        {
                            var text = webClient.DownloadString(@"https://80.wowfan.net/?npc=" + id);
                            HtmlDocument document = new HtmlDocument();
                            document.LoadHtml(text);
                            var documentNode = document.DocumentNode;
                            var headerNode = documentNode.Descendants("h1").FirstOrDefault();
                            if (headerNode == null)
                                continue;

                            var titleNode = documentNode.Descendants("div")
                                .FirstOrDefault(n =>
                                    n.HasAttributes && n.Attributes["id"] != null &&
                                    n.Attributes["id"].Value == "quotes-generic");

                            if (titleNode == null)
                            {
                                Console.Write(true);
                                continue;
                            }

                            script.NpcId = id.ToString();
                            script.NameCN = headerNode.InnerText;
                            foreach (var div in titleNode.Descendants("div"))
                            {
                                script.ScriptListCN.Add(div.InnerText);
                            }
                        }

                        Console.WriteLine(id);
                    }
                    catch (Exception e)
                    {
                        if (e.Message.Contains("404"))
                        {
                            continue;
                        }

                        if (retry)
                        {
                            retry = false;
                            id--;
                        }
                        else
                        {
                            retry = true;
                        }

                        continue;
                    }

                    scripts.Add(script);
                }
            }

            var xmlText = scripts.ToXml();
            File.WriteAllText(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\scripts\dbscripts_wlk.xml", xmlText);
        }
    }
}
