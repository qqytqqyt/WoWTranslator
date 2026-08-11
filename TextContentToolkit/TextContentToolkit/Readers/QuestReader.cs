using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using System.Text.RegularExpressions;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;
using TextContentToolkit.Utils;

namespace TextContentToolkit
{
    /// <summary>
    /// Builds the WoWeuCN quest data file from scanner objectives (*.lua) and client
    /// quest caches (*.wdb), merged on top of the previous output. Merging is per field:
    /// a new non-empty value wins, except that translated (Chinese) text is never
    /// replaced by untranslated text.
    /// </summary>
    public class QuestReader
    {
        private const string TemplateLine =
            "[\"$Id$\"]={[\"Title\"]=\"$Title$\", [\"Objectives\"]=\"$Objectives$\", [\"Description\"]=\"$Description$\", [\"Progress\"]=\"$Progress$\", [\"Completion\"]=\"$Completion$\", [\"Translator\"]=\"$Translator$\"},";

        private static readonly Regex BaselineLineRegex = new Regex(
            "^\\s*\\[\"(?<id>\\d+)\"\\]=\\{\\[\"Title\"\\]=\"(?<title>.*?)\", \\[\"Objectives\"\\]=\"(?<objectives>.*?)\", \\[\"Description\"\\]=\"(?<description>.*?)\", \\[\"Progress\"\\]=\"(?<progress>.*?)\", \\[\"Completion\"\\]=\"(?<completion>.*?)\", \\[\"Translator\"\\]=\"(?<translator>.*?)\"\\},?\\s*$",
            RegexOptions.Compiled);

        private sealed class QuestRow
        {
            public Quest Quest;

            public string RawLine;

            public bool Touched;
        }

        public void Execute(List<string> objectivePaths, List<string> cachePaths, string baselinePath, string outputPath)
        {
            var baseline = LoadBaseline(baselinePath);

            var objectives = new List<QuestObjectives>();
            foreach (var objectivePath in objectivePaths)
                ReadObjectives(objectivePath, objectives);

            // Known titles anchor the wdb parser calibration: previous output plus fresh objectives.
            var expectedTitles = new Dictionary<int, string>();
            foreach (var row in baseline.Where(r => r.Value.Quest != null && !string.IsNullOrEmpty(r.Value.Quest.Title)))
                expectedTitles[row.Key] = row.Value.Quest.Title;
            foreach (var objective in objectives)
            {
                int id;
                if (int.TryParse(objective.Id, out id) && !string.IsNullOrEmpty(objective.Title))
                    expectedTitles[id] = objective.Title;
            }

            var cachedQuests = new List<Quest>();
            foreach (var cachePath in cachePaths)
                SmartQuestCacheReader.ReadQuestCache(cachePath, cachedQuests, expectedTitles);

            var newQuests = Compose(cachedQuests, objectives);
            foreach (var quest in newQuests)
                NormalizeQuest(quest);

            foreach (var quest in newQuests)
                MergeIntoBaseline(baseline, quest);

            var lines = new List<string> { "WoWeuCN_Quests_QuestData = {" };
            foreach (var row in baseline.Values)
                lines.Add(row.Touched || row.RawLine == null ? Render(row.Quest) : row.RawLine);
            lines.Add("}");
            File.WriteAllLines(outputPath, lines);
        }

        private static List<Quest> Compose(List<Quest> cachedQuests, List<QuestObjectives> objectives)
        {
            var usedId = new HashSet<string>();
            var questObjects = new List<Quest>();

            foreach (var cachedQuest in cachedQuests)
            {
                usedId.Add(cachedQuest.Id);

                var questObject = new Quest();
                questObject.Id = cachedQuest.Id;
                questObject.Title = cachedQuest.Title;

                var objective = objectives.FirstOrDefault(o => o.Id == questObject.Id);
                questObject.Objectives = objective != null && cachedQuest.Objectives.Contains(@"oa")
                    ? objective.Objectives
                    : cachedQuest.Objectives;

                questObject.Description = cachedQuest.Description;
                questObject.Progress = string.Empty;
                questObject.Completion = string.Empty;
                questObjects.Add(questObject);
            }

            // objectives without a cache record still contribute title + objectives
            foreach (var questObjective in objectives.Where(o => !usedId.Contains(o.Id)))
            {
                usedId.Add(questObjective.Id);

                var questObject = new Quest();
                questObject.Id = questObjective.Id;
                questObject.Title = questObjective.Title;
                questObject.Objectives = questObjective.Objectives;
                questObject.Description = string.Empty;
                questObject.Progress = string.Empty;
                questObject.Completion = string.Empty;
                questObjects.Add(questObject);
            }

            return questObjects;
        }

