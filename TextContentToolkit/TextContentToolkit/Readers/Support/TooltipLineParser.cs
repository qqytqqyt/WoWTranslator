using System;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers.Support
{
    internal sealed class TooltipSourceLine
    {
        public TooltipSourceLine(string line, string r, string g, string b)
        {
            Line = line;
            R = r;
            G = g;
            B = b;
        }

        public string Line { get; }

        public string R { get; }

        public string G { get; }

        public string B { get; }
    }

    internal static class TooltipLineParser
    {
        public static bool TryParseEntry(string line, out string id, out string type, out string textContent, bool skipDnd = false)
        {
            id = string.Empty;
            type = string.Empty;
            textContent = string.Empty;

            var text = line?.Trim();
            if (string.IsNullOrEmpty(text) || !text.StartsWith("[") || (skipDnd && text.Contains("DND")))
            {
                return false;
            }

            id = text.FirstBetween("[\"", "\"]").Trim();
            if (string.IsNullOrEmpty(id))
            {
                return false;
            }

            type = text.FirstBetween("{{{", "}}}");
            if (!text.Contains("{{"))
            {
                return false;
            }

            text = text.Replace("]] \"", "]]\"").Replace("]]  \"", "]]\"");
            var valueSegments = text.Split(new[] { "= \"" }, StringSplitOptions.None);
            if (valueSegments.Length < 2)
            {
                return false;
            }

            textContent = valueSegments[1]
                .Split(new[] { "]]\"," }, StringSplitOptions.None)[0]
                .Trim() + "]]";

            return true;
        }

        public static bool TryReadNextLine(ref string textContent, out TooltipSourceLine tooltipLine)
        {
            tooltipLine = null;
            if (string.IsNullOrEmpty(textContent))
            {
                return false;
            }

            textContent = textContent.TrimTextAfter("{{");

            if (string.IsNullOrEmpty(textContent))
            {
                return false;
            }

            var line = textContent.GetTextBefore("}}");
            textContent = textContent.TrimTextAfter("[[");
            var r = textContent.GetTextBefore("]]");
            textContent = textContent.TrimTextAfter("[[");
            var g = textContent.GetTextBefore("]]");
            textContent = textContent.TrimTextAfter("[[");
            var b = textContent.GetTextBefore("]]");
            textContent = textContent.TrimTextAfter("]]");

            tooltipLine = new TooltipSourceLine(line, r, g, b);
            return true;
        }

        public static string RemoveRedColorCodes(string textContent)
        {
            var updated = textContent;
            if (updated.Contains(@"|cffff2020"))
            {
                updated = updated.Replace(@"|cffff2020", string.Empty).Replace(@"|r", string.Empty);
            }

            if (updated.Contains(@"|cffff2121"))
            {
                updated = updated.Replace(@"|cffff2121", string.Empty).Replace(@"|r", string.Empty);
            }

            return updated;
        }

        public static bool IsRedText(string r, string g, string b)
        {
            return (r == "0.99999779462814" && g == "0.12548992037773" && b == "0.12548992037773")
                   || (r == "1" && g == "0.12549020349979" && b == "0.12549020349979");
        }
    }
}
