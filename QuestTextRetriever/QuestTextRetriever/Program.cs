using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestTextRetriever
{
    class Program
    {
        static void Main(string[] args)
        {
            //var crawler = new Crawler();
            //crawler.Execute();
            //var itemReader = new ItemReader();
            //itemReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\retail_9.0_items_output.txt");


            //var spellReader = new SpellReader();
            //spellReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\retail_9.0_spells_output.txt");

            //var retriever = new Retriever(@"D:\qqytqqyt\Documents\OwnProjects\Translator\686500-Wow-ChineseDB-master\Wow-ChineseDB\quest_template.sql", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            //retriever.Execute(@"D:\qqytqqyt\Documents\OwnProjects\Translator\output.txt");

            var questReader = new QuestReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadSL\", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            questReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\outputretail9.0.txt");
        }
    }
}