        public void ReadObjectives(string objectivesPath, List<QuestObjectives> objectives)
        {
            var lines = ScannerSectionFilter.FilterCategoryLines(
                File.ReadAllLines(objectivesPath), ScannerSectionFilter.IsQuestSection);
            foreach (var line in lines)
            {
                var objective = new QuestObjectives();
                var text = line.Trim();

                if (string.IsNullOrEmpty(text) || !text.StartsWith("["))
                    continue;

                var id = text.Split(new[] { "[\"" }, StringSplitOptions.None)[1]
                    .Split(new[] { "\"]" }, StringSplitOptions.None)[0]
                    .Trim();

                if (!int.TryParse(id, out _))
                    continue;

                objective.Id = id;

                var textContent = text.TrimTextAfter(@"{{");

                var textTitle = textContent.GetTextBefore(@"}}");

                objective.Title = textTitle;

                textContent = text.TrimTextAfter(@"}}");
                var textObjective = textContent.FirstBetween("{{", "}}");

                if (!textObjective.StartsWith("要求："))
                    objective.Objectives = textObjective;

                var otherObjective = objectives.FirstOrDefault(o => o.Id == id);

                if (otherObjective == null)
                    objectives.Add(objective);
                else
                {
                    if (objective.Objectives.Length == 0 && otherObjective.Objectives.Length > 0)
                        objective.Objectives = otherObjective.Objectives;

                    objectives.Remove(otherObjective);
                    objectives.Add(objective);
                }
            }
        }

        private static SortedDictionary<int, QuestRow> LoadBaseline(string baselinePath)
        {
            var rows = new SortedDictionary<int, QuestRow>();
            if (string.IsNullOrWhiteSpace(baselinePath) || !File.Exists(baselinePath))
                return rows;

            foreach (var line in File.ReadLines(baselinePath))
            {
                if (!line.TrimStart().StartsWith("[\""))
                    continue;

                var match = BaselineLineRegex.Match(line);
                if (match.Success)
                {
                    var quest = new Quest
                    {
                        Id = match.Groups["id"].Value,
                        Title = match.Groups["title"].Value,
                        Objectives = match.Groups["objectives"].Value,
                        Description = match.Groups["description"].Value,
                        Progress = match.Groups["progress"].Value,
                        Completion = match.Groups["completion"].Value,
                        Translator = match.Groups["translator"].Value
                    };
                    rows[int.Parse(quest.Id)] = new QuestRow { Quest = quest, RawLine = line };
                }
                else
                {
                    int id;
                    if (int.TryParse(line.FirstBetween("[\"", "\"]"), out id))
                        rows[id] = new QuestRow { RawLine = line };
                }
            }

            return rows;
        }

        private static void MergeIntoBaseline(SortedDictionary<int, QuestRow> baseline, Quest incoming)
        {
            int id;
            if (!int.TryParse(incoming.Id, out id))
                return;

            QuestRow row;
            if (!baseline.TryGetValue(id, out row) || row.Quest == null)
            {
                baseline[id] = new QuestRow { Quest = incoming, Touched = true };
                return;
            }

            var quest = row.Quest;
            row.Touched |= ApplyField(quest.Title, incoming.Title, v => quest.Title = v);
            row.Touched |= ApplyField(quest.Objectives, incoming.Objectives, v => quest.Objectives = v);
            row.Touched |= ApplyField(quest.Description, incoming.Description, v => quest.Description = v);
            row.Touched |= ApplyField(quest.Progress, incoming.Progress, v => quest.Progress = v);
            row.Touched |= ApplyField(quest.Completion, incoming.Completion, v => quest.Completion = v);
        }

        /// <summary>New non-empty text wins, but translated text is never replaced by untranslated text.</summary>
        private static bool ApplyField(string oldValue, string newValue, Action<string> setter)
        {
            if (string.IsNullOrEmpty(newValue) || newValue.Trim().Length == 0)
                return false;

            if (!string.IsNullOrEmpty(oldValue) && oldValue.HasChinese() && !newValue.HasChinese())
                return false;

            if (newValue == oldValue)
                return false;

            setter(newValue);
            return true;
        }

        private static void NormalizeQuest(Quest quest)
        {
            quest.Title = Normalize(quest.Title);
            quest.Objectives = Normalize(quest.Objectives);
            quest.Description = Normalize(quest.Description);
            quest.Progress = Normalize(quest.Progress);
            quest.Completion = Normalize(quest.Completion);
        }

        private static string Normalize(string text)
        {
            if (string.IsNullOrEmpty(text))
                return text ?? string.Empty;

            text = text.Replace(Environment.NewLine, @"NEW_LINE").Replace("\n", @"NEW_LINE");

            text = text.Replace(@"$r", @"{race}").Replace(@"$R", @"{race}");
            text = text.Replace(@"$c", @"{class}").Replace(@"$C", @"{class}");
            text = text.Replace(@"$n", @"{name}").Replace(@"$N", @"{name}");
            text = text.Replace(@"$p", @"{name}").Replace(@"$P", @"{name}");
            text = text.Replace(@"$b", @"NEW_LINE").Replace(@"$B", @"NEW_LINE");

            return ReplaceGender(text);
        }

        private static string Render(Quest quest)
        {
            return TemplateLine.Replace("$Id$", quest.Id)
                .Replace("$Title$", quest.Title)
                .Replace("$Objectives$", quest.Objectives)
                .Replace("$Description$", quest.Description)
                .Replace("$Progress$", quest.Progress)
                .Replace("$Completion$", quest.Completion)
                .Replace("$Translator$", quest.Translator ?? string.Empty);
        }

