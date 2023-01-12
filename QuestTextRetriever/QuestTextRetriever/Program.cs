using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;
using QuestTextRetriever.Crawlers;
using QuestTextRetriever.Readers;
using QuestTextRetriever.Utils;

namespace QuestTextRetriever
{
    class Program
    {
        static void Main(string[] args)
        {
            //new QuestieMerger().Execute();
            //var globalStringReader = new GlobalStringReader();
            //globalStringReader.Execute2();

            //var hash = ScriptReader.GetHash("We're under attack! Avast, ye swabs! Repel the invaders!");
            //var journalCrawler = new JournalCrawler();
            //journalCrawler.Execute();
            //var scriptCrawler = new ScriptCrawler();
            //scriptCrawler.Execute();
            //var scriptCrawler = new ScriptCrawler();
            //scriptCrawler.ExecuteSql();

            //var crawler = new Crawler();
            //crawler.Execute();

            // retail
            //var questReader = new QuestReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWHeadData\WoWHead37844\", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            //questReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\outputretail9.2.5.43971.txt");
            //var itemReader = new ItemReader();
            //itemReader.Write(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\dragon_items_output_47213.lua");
            var achievementReader = new AchievementReader();
            achievementReader.Write(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wlk_achievements_output_47585.lua");
            ////itemReader.ExecuteOnQuestieFolder(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\items");
            ////var unitReader = new UnitReader();
            ////unitReader.ExecuteOnQuestieFolder(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\units");
            //var questReader = new QuestReader();
            //questReader.Execute(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\quests\output_47213.lua", VersionMode.Retail);
            //QuestReader.MergeOutputs(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\quests\47213merged.lua");
            //////questReader.ExecuteOnQuestieFolder(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\quests");
            ////itemReader.Write(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wlk_items_output_zhcn_45166.lua", OutputMode.WoWeuCN);
            //var unitReader = new UnitReader();
            //unitReader.Write(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\units\dragon_units_output_46144.lua", OutputMode.WoWeuCN);
            //var spellReader = new SpellReader();
            //spellReader.Write(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\dragon_spells_output_47213.lua");




            //var journalReader = new JournalReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\TBCTW\");
            //journalReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\outputngatw.txt");


            // tbc
            //var questCacheReader =
            //   new QuestCacheReader(
            //       @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            //questCacheReader.Execute(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\wlktest1.lua");

            //var questReader = new QuestReader();
            //questReader.Execute(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\quests\wlk_quests_output_questie_zhcn_45166.lua", VersionMode.Classic, OutputMode.Questie);
            //var scriptReader = new ScriptReader();
            //scriptReader.Execute(@"G:\OneDrive\OwnProjects\WoWTranslator\Data\scripts\output_wlk.lua");
            //QuestReader.MergeOutputs();

            //DirectoryInfo dir = new DirectoryInfo(@"G:\Games\World of Warcraft\_retail_\WTF\Account\411375915#1\SavedVariables");
            //foreach (var bakFile in dir.GetFiles(@"*.bak"))
            //{
            //    var fileName = Path.GetFileNameWithoutExtension(bakFile.FullName);
            //    var filePath = Path.Combine(dir.FullName, fileName);
            //    if (!File.Exists(filePath))
            //        bakFile.CopyTo(filePath);
            //}

            //dir.GetFiles("*.bak");
            //for (int i = 1; i < 999; ++i)
            //    using (var webClient = new WebClient())
            //    {
            //        Thread.Sleep(10);
            //        var num = i.ToString("D3");
            //        Console.Write("Processing " + i);

            //        try
            //        {
            //            webClient.DownloadFile(@"https://us.api.blizzard.com/data/wow/quest/2?namespace=static-9.0.5_37" + num + @"-us&locale=en_US&access_token=USOpSsPh3W0A0kpXq4HraBr6bPc1GKZiYe", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadTemp\" + i + ".json");
            //            Console.Write(true);
            //            //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
            //            //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
            //            //webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/quest/{i}?namespace=static-us&locale=zh_CN&access_token=USUKsi22RwOof8IWqTg4bU6jE2BeJzvSz7",
            //            //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadSL\" + i + ".json");
            //        }
            //        catch (Exception e)
            //        {
            //            if (e.Message.Contains("403"))
            //            {
            //                Console.Write(" Not Found");
            //            }
            //        }

            //        try
            //        {
            //            webClient.DownloadFile(@"https://us.api.blizzard.com/data/wow/quest/2?namespace=static-9.0.5_37" + num + @"-us&locale=en_US&access_token=USOpSsPh3W0A0kpXq4HraBr6bPc1GKZiYe", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadTemp\" + i + ".json");
            //            Console.Write(true);
            //            //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
            //            //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
            //            //webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/quest/{i}?namespace=static-us&locale=zh_CN&access_token=USUKsi22RwOof8IWqTg4bU6jE2BeJzvSz7",
            //            //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadSL\" + i + ".json");
            //        }
            //        catch (Exception e)
            //        {
            //            if (e.Message.Contains("403"))
            //            {
            //                Console.Write(" Not Found");
            //            }
            //        }

            //        Console.WriteLine();
            //    }


            //var lines = File.ReadAllLines(@"G:\OneDrive\OwnProjects\Leveling\Turn-in-guide.lua");
            //var questLines = File.ReadAllLines(@"G:\OneDrive\OwnProjects\Leveling\questie-db.txt");
            //var expLines = File.ReadAllLines(@"G:\OneDrive\OwnProjects\Leveling\questie-exp.txt");
            //var dictionary= new Dictionary<string, string>();
            //var dictionaryExp = new Dictionary<string, string>();
            //foreach (var questLine in questLines)
            //{
            //    var id = questLine.FirstBetween("[", "]");
            //    var name = questLine.Substring(questLine.IndexOf("= {") + 4);
            //    dictionary[id] = name;
            //}

            //foreach (var expLine in expLines)
            //{
            //    var id = expLine.FirstBetween("[", "]");
            //    var exp = expLine.FirstBetween("{", "}");
            //    dictionaryExp[id] = exp;
            //}

            //var outputLines = new List<string>();
            //foreach (var line in lines.Select(l => l.Trim()).Where(l => l.StartsWith("Accept", StringComparison.OrdinalIgnoreCase)))
            //{
            //    var name = line.Substring(7).Trim().Trim(new[] {'.'});
            //    var item = dictionary.FirstOrDefault(d => d.Value.StartsWith(name, StringComparison.OrdinalIgnoreCase));
            //    if (item.Key != null)
            //    {
            //        if (dictionaryExp.ContainsKey(item.Key))
            //        {
            //            var level = dictionaryExp[item.Key].Split(',')[0];
            //            var exp = dictionaryExp[item.Key].Split(',')[1].Trim();
            //            outputLines.Add(line + "|" + item.Key + "|" + exp + "|" + level);
            //        }
            //        else
            //        {
            //            outputLines.Add(line + "|" + item.Key + "||" );
            //        }


            //    }
            //    else
            //    {
            //        outputLines.Add(line + "|||");
            //    }
            //}

            //File.WriteAllLines(@"G:\OneDrive\OwnProjects\Leveling\turn-in-output.csv", outputLines);

            //var retriever = new Retriever(@"D:\qqytqqyt\Documents\OwnProjects\Translator\686500-Wow-ChineseDB-master\Wow-ChineseDB\quest_template.sql", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            //retriever.Execute(@"D:\qqytqqyt\Documents\OwnProjects\Translator\output.txt");


        }
    }
}
