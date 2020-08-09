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
            var retriever = new Retriever(@"D:\qqytqqyt\Documents\OwnProjects\Translator\686500-Wow-ChineseDB-master\Wow-ChineseDB\quest_template.sql", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            retriever.Execute(@"D:\qqytqqyt\Documents\OwnProjects\Translator\output.txt");

            var htmlRetriever = new HtmlRetriever(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\", @"D:\qqytqqyt\Documents\OwnProjects\Translator\template.txt");
            htmlRetriever.ExecuteJson(@"D:\qqytqqyt\Documents\OwnProjects\Translator\outputretail.txt");
        }
    }
}
