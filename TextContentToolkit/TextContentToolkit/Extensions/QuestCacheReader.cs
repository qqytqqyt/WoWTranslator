using System;
using System.Collections;
using System.Collections.Generic;
using System.Globalization;
using System.IO;
using System.Linq;
using System.Text;
using TextContentToolkit.Extensions;
using TextContentToolkit.Models;

namespace TextContentToolkit.Readers
{
    public static class QuestCacheReader
    {
        public static void ReadQuestCache(string fileName, List<Quest> questObjects)
        {
            var index = 0;
            long totalLength = 0;
            try
            {
                using (var ms = new MemoryStream(File.ReadAllBytes(fileName))
                )
                {
                    using (var dbReader = new BinaryReader(ms, Encoding.UTF8))
                    {
                        totalLength = ms.Length;
                        dbReader.ReadByte(24);
                        while (true)
                        {
                            index++;
                            Console.WriteLine(index);
                            if (index == 193)
                                Console.Write(true);
                            var id = dbReader.ReadInt32();
                            if (id == 8274)
                                Console.Write(true);
                            if (id == 78752)
                                Console.WriteLine(true);

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

                            dbReader.ReadByte(4);
                            dbReader.ReadByte(4);

                            var numObjectives = dbReader.ReadInt32();
                            dbReader.ReadByte(8);
                            dbReader.ReadByte(8);
                            dbReader.ReadByte(12);

                            var attemptPosition = ms.Position;
                            var attempCount = 1;
                            var title = string.Empty;
                            var objective = string.Empty;
                            var description = string.Empty;
                            while (true)
                            {
                                var abort = false;
                                //if (check3.All(c => c == 255))
                                //    dbReader.ReadByte(8);

                                Byte[] lengthBytes;
                                BitArray bits;
                                var titleLength = 0;
                                try
                                {
                                    lengthBytes = dbReader.ReadByte(12);
                                    bits = new BitArray(lengthBytes);
                                    titleLength = 0;
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

                                    if (numObjectives > 1)
                                        Console.Write(true);

                                    for (int i = 0; i < numObjectives; ++i)
                                    {
                                        var objectiveId = dbReader.ReadInt32();
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(20);
                                        var numVisual = dbReader.ReadInt32();
                                        if (numVisual != 0 && i > 0)
                                            Console.Write(true);
                                        for (int j = 0; j < numVisual; ++j)
                                            dbReader.ReadInt32();
                                        var objectiveDescriptionByte = dbReader.ReadByte();
                                        if (objectiveDescriptionByte > 0)
                                        {
                                            var objectiveDescriptionBytes = dbReader.ReadByte(objectiveDescriptionByte);
                                            var objectiveDescription =
                                                new string(Encoding.UTF8.GetChars(objectiveDescriptionBytes));
                                        }
                                    }

                                    var titleBytes = dbReader.ReadByte(titleLength);
                                    title = new string(Encoding.UTF8.GetChars(titleBytes));
                                    var objectiveBytes = dbReader.ReadByte(objectiveLength);
                                    objective = new string(Encoding.UTF8.GetChars(objectiveBytes));
                                    var descriptionBytes = dbReader.ReadByte(descriptionLength);
                                    description = new string(Encoding.UTF8.GetChars(descriptionBytes));

                                }
                                catch (Exception e)
                                {
                                    ms.Position = attemptPosition;
                                    if (ms.Position + attempCount > currentPosition + length)
                                        break;

                                    dbReader.ReadByte(attempCount);
                                    attempCount++;
                                    continue;
                                }

                                if (string.IsNullOrEmpty(title) || title.Contains("\r") || description.Contains('\0') || objective.Contains('\0') || title.Contains('\0') || !IsLegalUnicode(title))
                                {
                                    ms.Position = attemptPosition;
                                    if (ms.Position + attempCount > currentPosition + length)
                                        break;

                                    dbReader.ReadByte(attempCount);
                                    attempCount++;
                                    continue;
                                }

                                Console.WriteLine("(" + attempCount + ")");
                                attempCount = 1;
                                var quest = new Quest();
                                quest.Id = id.ToString();
                                quest.Title = title.Replace("\"", "\\\"");
                                quest.Objectives = objective.Replace("\"", "\\\"");
                                quest.Description = ReplaceGender(description.Replace("\"", "\\\""));


                                var otherObjective = questObjects.FirstOrDefault(o => o.Id == id.ToString());

                                if (otherObjective == null)
                                    questObjects.Add(quest);
                                else
                                {
                                    if (quest.Description.Length == 0 && otherObjective.Description.Length > 0)
                                        quest.Description = otherObjective.Description;
                                    if (quest.Objectives.Length == 0 && otherObjective.Objectives.Length > 0)
                                        quest.Objectives = otherObjective.Objectives;

                                    questObjects.Remove(otherObjective);
                                    questObjects.Add(quest);
                                }

                                break;
                            }

                            if (currentPosition + length >= totalLength - 100)
                                break;

                            ms.Position = currentPosition + length;

                            //var lengthBytes = dbReader.ReadByte(12);
                            //var bits = new BitArray(lengthBytes);
                            //var titleLength = 0;
                            //titleLength |= lengthBytes[0] & 0xFF;
                            //titleLength <<= 1;
                            //titleLength |= (lengthBytes[1] & 0x80) >> 7;

                            //var objectiveLength = 0;
                            //objectiveLength |= lengthBytes[1] & 0x7F;
                            //objectiveLength <<= 5;
                            //objectiveLength |= (lengthBytes[2] & 0xF8) >> 3;

                            //var descriptionLength = 0;
                            //descriptionLength |= lengthBytes[2] & 0x07;
                            //descriptionLength <<= 8;
                            //descriptionLength |= lengthBytes[3] & 0xFF;
                            //descriptionLength <<= 1;
                            //descriptionLength |= (lengthBytes[4] & 0x80) >> 7;

                            //for (int i = 0; i < numObjectives; ++i)
                            //{
                            //    dbReader.ReadByte(4);
                            //    dbReader.ReadByte(1);
                            //    dbReader.ReadByte(1);
                            //    dbReader.ReadByte(24);
                            //    var objectiveDescriptionByte = dbReader.ReadByte();
                            //    var objectiveDescriptionBytes = dbReader.ReadByte(objectiveDescriptionByte);
                            //    var objectiveDescription = new string(Encoding.UTF8.GetChars(objectiveDescriptionBytes));
                            //}

                            //var titleBytes = dbReader.ReadByte(titleLength);
                            //var title = new string(Encoding.UTF8.GetChars(titleBytes));
                            //var objectiveBytes = dbReader.ReadByte(objectiveLength);
                            //var objective = new string(Encoding.UTF8.GetChars(objectiveBytes));
                            //var descriptionBytes = dbReader.ReadByte(descriptionLength);
                            //var description = new string(Encoding.UTF8.GetChars(descriptionBytes));
                            //ms.Position = currentPosition + length;

                            //var quest = new Quest();
                            //quest.Id = id.ToString();
                            //quest.Title = title;
                            //quest.Objectives = objective;
                            //quest.Description = ReplaceGender(description.Replace("\"", "\\\""));

                            //questObjects.Add(quest);
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.Write(index);
            }
        }

        public static void ReadQuestCacheRetail(string fileName, List<Quest> questObjects)
        {
            var index = 0;
            var specialQuests = new List<int>();
            long totalLength = 0;
            try
            {
                using (var ms = new MemoryStream(File.ReadAllBytes(fileName
                    ))
                )
                {
                    using (var dbReader = new BinaryReader(ms, Encoding.UTF8))
                    {
                        totalLength = ms.Length;
                        dbReader.ReadByte(24);
                        while (true)
                        {
                            index++;
                            Console.WriteLine(index);
                            var id = dbReader.ReadInt32();
                            if (id == 12022)
                                Console.Write(true);
                            if (index == 307 || index == 6638)
                                Console.Write(true);
                            var length = dbReader.ReadInt32();
                            var currentPosition = ms.Position;
                            dbReader.ReadByte(13 * 4);
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
                            var check5 = dbReader.ReadByte(4);
                            var numObjectives = dbReader.ReadInt32();
                            var check3 = dbReader.ReadByte(8);
                            var check4 = dbReader.ReadByte(8);
                            var check1 = dbReader.ReadByte(4);
                            var check2 = dbReader.ReadByte(4);
                            var check6 = dbReader.ReadByte(12);
                            if (numObjectives > 1)
                            {
                                Console.Write(true);
                                //dbReader.ReadByte((numObjectives - 1) * 6);
                            }
                            var attemptPosition = ms.Position;
                            var attempCount = 1;
                            var title = string.Empty;
                            var objective = string.Empty;
                            var description = string.Empty;

                            while (true)
                            {
                                var abort = false;
                                //if (check3.All(c => c == 255))
                                //    dbReader.ReadByte(8);
                                try
                                {

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

                                    //if (numObjectives > 2)
                                    //    Console.Write(true);
                                    if (numObjectives > 1)
                                        Console.Write(true);

                                    for (int i = 0; i < numObjectives; ++i)
                                    {
                                        var objectiveId = dbReader.ReadInt32();
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(20);
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(1);
                                        dbReader.ReadByte(1);
                                        var numVisual = dbReader.ReadInt32();
                                        if (numVisual != 0 && i > 0)
                                            Console.Write(true);
                                        if (numVisual < 0)
                                            Console.Write(true);
                                        for (int j = 0; j < numVisual; ++j)
                                            dbReader.ReadInt32();
                                        var objectiveDescriptionByte = dbReader.ReadByte();
                                        if (objectiveDescriptionByte > 0)
                                        {
                                            var objectiveDescriptionBytes = dbReader.ReadByte(objectiveDescriptionByte);
                                            var objectiveDescription =
                                                new string(Encoding.UTF8.GetChars(objectiveDescriptionBytes));
                                        }
                                    }

                                    var titleBytes = dbReader.ReadByte(titleLength);
                                    title = new string(Encoding.UTF8.GetChars(titleBytes));
                                    var objectiveBytes = dbReader.ReadByte(objectiveLength);
                                    objective = new string(Encoding.UTF8.GetChars(objectiveBytes));
                                    var descriptionBytes = dbReader.ReadByte(descriptionLength);
                                    description = new string(Encoding.UTF8.GetChars(descriptionBytes));

                                }
                                catch (Exception e)
                                {
                                    ms.Position = attemptPosition;
                                    if (ms.Position + attempCount > currentPosition + length)
                                        break;

                                    dbReader.ReadByte(attempCount);
                                    attempCount++;
                                    continue;
                                }


                                if (string.IsNullOrEmpty(title) || title.Contains("\r") || description.Contains('\0') || objective.Contains('\0') || title.Contains('\0') || !IsLegalUnicode(title) || 
                                    title.Trim().Length != title.Length || objective.Trim().Length != objective.Length)
                                {
                                    ms.Position = attemptPosition;
                                    if (ms.Position + attempCount > currentPosition + length)
                                        break;

                                    dbReader.ReadByte(attempCount);
                                    attempCount++;
                                    continue;
                                }

                                if (title.Trim().Length != title.Length || objective.Trim().Length != objective.Length)
                                    Console.Write(true);

                                Console.WriteLine("(" + attempCount + ")");
                                attempCount = 1;
                                var quest = new Quest();
                                quest.Id = id.ToString();
                                quest.Title = title.Replace("\"", "\\\"");
                                quest.Objectives = objective.Replace("\"", "\\\"");
                                quest.Description = ReplaceGender(description.Replace("\"", "\\\""));


                                var otherObjective = questObjects.FirstOrDefault(o => o.Id == id.ToString());

                                if (otherObjective == null)
                                    questObjects.Add(quest);
                                else
                                {
                                    if (quest.Description.Length == 0 && otherObjective.Description.Length > 0)
                                        quest.Description = otherObjective.Description;
                                    if (quest.Objectives.Length == 0 && otherObjective.Objectives.Length > 0)
                                        quest.Objectives = otherObjective.Objectives;

                                    questObjects.Remove(otherObjective);
                                    questObjects.Add(quest);
                                }

                                break;
                            }

                            if (currentPosition + length >= totalLength - 100)
                                break;

                            ms.Position = currentPosition + length;
                        }
                    }
                }
            }
            catch (Exception e)
            {
                Console.Write(index);
            }
        }

        private static bool IsLegalUnicode(string str)
        {
            for (int i = 0; i < str.Length; i++)
            {
                var uc = char.GetUnicodeCategory(str, i);

                if (uc == UnicodeCategory.Surrogate)
                {
                    // Unpaired surrogate, like  "😵"[0] + "A" or  "😵"[1] + "A"
                    return false;
                }
                else if (uc == UnicodeCategory.OtherNotAssigned)
                {
                    // \uF000 or \U00030000
                    return false;
                }
                else if (uc == UnicodeCategory.OtherSymbol)
                {
                    // \uF000 or \U00030000
                    return false;
                }

                // Correct high-low surrogate, we must skip the low surrogate
                // (it is correct because otherwise it would have been a 
                // UnicodeCategory.Surrogate)
                if (char.IsHighSurrogate(str, i))
                {
                    i++;
                }
            }

            return true;
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
    }
}