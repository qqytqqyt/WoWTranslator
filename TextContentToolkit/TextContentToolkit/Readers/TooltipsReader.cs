using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using TextContentToolkit.Models;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    /// <summary>
    /// Base class of the item/spell/unit/achievement readers. Executes the shared flow:
    /// load the previous output as baseline, apply the new inputs on top (new data wins
    /// per record id), write the merged WoWeuCN output.
    /// </summary>
    public abstract class TooltipsReader
    {
        private static readonly Regex OutputEntryRegex = new Regex("^\\s*\"(?<payload>.*)\",\\s*--(?<id>\\d+)\\s*$", RegexOptions.Compiled);

        public void Execute(IEnumerable<string> inputPaths, string baselinePath, string outputPath)
        {
            var tips = new Dictionary<string, Tooltip>();
            LoadBaseline(baselinePath, tips);

            foreach (var inputPath in inputPaths)
                Read(inputPath, tips);

            WoWeuCNTooltipWriter.Write(outputPath, Profile, tips);
        }

        protected abstract void Read(string inputPath, Dictionary<string, Tooltip> tips);

        internal abstract WoWeuCNWriterProfile Profile { get; }

        /// <summary>Whether a scanner SavedVariables table belongs to this reader's category.</summary>
        protected abstract bool IsRelevantSection(string tableName);

        /// <summary>Reads an input file restricted to this category's scanner sections.</summary>
        protected IEnumerable<string> ReadCategoryLines(string inputPath)
        {
            return ScannerSectionFilter.FilterCategoryLines(File.ReadAllLines(inputPath), IsRelevantSection);
        }

        /// <summary>Loads the "payload", --id entries of a previous output as the merge baseline.</summary>
        protected static void LoadBaseline(string baselinePath, Dictionary<string, Tooltip> tips)
        {
            if (string.IsNullOrWhiteSpace(baselinePath) || !File.Exists(baselinePath))
                return;

            foreach (var line in File.ReadLines(baselinePath))
            {
                var match = OutputEntryRegex.Match(line);
                if (!match.Success)
                    continue;

                var id = match.Groups["id"].Value;
                var payload = match.Groups["payload"].Value;

                var tooltip = new Tooltip { Id = id };
                foreach (var tooltipLine in payload.Split(new[] { '£' }, StringSplitOptions.None))
                {
                    tooltip.TooltipLines.Add(new TooltipLine
                    {
                        Line = tooltipLine
                    });
                }

                tips[id] = tooltip;
            }
        }

        /// <summary>Stores a parsed record; an empty record never clobbers existing data for the same id.</summary>
        protected static void Store(Dictionary<string, Tooltip> tips, Tooltip tooltip)
        {
            if (!tooltip.TooltipLines.Any() && tips.ContainsKey(tooltip.Id))
                return;

            tips[tooltip.Id] = tooltip;
        }

        /// <summary>Reads the ids of a Questie filter file ("[id] = ..." lines).</summary>
        protected static HashSet<string> ReadQuestieFilter(string filterPath)
        {
            var validIds = new HashSet<string>();
            if (string.IsNullOrEmpty(filterPath))
                return validIds;

            foreach (var line in File.ReadAllLines(filterPath))
            {
                if (!line.Trim().StartsWith("["))
                    continue;

                validIds.Add(line.FirstBetween("[", "]"));
            }

            return validIds;
        }
    }
}
