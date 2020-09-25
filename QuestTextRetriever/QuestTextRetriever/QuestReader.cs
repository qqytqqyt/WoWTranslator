using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;

namespace QuestTextRetriever
{
    public class QuestReader
    {
        public QuestReader(string dirPath, string templateFilePath)
        {
            m_dirPath = dirPath;
            m_template = File.ReadAllText(templateFilePath);
        }


        public void ReadObjectives(string objectivesPath, List<QuestObjectives> objectives)
        {
            var lines = File.ReadAllLines(objectivesPath);
            foreach (var line in lines)
            {
                var objective = new QuestObjectives();
                var text = line.Trim();
                var id = text.Split(new[] {"[\""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\"]"}, StringSplitOptions.None)[0]
                    .Trim();

                objective.Id = id;
                var otherObjective = objectives.FirstOrDefault(o => o.Id == id);
                var textContent = text.Split(new[] {"= \""}, StringSplitOptions.None)[1]
                    .Split(new[] {"\","}, StringSplitOptions.None)[0]
                    .Trim();

                var contents = textContent.Split(' ');
                if (contents.Length < 2)
                {
                    if (otherObjective == null)
                    {
                        objective.Objectives = string.Empty;
                        objectives.Add(objective);
                    }

                    continue;
                }

                var textTitle = textContent.Split(' ')[0];

                objective.Title = textTitle;

                textContent = textContent.Split(' ')[1].Split(new[] {"要求："}, StringSplitOptions.None)[0];
                objective.Objectives = textContent.Trim();

                if (otherObjective == null)
                    objectives.Add(objective);
            }
        }

        public void ExecuteJson(string outputPath)
        {
            var objectives = new List<QuestObjectives>();
            ReadObjectives(
                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\QuestCompletist.lua",
                objectives);
            ReadObjectives(
                @"C:\Users\qqytqqyt\OneDrive\Documents\OneDrive\OwnProjects\WoWTranslator\WoWeuCN_Quests_beta.lua",
                objectives);
            var sb = new StringBuilder();
            var dirPath = new DirectoryInfo(m_dirPath);
            var questObjects = new List<Quest>();
            var usedId = new HashSet<string>();
            foreach (var filePath in dirPath.GetFiles(@"*.json"))
            {
                var text = File.ReadAllText(filePath.FullName);
                var questApi = JsonConvert.DeserializeObject<QuestApi>(text);

                var questObject = new Quest();
                usedId.Add(questApi.Id);
                questObject.Id = questApi.Id;
                questObject.Title = questApi.Title;
                var objective = objectives.FirstOrDefault(o => o.Id == questApi.Id);
                if (objective != null)
                    questObject.Objectives = objective.Objectives;
                else
                    questObject.Objectives = string.Empty;

                questObject.Description = questApi.Description?.Replace("\"", string.Empty).Replace("“", string.Empty)
                    .Replace("”", string.Empty);
                questObject.Progress = string.Empty;
                questObject.Completion = string.Empty;
                questObjects.Add(questObject);
            }

            foreach (var questObjective in objectives.Where(o => !usedId.Contains(o.Id)))
            {
                var questObject = new Quest();
                questObject.Id = questObjective.Id;
                questObject.Title = questObjective.Title;
                questObject.Objectives = questObjective.Objectives;
                questObject.Description = string.Empty;
                questObject.Progress = string.Empty;
                questObject.Completion = string.Empty;
                questObjects.Add(questObject);
            }

            var sbQuestToCheck = new StringBuilder();
            foreach (var questObject in questObjects.OrderBy(q => int.Parse(q.Id)))
            {
                var line = PrintLine(questObject);
                //line = SpecialTreatment(line);
                line = line.Replace(Environment.NewLine, @"NEW_LINE").Replace("\n", @"NEW_LINE");
                line = ReplaceGender(line);
                //line = ReplacePlayer(line, questObject, sbQuestToCheck);
                sb.AppendLine(line);
            }

            File.WriteAllText(outputPath + ".log", sbQuestToCheck.ToString());
            var finalText = sb.ToString();
            File.WriteAllText(outputPath, finalText);
        }

        //public void Execute(string outputPath, string samplePath)
        //{
        //    m_sampleText = File.ReadAllLines(samplePath);
        //    var sb = new StringBuilder();
        //    var dirPath = new DirectoryInfo(m_dirPath);
        //    var questObjects = new List<Quest>();
        //    foreach (var filePath in dirPath.GetFiles(@"*.html"))
        //    {
        //        var text = File.ReadAllText(filePath.FullName);
        //        var id = filePath.Name.Replace(@".html", string.Empty);
        //        var title = GetValueFromString(text, "<h1 title=\"", "</h1>", ref text);
        //        var objectives = GetValueFromString(text, "<h3>任务需求</h3>", "</div", ref text);
        //        var description = GetValueFromString(text, "<h3>任务描述</h3>", "</div", ref text);
        //        var progress = GetValueFromString(text, "<h3>任务返回</h3>", "</div", ref text);
        //        var completion = GetValueFromString(text, "<h3>任务完成</h3>", "<div ", ref text);

