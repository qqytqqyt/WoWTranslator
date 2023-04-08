using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;

namespace TextContentToolkit.Crawlers
{
    public class JournalCrawler
    {
        public void Execute()
        {
            var sb = new StringBuilder();
            for (int i = 1; i < 2000; ++i)
            using (var webClient = new WebClient())
            {
                Thread.Sleep(10);
                Console.Write("Processing " + i);
                sb.Append("Processing " + i);
                try
                {
                        //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
                        //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
                    webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/journal-encounter/{i}?namespace=static-us&locale=zh_TW&access_token=USEDHB4psKGpMzcQUzxWyS6krBnw8U33oE",
                        @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\TBCTW\" + i + ".json");
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
                        try
                        {
                            //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
                            //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
                            webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/journal-encounter/{i}?namespace=static-us&locale=ZH_cn&access_token=USEDHB4psKGpMzcQUzxWyS6krBnw8U33oE",
                                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\TBCTW\" + i + ".json");
                        }
                        catch (Exception e2)
                        {
                            if (e2.Message.Contains("404"))
                            {
                                Console.Write(" Not Found");
                                sb.Append(" Not Found");
                            }
                            else
                            {
                                throw;
                            }
                        }
                        }
                }

                sb.AppendLine();
                Console.WriteLine();
            }

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Journals\TBC\summary.txt", sb.ToString());
        }
    }
}