        private static string ReplaceGender(string text)
        {
            foreach (var genderText in new[] { "$g", "$G" })
            {
                while (text.Contains(genderText))
                {
                    var index = text.IndexOf(genderText, StringComparison.Ordinal);

                    var tempText = text.Substring(index + genderText.Length);

                    var index2 = tempText.IndexOf(":", StringComparison.Ordinal);
                    if (index2 < 0)
                        break;
                    var genderFirstText = tempText.Substring(0, index2);
                    tempText = tempText.Substring(index2 + 1);
                    var index3 = tempText.IndexOf(";", StringComparison.Ordinal);
                    if (index3 < 0)
                        break;
                    var gender2ndText = tempText.Substring(0, index3);

                    var newText = "YOUR_GENDER" + "(" + genderFirstText + ";" + gender2ndText + ")";
                    var oldText = genderText + genderFirstText + ":" + gender2ndText + ";";
                    text = text.Replace(oldText, newText);
                }
            }

            return text;
        }

        #region Questie output (legacy --questie mode)

        public void WriteToQuestie(string outputPath, string locale, List<Quest> questObjects, string filterPath = null)
        {
            var sb = new StringBuilder();

            var validIds = new HashSet<string>();
            var useFilter = !string.IsNullOrEmpty(filterPath);
            if (useFilter)
            {
                foreach (var line in File.ReadAllLines(filterPath))
                {
                    if (!line.Trim().StartsWith("["))
                        continue;

                    validIds.Add(line.FirstBetween("[", "]"));
                }
            }

            var preText = @"---@type l10n
local l10n = QuestieLoader:ImportModule(""l10n"")

l10n.questLookup[""localeCode""] = { ";
            preText = preText.Replace("localeCode", locale);
            sb.AppendLine(preText);
            foreach (var questObject in questObjects.OrderBy(q => int.Parse(q.Id)))
            {
                if (useFilter && !validIds.Contains(questObject.Id))
                    continue;

                sb.Append("[" + questObject.Id + "] = {");
                sb.Append("\"" + questObject.Title.Replace("\\\"", "#$#$").Replace("\"", "\\\"").Replace("#$#$", "\\\"") +
                          "\", ");
                AppendQuestieBlock(sb, questObject.Description, false);
                AppendQuestieBlock(sb, questObject.Objectives, true);
                sb.AppendLine(",");
            }

            sb.AppendLine("}");
            File.WriteAllText(outputPath, sb.ToString());
        }

        private static void AppendQuestieBlock(StringBuilder sb, string text, bool isLast)
        {
            if (string.IsNullOrEmpty(text) || string.IsNullOrEmpty(text.Trim()))
            {
                sb.Append(isLast ? "nil}" : "nil, ");
                return;
            }

            var questLines = text.Split(new[] { "$b", "$B", Environment.NewLine }, StringSplitOptions.RemoveEmptyEntries);
            var questLinesModified = new List<string>();
            foreach (var questLine in questLines)
            {
                var line = questLine;

                line = line.Replace(@"$r", @"<race>").Replace(@"$R", @"<race>");
                line = line.Replace(@"$c", @"<class>").Replace(@"$C", @"<class>");
                line = line.Replace(@"$n", @"<name>").Replace(@"$N", @"<name>");
                line = line.Replace(@"$p", @"<name>").Replace(@"$P", @"<name>");

                line = ReplaceGenderQuestie(line);
                questLinesModified.Add(line);
            }

            var questDescText = string.Join(",",
                questLinesModified.Select(s =>
                    "\"" + s.Replace("\\\"", "#$#$").Replace("\"", "\\\"").Replace("#$#$", "\\\"") + "\""));
            sb.Append("{" + questDescText + "}").Append(isLast ? "}" : ", ");
        }

        private static string ReplaceGenderQuestie(string text)
        {
            foreach (var genderText in new[] { "$g", "$G" })
            {
                while (text.Contains(genderText))
                {
                    var index = text.IndexOf(genderText, StringComparison.Ordinal);

                    var tempText = text.Substring(index + genderText.Length);

                    var index2 = tempText.IndexOf(":", StringComparison.Ordinal);
                    if (index2 < 0)
                        break;
                    var genderFirstText = tempText.Substring(0, index2);
                    tempText = tempText.Substring(index2 + 1);
                    var index3 = tempText.IndexOf(";", StringComparison.Ordinal);
                    if (index3 < 0)
                        break;
                    var gender2ndText = tempText.Substring(0, index3);

                    var newText = "<" + genderFirstText + "/" + gender2ndText + ">";
                    var oldText = genderText + genderFirstText + ":" + gender2ndText + ";";
                    text = text.Replace(oldText, newText);
                }
            }

            return text;
        }

        public List<Quest> ComposeFromObjectives(string objectivesPath)
        {
            var objectives = new List<QuestObjectives>();
            ReadObjectives(objectivesPath, objectives);
            return Compose(new List<Quest>(), objectives);
        }

        #endregion
    }
}
