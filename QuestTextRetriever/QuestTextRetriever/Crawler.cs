using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Text;
using System.Threading;
using System.Threading.Tasks;

namespace QuestTextRetriever
{
    public class Crawler
    {
        public void Execute()
        {
            var sb = new StringBuilder();
            for (int i = 50573; i < 70000; ++i)
            using (var webClient = new WebClient())
            {
                Thread.Sleep(10);
                Console.Write("Processing " + i);
                sb.Append("Processing " + i);
                try
                {
                    //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
                    //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
                    webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/quest/{i}?namespace=static-9.0.2_36532-us&locale=zh_CN&access_token=USUM4sPVtdB9mOdqanKJZbBbYMUf5W47SW",
                        @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadSLbeta\" + i + ".json");
                }
                catch (Exception e)
                {
                    if (e.Message.Contains("404"))
                    {
                        Console.Write(" Not Found");
                        sb.Append(" Not Found");
                    }
                    else
                    {
                        throw;
                    }
                }

                sb.AppendLine();
                Console.WriteLine();
            }

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHeadSLbeta\summary.txt", sb.ToString());
        }
    }
}
