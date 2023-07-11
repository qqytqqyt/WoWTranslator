using System.IO;
using TextContentToolkit.Configs;
using TextContentToolkit.Extensions;

namespace TextContentToolkit
{
    internal class Program
    {
        private static void Main(string[] _)
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
                if (config.ItemConfig.Enabled)
                    itemReader.Execute();

                var achievementReader = new AchievementReader(config.AchievementConfig);
                if (config.AchievementConfig.Enabled)
                    achievementReader.Execute();

                var spellReader = new SpellReader(config.SpellConfig);
                if (config.SpellConfig.Enabled)
                    spellReader.Execute();

                var unitReader = new UnitReader(config.UnitConfig);
                if (config.UnitConfig.Enabled)
                    unitReader.Execute();

                var questReader = new QuestReader(config.QuestConfig);
                if (config.QuestConfig.Enabled)
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