using System.Collections.Generic;
using System.Linq;
using System.Text.RegularExpressions;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers.Support
{
    internal static class TooltipTextFormatter
    {
        public static string ApplyGrayedOutNumbers(string line)
        {
            var updatedLine = line;
            foreach (var grayedOutIndicator in StringUtils.GrayedOutIndicatorText)
            {
                var matches = Regex.Matches(updatedLine, @"(\d+(,\d+)*)" + grayedOutIndicator).OfType<Match>().ToList();
                var orderedMatches = matches.OrderByDescending(m => m.Length);
                foreach (var match in orderedMatches)
                {
                    var result = "|cff7f7f7f" + match.Result("$1") + "|r";
                    updatedLine = updatedLine.Replace(match.Value, result + grayedOutIndicator);
                }
            }

            return updatedLine;
        }
    }
}
