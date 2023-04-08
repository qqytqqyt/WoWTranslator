using System;
using System.IO;
using System.Net;
using System.Text;
using System.Threading;

namespace TextContentToolkit.Crawlers
{
    public class QuestCrawler
    {
        public void Execute()
        {
            var sb = new StringBuilder();
            for (int i = 28700; i < 70000; ++i)
            using (var webClient = new WebClient())
            {
                Thread.Sleep(10);
                Console.Write("Processing " + i);
                sb.Append("Processing " + i);
                try
                {
                    //webClient.DownloadFile(@"https://cn.wowhead.com/quest=" + i,
                    //    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WowHead\" + i + ".html");
                    webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/quest/{i}?namespace=static-9.0.5_37760-us&locale=zh_CN&access_token=USOpSsPh3W0A0kpXq4HraBr6bPc1GKZiYe",
                        @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWHead37844\" + i + ".json");
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
                            webClient.DownloadFile($@"https://us.api.blizzard.com/data/wow/quest/{i}?namespace=static-9.0.5_37760-us&locale=zh_CN&access_token=USOpSsPh3W0A0kpXq4HraBr6bPc1GKZiYe",
                                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWHead37844\" + i + ".json");
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

            File.WriteAllText(@"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWHead37844\summary.txt", sb.ToString());
        }
    }
}
