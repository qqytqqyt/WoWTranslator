using System;
using System.Collections.Generic;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    /// <summary>
    /// Tokenizes one line of a scanner lua dump:
    ///   ["id"] = "{{line}}[[r]][[g]][[b]]{{line}}[[r]][[g]][[b]]...{{{type}}}"
    /// Shared by the item/spell/unit/achievement readers; per-category filtering of the
    /// tokenized entries stays in the readers.
    /// </summary>
    internal static class ScannerTooltipParser
    {
        internal sealed class RawRecord
        {
            public string Id;

            public string Type;

            /// <summary>False when the line has no "{{" body; the id still counts as seen.</summary>
            public bool HasBody;

            public List<RawEntry> Entries = new List<RawEntry>();
        }

        internal sealed class RawEntry
        {
            public string Line;

            public string R;

            public string G;

            public string B;
        }

        /// <param name="stripRedColorCodes">Remove |cffff2020/|cffff2121 red colour markup (and all |r
        /// resets in the remainder) before tokenizing each entry - historic spell/unit/achievement behavior.</param>
        /// <param name="hasTypeMarker">Stop at the trailing {{{type}}} marker and expose it as Type - item behavior.</param>
        public static RawRecord TryParse(string rawLine, bool stripRedColorCodes, bool hasTypeMarker)
        {
            var text = rawLine.Trim();
            if (string.IsNullOrEmpty(text) || !text.StartsWith("["))
                return null;

            var record = new RawRecord();
            record.Id = text.Split(new[] { "[\"" }, StringSplitOptions.None)[1]
                .Split(new[] { "\"]" }, StringSplitOptions.None)[0]
                .Trim();

            if (hasTypeMarker)
                record.Type = text.FirstBetween("{{{", "}}}");

            if (!text.Contains("{{"))
                return record;

            record.HasBody = true;
            text = text.Replace("]] \"", "]]\"").Replace("]]  \"", "]]\"");
            var textContent = text.Split(new[] { "= \"" }, StringSplitOptions.None)[1]
                .Split(new[] { "]]\"," }, StringSplitOptions.None)[0]
                .Trim() + "]]";

            while (!string.IsNullOrEmpty(textContent))
            {
                if (hasTypeMarker && textContent.TrimStart().StartsWith("{{{"))
                    break;

                textContent = textContent.TrimTextAfter("{{");

                if (stripRedColorCodes)
                {
                    if (textContent.Contains(@"|cffff2020"))
                        textContent = textContent.Replace(@"|cffff2020", string.Empty).Replace(@"|r", string.Empty);
                    if (textContent.Contains(@"|cffff2121"))
                        textContent = textContent.Replace(@"|cffff2121", string.Empty).Replace(@"|r", string.Empty);
                }

                var entry = new RawEntry();
                entry.Line = textContent.GetTextBefore("}}");
                textContent = textContent.TrimTextAfter("[[");
                entry.R = textContent.GetTextBefore("]]");
                textContent = textContent.TrimTextAfter("[[");
                entry.G = textContent.GetTextBefore("]]");
                textContent = textContent.TrimTextAfter("[[");
                entry.B = textContent.GetTextBefore("]]");
                textContent = textContent.TrimTextAfter("]]");

                record.Entries.Add(entry);
            }

            return record;
        }
    }
}
