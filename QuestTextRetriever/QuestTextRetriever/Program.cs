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
            var itemReader = new ItemReader();
            itemReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\items\classic_items_output.txt");


            //var spellReader = new SpellReader();
            //spellReader.Write(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\spells\classic_spells_output.txt");

            //var retriever = new Retriever(@"D:\qqytqqyt\Documents\OwnProjects\Translator\686500-Wow-ChineseDB-master\Wow-ChineseDB\quest_template.sql", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            //retriever.Execute(@"D:\qqytqqyt\Documents\OwnProjects\Translator\output.txt");

            //var questReader = new QuestReader(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\", @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\template.txt");
            //questReader.ExecuteJson(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\outputbeta.txt");
        }
    }
}