        //        var questObject = new Quest();
        //        questObject.Id = id;
        //        questObject.Title = title;
        //        questObject.Objectives = objectives;
        //        questObject.Description = description;
        //        questObject.Progress = progress;
        //        questObject.Completion = completion;
        //        questObjects.Add(questObject);
        //    }

        //    var sbQuestToCheck = new StringBuilder();
        //    foreach (var questObject in questObjects.OrderBy(q => int.Parse(q.Id)))
        //    {
        //        var line = PrintLine(questObject);
        //        line = SpecialTreatment(line);
        //        line = ReplaceGender(line);
        //        line = ReplacePlayer(line, questObject, sbQuestToCheck);
        //        sb.AppendLine(line);
        //    }

        //    File.WriteAllText(outputPath + ".log", sbQuestToCheck.ToString());
        //    var finalText = sb.ToString();
        //    File.WriteAllText(outputPath, finalText);
        //}

        //public static string SpecialTreatment(string text)
        //{
        //    return text.Replace("麽", "么").Replace("；", ";").Replace("<Class>", "YOUR_CLASS").Replace("萨丁巴我", "萨丁和我").Replace("於", "于")
        //        .Replace("―", "─")
        //        .Replace("：", ":").Replace("；", ";")
        //        .Replace("$G魅魔; 在她找到你之前你就来了", "YOUR_GENDER(魅魔;地狱火)跟着你，以便引起你的注意，但看起来你在它找到你之前就来到这里了")
        //        .Replace("(玩家);指挥官雷尔松咧嘴笑着。$g;", "NEW_LINENEW_LINE<指挥官雷尔松咧嘴笑着。>");
        //}

        //private string ReplacePlayer(string text, Quest questObject, StringBuilder sbQuestToCheck)
        //{
        //    var playerText = "(玩家)";

        //    if (questObject.Id == "218")
        //        Console.WriteLine(true);
        //    text = ChineseConverter.Convert(text, ChineseConversionDirection.TraditionalToSimplified);
        //    var sampleLine = m_sampleText.First(l => l.StartsWith("    [\"" + questObject.Id));
        //    sampleLine = ChineseConverter.Convert(sampleLine, ChineseConversionDirection.TraditionalToSimplified);

        //    while (text.Contains(playerText))
        //    {
        //        var index = text.IndexOf(playerText);
        //        var checkTextBefore = text.Substring(index - 6, 6);
        //        var checkTextAfter = text.Substring(index + playerText.Length, 6);

        //        var indexOriginBefore = sampleLine.IndexOf(checkTextBefore);
        //        var indexOriginAfter = -1;
        //        if (indexOriginBefore > 0)
        //            indexOriginAfter = sampleLine.Substring(indexOriginBefore).IndexOf(checkTextAfter) + indexOriginBefore;
        //        var newText = string.Empty;
        //        if (indexOriginBefore == -1 || indexOriginAfter < indexOriginBefore)
        //        {
        //            sbQuestToCheck.AppendLine(questObject.Id);
        //            newText = checkTextBefore + "YOUR_PLAYER" + checkTextAfter;
        //        }
        //        else
        //        {
        //            newText = checkTextBefore + sampleLine.Substring(indexOriginBefore + 6, indexOriginAfter - indexOriginBefore - 6) + checkTextAfter;
        //        }

        //        var oldText = checkTextBefore + playerText + checkTextAfter;
        //        text = text.Replace(oldText, newText);
        //    }

        //    return text;
        //}

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

        //private static string GetValueFromString(string inputString, string keyword, string endKeyword, ref string text)
        //{
        //    var startText = keyword;
        //    int index = inputString.IndexOf(keyword, StringComparison.OrdinalIgnoreCase);
        //    if (index < 0)
        //        return string.Empty;

        //    inputString = inputString.Substring(index + startText.Length);

        //    int indexStart = inputString.IndexOf("\">", StringComparison.OrdinalIgnoreCase);
        //    if (indexStart < 0)
        //        throw new Exception(inputString + Environment.NewLine + keyword);

        //    inputString = inputString.Substring(indexStart + 2);

        //    int indexEnd = inputString.IndexOf(endKeyword, StringComparison.OrdinalIgnoreCase);
        //    var output = inputString.Substring(0, indexEnd);
        //    text = inputString.Substring(indexEnd);
        //    output = output.Replace("\n", string.Empty);
        //    if (output.EndsWith("<br>"))
        //        output = output.Substring(0, output.Length - 4);
        //    return output.Replace("<br>", "NEW_LINENEW_LINE");

        //}

        public string PrintLine(Quest quest)
        {
            var text = m_template.Replace("$Id$", quest.Id).Replace("$Title$", quest.Title)
                .Replace("$Objectives$", quest.Objectives).Replace("$Description$", quest.Description)
                .Replace("$Progress$", quest.Progress).Replace("$Completion$", quest.Completion);
            return text;
        }

        private readonly string m_dirPath;

        private string[] m_sampleText;
        private readonly string m_template;
    }
}