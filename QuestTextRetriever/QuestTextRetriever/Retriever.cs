using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Reflection;
using System.Text;
using System.Threading.Tasks;
using HtmlAgilityPack;
using QuestTextRetriever.Models;

namespace QuestTextRetriever
{
    public class Retriever
    {
        private string m_filePath;
        private string m_template;

        public Retriever(string filePath, string templateFilePath)
        {
            m_filePath = filePath;
            m_template = File.ReadAllText(templateFilePath);
        }

        public void Execute(string outputPath)
        {
            var lines = File.ReadAllLines(m_filePath);
            var processedLines = new List<string>();
            var currentLine = string.Empty;
            foreach (var line in lines)
            {
                if (line.StartsWith("UPDATE") && !string.IsNullOrEmpty(currentLine))
                {
                    processedLines.Add(currentLine);
                    currentLine = string.Empty;
                }

                currentLine += line;
            }

            var sb = new StringBuilder();
            foreach (var line in processedLines)
            {
                var id = GetId(line);
                var title = GetValueFromString(line, "TITLE");
                var objectives = GetValueFromString(line, "Objectives");
                var description = GetValueFromString(line, "Details");
                var progress = GetValueFromString(line, "RequestItemsText");
                var completion = GetValueFromString(line, "OfferRewardText");

                var questObject = new Quest();
                questObject.Id = id;
                questObject.Title = title;
                questObject.Objectives = objectives;
                questObject.Description = description;
                questObject.Progress = progress;
                questObject.Completion = completion;

                var text = PrintLine(questObject);
                sb.AppendLine(text);
            }

            File.WriteAllText(outputPath, sb.ToString());
        }

        public void ExecuteApi(string outputPath)
        {

        }

        public string PrintLine(Quest quest)
        {
            var text = m_template.Replace("$Id$", quest.Id).Replace("$Title$", quest.Title).Replace("$Objectives$", quest.Objectives).Replace("$Description$", quest.Description)
                .Replace("$Progress$", quest.Progress).Replace("$Completion$", quest.Completion);
            return text;
        }

        private static string GetId(string inputString)
        {
            var startText = "ID" + "=";
            int index = inputString.IndexOf(startText, StringComparison.OrdinalIgnoreCase);
            if (index < 0)
                throw new Exception(inputString + Environment.NewLine + @"ID");

            inputString = inputString.Substring(index + startText.Length);
            int indexEnd = inputString.IndexOf(';');
            return inputString.Substring(0, indexEnd);
        }

        private static string GetValueFromString(string inputString, string keyword)
        {
            var startText = keyword + "='";
            int index = inputString.IndexOf(startText, StringComparison.OrdinalIgnoreCase);
            if (index < 0)
                throw new Exception(inputString + Environment.NewLine + keyword);

            inputString = inputString.Substring(index + startText.Length);
            int indexEnd = inputString.IndexOf('\'');
            var output = inputString.Substring(0, indexEnd);
            return output.Replace("\"", "\\\"");
        }

        //public void Execute()
        //{
        //    using (var webClient = new WebClient() { Encoding = System.Text.Encoding.UTF8 })
        //    {
        //        var text = webClient.DownloadString(@"https://cn.80wdb.com/?quest=" + 2);
        //        HtmlDocument document = new HtmlDocument();
        //        document.LoadHtml(text);
        //        var documentNode = document.DocumentNode;
        //        var titleNode = documentNode.Descendants("h1")
        //            .FirstOrDefault(n => n.HasAttributes && n.Attributes["class"] != null && n.Attributes["class"].Value == "heading-size-1");

        //        if (titleNode == null)
        //            return;
        //        var title = titleNode.InnerText;

        //        var descriptionNode = documentNode.Descendants("h2")
        //            .FirstOrDefault(n => n.HasAttributes && n.Attributes["class"] != null && n.Attributes["class"].Value == "heading-size-3" && n.InnerText == @"描述");
        //        var descriptionTextNode = descriptionNode.SelectSingleNode("following-sibling::text()[1]");
        //        var description = descriptionTextNode.InnerText;


        //        var questObject = new Quest();
        //        questObject.Title = title;
        //        questObject.Description = description;
        //        questObject.
        //    }


        //}

        
    }
}
