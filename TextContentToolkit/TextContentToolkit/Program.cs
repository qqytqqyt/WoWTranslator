using System.IO;
using TextContentToolkit.Configs;
using TextContentToolkit.Extensions;

namespace TextContentToolkit
{
    class Program
    {
        static void Main(string[] _)
        {
            var text = File.ReadAllText(@".\Config.xml");
            var config = text.FromXml<RetrieverConfig>();

            //var globalStringReader = new GlobalStringReader();
            //globalStringReader.Execute2();

            //var hash = ScriptReader.GetHash("We're under attack! Avast, ye swabs! Repel the invaders!");

            #region Crawlers
            //var journalCrawler = new JournalCrawler();
            //journalCrawler.Execute();
            //var scriptCrawlerWowDB = new ScriptCrawler();
            //scriptCrawlerWowDB.ExecuteWowDB();
            //var scriptCrawlerSql = new ScriptCrawler();
            //scriptCrawlerSql.ExecuteSql();
            //var questCrawler = new QuestCrawler();
            //questCrawler.Execute();
            #endregion

            if (config.RunReaders)
            {
                var itemReader = new ItemReader(config.ItemConfig);
                itemReader.Execute();
                var achievementReader = new AchievementReader(config.AchievementConfig);
                achievementReader.Execute();
                var spellReader = new SpellReader(config.SpellConfig);
                spellReader.Execute();
                var unitReader = new UnitReader(config.UnitConfig);
                unitReader.Execute();

                var questReader = new QuestReader(config.QuestConfig);
                questReader.Execute();
            }

            if (config.RunQuestieFolders)
            {
                var questieItemReader = new ItemReader(config.ItemConfig);
                questieItemReader.ExecuteOnQuestieFolder();
                var questieUnitReader = new UnitReader(config.UnitConfig);
                questieUnitReader.ExecuteOnQuestieFolder();
                var questieQuestReader = new QuestReader(config.QuestConfig);
                questieQuestReader.ExecuteOnQuestieFolder();
            }
        }
    }
}
