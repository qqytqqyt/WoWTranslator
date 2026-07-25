using System;
using System.Collections.Generic;
using System.IO;
using TextContentToolkit.Models;

namespace TextContentToolkit.Pipeline
{
    /// <summary>
    /// Legacy Questie locale generation: every *.lua file in the folder is treated as
    /// "&lt;locale&gt;.&lt;kind&gt;.lua" scanner data and converted into
    /// &lt;folder&gt;/output/&lt;same name&gt; in Questie l10n format. The file kind is taken
    /// from the name: quest/item/unit (npc).
    /// </summary>
    internal static class QuestieRunner
    {
        public static void Run(string questieDir)
        {
            if (!Directory.Exists(questieDir))
            {
                Console.WriteLine("Questie folder not found: " + questieDir);
                return;
            }

            Directory.CreateDirectory(Path.Combine(questieDir, "output"));

            foreach (var fileInfo in new DirectoryInfo(questieDir).GetFiles("*.lua"))
            {
                var outputPath = Path.Combine(questieDir, "output", fileInfo.Name);
                var locale = fileInfo.Name.Split('.')[0];
                var lowerName = fileInfo.Name.ToLowerInvariant();

                Console.WriteLine("[questie] " + fileInfo.Name + " (locale " + locale + ")");

                if (lowerName.Contains("item"))
                {
                    var reader = new ItemReader();
                    var tips = new Dictionary<string, Tooltip>();
                    reader.ReadForQuestie(fileInfo.FullName, tips);
                    reader.WriteToQuestie(outputPath, locale, tips);
                }
                else if (lowerName.Contains("unit") || lowerName.Contains("npc"))
                {
                    var reader = new UnitReader();
                    var tips = new Dictionary<string, Tooltip>();
                    reader.ReadForQuestie(fileInfo.FullName, tips);
                    reader.WriteToQuestie(outputPath, locale, tips);
                }
                else
                {
                    var reader = new QuestReader();
                    var quests = reader.ComposeFromObjectives(fileInfo.FullName);
                    reader.WriteToQuestie(outputPath, locale, quests);
                }
            }
        }
    }
}
