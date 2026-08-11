using System;
using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;

namespace TextContentToolkit.Readers
{
    /// <summary>
    /// Restricts scanner lua parsing to the category's own SavedVariables tables.
    /// A WoWeuCN_Scanner.lua contains many top-level tables (ItemToolTips*, SpellToolTips*,
    /// UnitToolTips*, Achivements*, QuestToolTips, *NameData, EncounterData, Decor, ...);
    /// without filtering, one category's reader would consume another category's entries.
    /// Files without any table declaration (bare extracts, Questie l10n files, previous
    /// outputs) are passed through unfiltered - legacy behavior.
    /// </summary>
    internal static class ScannerSectionFilter
    {
        // matches a top-level SavedVariables table declaration: "Name = {"
        private static readonly Regex SectionHeaderRegex = new Regex(
            @"^([A-Za-z_][A-Za-z0-9_]*)\s*=\s*\{\s*$", RegexOptions.Compiled);

        public static IEnumerable<string> FilterCategoryLines(string[] lines, Func<string, bool> isRelevantSection)
        {
            if (!lines.Any(line => SectionHeaderRegex.IsMatch(line)))
                return lines;

            return Filter(lines, isRelevantSection);
        }

        private static IEnumerable<string> Filter(string[] lines, Func<string, bool> isRelevantSection)
        {
            var inRelevantSection = false;
            foreach (var line in lines)
            {
                var header = SectionHeaderRegex.Match(line);
                if (header.Success)
                {
                    inRelevantSection = isRelevantSection(header.Groups[1].Value);
                    continue;
                }

                // a top-level table always closes with "}" at column 0; nested closers are indented
                if (line.Length > 0 && line[0] == '}')
                {
                    inRelevantSection = false;
                    continue;
                }

                if (inRelevantSection)
                    yield return line;
            }
        }

        public static bool IsQuestSection(string tableName)
        {
            return tableName.Contains("QuestToolTips");
        }
    }
}
