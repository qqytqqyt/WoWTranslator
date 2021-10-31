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

namespace QuestTextRetriever
{
    class Program
    {
        static void Main(string[] args)
        {
            new QuestieMerger().Execute();

            //var hash = ScriptReader.GetHash("We're under attack! Avast, ye swabs! Repel the invaders!");
            //var journalCrawler = new JournalCrawler();
            //journalCrawler.Execute();
            //var scriptCrawler = new ScriptCrawler();
            //scriptCrawler.Execute();
            //var scriptCrawler = new ScriptCrawler();
            //scriptCrawler.ExecuteSql();
            //var scriptReader = new ScriptReader();
            //scriptReader.Excecute(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\scripts\output3.lua");
            //var crawler = new Crawler();
            //crawler.Execute();
            //var itemReader = new ItemReader();
            //itemReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\retail_items_output_40843.lua");
            var questReader = new QuestReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWHeadData\WoWHead37844\", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            questReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\outputretail9.1.5.40843.txt");
            //var unitReader = new UnitReader();
            //unitReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\units\retail_units_output_40843.lua");
            //var spellReader = new SpellReader();
            //spellReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\retail_spells_output_40843.lua");

            //var journalReader = new JournalReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\TBCTW\");
            //journalReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\outputngatw.txt");


            //var questCacheReader =
            //    new QuestCacheReader(
            //        @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            //questCacheReader.Execute(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\tbcextra38548.lua");

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





            //var retriever = new Retriever(@"D:\qqytqqyt\Documents\OwnProjects\Translator\686500-Wow-ChineseDB-master\Wow-ChineseDB\quest_template.sql", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            //retriever.Execute(@"D:\qqytqqyt\Documents\OwnProjects\Translator\output.txt");


        }
    }
}
