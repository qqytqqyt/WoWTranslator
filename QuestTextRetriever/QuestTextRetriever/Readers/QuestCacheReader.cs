using System;
using System.Collections;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using QuestTextRetriever.Extensions;
using QuestTextRetriever.Models;
using QuestTextRetriever.Utils;

namespace QuestTextRetriever.Readers
{
    public class QuestCacheReader
    {
        public QuestCacheReader(string templateFilePath)
        {
            m_template = File.ReadAllText(templateFilePath);
        }

        public void Execute(string outputPath)
        {
            var questObjects = new List<Quest>();
            var index = 0;
            try
            {
                using (var ms = new MemoryStream(File.ReadAllBytes(
                    @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\Data\quests\questcache38339zhcn.wdb"))
                )
                {
                    using (var dbReader = new BinaryReader(ms, Encoding.UTF8))
                    {
                        dbReader.ReadByte(24);
                        while (true)
                        {
                            index++;
                            Console.WriteLine(index);
                            var id = dbReader.ReadInt32();
                            if (id == 62)
                                Console.Write(true);
                            var length = dbReader.ReadInt32();
                            var currentPosition = ms.Position;
                            dbReader.ReadByte(17 * 4);
                            dbReader.ReadByte(0xc);
                            dbReader.ReadByte(40);
                            dbReader.ReadByte(0x20);
                            dbReader.ReadByte(0x20);
                            dbReader.ReadByte(0x48);
                            dbReader.ReadByte(44);
                            dbReader.ReadByte(0x50);
                            dbReader.ReadByte(4);
                            dbReader.ReadByte(0x20);
                            dbReader.ReadByte(16);
                            var numObjectives = dbReader.ReadInt32();
                            dbReader.ReadByte(8);
                            dbReader.ReadByte(8);

                            var lengthBytes = dbReader.ReadByte(12);
                            var bits = new BitArray(lengthBytes);
                            var titleLength = 0;
                            titleLength |= lengthBytes[0] & 0xFF;
                            titleLength <<= 1;
                            titleLength |= (lengthBytes[1] & 0x80) >> 7;

                            var objectiveLength = 0;
                            objectiveLength |= lengthBytes[1] & 0x7F;
                            objectiveLength <<= 5;
                            objectiveLength |= (lengthBytes[2] & 0xF8) >> 3;

                            var descriptionLength = 0;
                            descriptionLength |= lengthBytes[2] & 0x07;
                            descriptionLength <<= 8;
                            descriptionLength |= lengthBytes[3] & 0xFF;
                            descriptionLength <<= 1;
                            descriptionLength |= (lengthBytes[4] & 0x80) >> 7;

                            for (int i = 0; i < numObjectives; ++i)
                            {
                                dbReader.ReadByte(4);
                                dbReader.ReadByte(1);
                                dbReader.ReadByte(1);
                                dbReader.ReadByte(24);
                                var objectiveDescriptionByte = dbReader.ReadByte();
                                var objectiveDescriptionBytes = dbReader.ReadByte(objectiveDescriptionByte);
                                var objectiveDescription = new string(Encoding.UTF8.GetChars(objectiveDescriptionBytes));
                            }

                            var titleBytes = dbReader.ReadByte(titleLength);
                            var title = new string(Encoding.UTF8.GetChars(titleBytes));
                            var objectiveBytes = dbReader.ReadByte(objectiveLength);
                            var objective = new string(Encoding.UTF8.GetChars(objectiveBytes));
                            var descriptionBytes = dbReader.ReadByte(descriptionLength);
                            var description = new string(Encoding.UTF8.GetChars(descriptionBytes));
                            ms.Position = currentPosition + length;

                            var quest = new Quest();
                            quest.Id = id.ToString();
                            quest.Title = title;
                            quest.Objectives = objective;
                            quest.Description = description.Replace("\"", "\\\"");

                            questObjects.Add(quest);
                        }
                    }
                }
            }
            catch (Exception)
            {
                Console.Write(index);
            }

            var sb = new StringBuilder();
            foreach (var questObject in questObjects.OrderBy(q => int.Parse(q.Id)))
            {
                var line = PrintLine(questObject);
                //line = SpecialTreatment(line);
                line = line.Replace(Environment.NewLine, @"NEW_LINE").Replace("\n", @"NEW_LINE");
                line = line.Replace(@"$r", @"{race}").Replace(@"$R", @"{race}");
                line = line.Replace(@"$c", @"{class}").Replace(@"$C", @"{class}");
                line = line.Replace(@"$n", @"{name}").Replace(@"$N", @"{name}");
                line = line.Replace(@"$b", @"NEW_LINE").Replace(@"$B", @"NEW_LINE");
                line = ReplaceGender(line);
                //line = ReplacePlayer(line, questObject, sbQuestToCheck);
                sb.AppendLine(line);
            }

            var finalText = sb.ToString();
            File.WriteAllText(outputPath, finalText);
        }

        private static string ReplaceGender(string text)
        {
            var genderText = "$g";
            while (text.Contains(genderText))
            {
                var index = text.IndexOf(genderText);

                var tempText = text.Substring(index + genderText.Length);

                var index2 = tempText.IndexOf(":");
                var genderFirstText = tempText.Substring(0, index2);
                if (genderFirstText.Contains("[")) Console.Write(true);
                tempText = tempText.Substring(index2 + 1);
                var index3 = tempText.IndexOf(";");
                var gender2ndText = tempText.Substring(0, index3);

                if (gender2ndText.Contains("[")) Console.Write(true);
                var newText = "YOUR_GENDER" + "(" + genderFirstText + ";" + gender2ndText + ")";
                var oldText = genderText + genderFirstText + ":" + gender2ndText + ";";
                text = text.Replace(oldText, newText);
            }

            genderText = "$G";
            while (text.Contains(genderText))
            {
                var index = text.IndexOf(genderText);

                var tempText = text.Substring(index + genderText.Length);

                var index2 = tempText.IndexOf(":");
                var genderFirstText = tempText.Substring(0, index2);
                if (genderFirstText.Contains("[")) Console.Write(true);
                tempText = tempText.Substring(index2 + 1);
                var index3 = tempText.IndexOf(";");
                var gender2ndText = tempText.Substring(0, index3);

                if (gender2ndText.Contains("[")) Console.Write(true);
                var newText = "YOUR_GENDER" + "(" + genderFirstText + ";" + gender2ndText + ")";
                var oldText = genderText + genderFirstText + ":" + gender2ndText + ";";
                text = text.Replace(oldText, newText);
            }

            return text;
        }
        
        public string PrintLine(Quest quest)
        {
            var text = m_template.Replace("$Id$", quest.Id).Replace("$Title$", quest.Title)
                .Replace("$Objectives$", quest.Objectives).Replace("$Description$", quest.Description)
                .Replace("$Progress$", quest.Progress).Replace("$Completion$", quest.Completion);
            return text;
        }

        private string[] m_sampleText;
        private readonly string m_template;
    }
}