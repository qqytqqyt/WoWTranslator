using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using Newtonsoft.Json;
using TextContentToolkit.Models;
using TextContentToolkit.Utils;

namespace TextContentToolkit
{
    public class JournalReader
    {
        private static List<int> m_whiteList = new List<int>
        {
            247,248,249,250,251,252,253,254,255,256,257,258,259,260,261,262,745,746,747,748,749,750,751,752
        };

        public JournalReader(string dirPath)
        {
            m_dirPath = dirPath;
        }

        public void ExecuteJson(string outputPath)
        {
            var encounters = new List<JournalEncounter>();
            
            var dirPath = new DirectoryInfo(m_dirPath);
            ReadQuestApis(dirPath, encounters);

            var sb = new StringBuilder();
            var processedInstance = new List<int>();
            
            foreach (var instanceEncounters in encounters.GroupBy(c => c.Instance.Id).ToList().OrderBy(l => l.ToList()[0].Instance.Id))
            {
                var instanceBosses = instanceEncounters.OrderBy(i => i.Id).ToList();
                if (!m_whiteList.Contains(instanceBosses[0].Instance.Id))
                    continue;

                processedInstance.Add(instanceBosses[0].Instance.Id);
                sb.Append("[b][size=150%][color=royalblue]");
                sb.Append(instanceBosses[0].Instance.Name);
                sb.Append("[/color][/size][/b]").AppendLine();

                sb.Append("[quote]内容[/quote]").AppendLine();

                foreach (var instanceBoss in instanceBosses)
                {
                    sb.Append("[h]").Append(instanceBoss.Name).Append("[/h]").AppendLine();
                    sb.Append("[quote]").Append(instanceBoss.Description).AppendLine();

                    sb.Append("[h]概况说明[/h]").AppendLine();
                    sb.Append("[list][*]整体战术：").AppendLine();
                    sb.Append("[*]坦克：").AppendLine();
                    sb.Append("[*]治疗：").AppendLine();
                    sb.Append("[*]伤害输出：").Append("[/list]").AppendLine();

                    sb.Append("[h]").Append("技能列表").Append("[/h]").AppendLine();
                    sb.Append("[list]");
                    foreach (var section in instanceBoss.Sections)
                    {
                        WriteSections(sb, section, string.Empty);
                    }
                    sb.AppendLine("[/list]");

                    sb.Append("[h]").Append("掉落列表").Append("[/h]").AppendLine();
                    sb.Append("[quote]");
                    foreach (var instanceBossItem in instanceBoss.Items)
                    {
                        sb.Append($"[dict][{instanceBossItem.Item.Name}][url=https://cn.tbc.wowhead.com/item={instanceBossItem.Item.Id}]{instanceBossItem.Item.Name}[/url]");
                        sb.AppendLine("[/dict]");
                    }
                    sb.Append("[/quote]");
                    sb.AppendLine("[/quote]");

                    sb.AppendLine();
                }

                sb.AppendLine();
            }

            var finalText = sb.ToString();
            File.WriteAllText(outputPath, finalText);

        }

        private void WriteSections(StringBuilder sb, JournalSection section, string prefix)
        {
            //sb.Append(prefix);
            sb.Append("[*][color=skyblue]");
            sb.Append(section.Title);
            sb.Append("[/color]");
            if (!string.IsNullOrEmpty(section.Body_Text))
            {
                sb.Append(" : ").AppendLine(section.Body_Text);
            }
            
            if (section.Sections.Any())
            {
                sb.Append("[list]");
                foreach (var subSection in section.Sections)
                {
                    WriteSections(sb, subSection, prefix + "-");
                }
                sb.Append("[/list]");
            }

        }

        private static void ReadQuestApis(DirectoryInfo dirPath, List<JournalEncounter> apis)
        {
            foreach (var filePath in dirPath.GetFiles(@"*.json"))
            {
                var text = File.ReadAllText(filePath.FullName);
                var questApi = JsonConvert.DeserializeObject<JournalEncounter>(text);
                if (questApi == null)
                    continue;
                apis.Add(questApi);
            }
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