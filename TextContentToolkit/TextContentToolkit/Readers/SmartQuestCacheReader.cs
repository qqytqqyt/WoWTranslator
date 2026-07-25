using System;
using System.Collections.Generic;
using System.Linq;
using TextContentToolkit.Models;
using WdbToolkit;

namespace TextContentToolkit.Readers
{
    /// <summary>
    /// Reads quest cache (questcache.wdb) files of any client build - retail or classic -
    /// via the self-calibrating WdbToolkit library. The known titles (previous output plus
    /// scanner objectives) are passed as a corpus, anchoring calibration and validating results.
    /// </summary>
    public static class SmartQuestCacheReader
    {
        public static void ReadQuestCache(string fileName, List<Quest> questObjects, IReadOnlyDictionary<int, string> expectedTitles)
        {
            var options = new QuestCacheParseOptions { ExpectedTitles = expectedTitles };
            var result = QuestCacheParser.ParseFile(fileName, options);

            Console.WriteLine(result.BuildSummary());
            foreach (var failure in result.Failures.Take(20))
                Console.WriteLine("  unparsed quest " + failure.Id + ": " + failure.Reason);

            foreach (var record in result.Quests)
            {
                if (record.LogTitle.Length == 0)
                    continue;

                var quest = new Quest();
                quest.Id = record.Id.ToString();
                quest.Title = record.LogTitle.Replace("\"", "\\\"");
                quest.Objectives = record.LogDescription.Replace("\"", "\\\"");
                quest.Description = ReplaceGender(record.QuestDescription.Replace("\"", "\\\""));

                var existing = questObjects.FirstOrDefault(o => o.Id == quest.Id);
                if (existing != null)
                {
                    if (quest.Description.Length == 0 && existing.Description.Length > 0)
                        quest.Description = existing.Description;
                    if (quest.Objectives.Length == 0 && existing.Objectives.Length > 0)
                        quest.Objectives = existing.Objectives;

                    questObjects.Remove(existing);
                }

                questObjects.Add(quest);
            }
        }

        private static string ReplaceGender(string text)
        {
            foreach (var genderText in new[] { "$g", "$G" })
            {
                while (true)
                {
                    var index = text.IndexOf(genderText, StringComparison.Ordinal);
                    if (index < 0)
                        break;

                    var tempText = text.Substring(index + genderText.Length);
                    var separatorIndex = tempText.IndexOf(":", StringComparison.Ordinal);
                    if (separatorIndex < 0)
                        break;

                    var firstText = tempText.Substring(0, separatorIndex);
                    tempText = tempText.Substring(separatorIndex + 1);
                    var endIndex = tempText.IndexOf(";", StringComparison.Ordinal);
                    if (endIndex < 0)
                        break;

                    var secondText = tempText.Substring(0, endIndex);
                    var newText = "YOUR_GENDER(" + firstText + ";" + secondText + ")";
                    var oldText = genderText + firstText + ":" + secondText + ";";
                    text = text.Replace(oldText, newText);
                }
            }

            return text;
        }
    }
}
