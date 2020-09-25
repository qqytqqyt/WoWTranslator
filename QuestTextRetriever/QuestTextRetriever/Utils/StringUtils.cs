using System;

namespace QuestTextRetriever.Utils
{
    public static class StringUtils
    {

        public static string TrimTextAfter(this string textContent, string separator)
        {
            var content = textContent.Split(new string[] { separator }, StringSplitOptions.None)[0];
            return textContent.Substring(content.Length + separator.Length);
        }

        public static string FirstBetween(this string textContent, string start, string end)
        {
            if (!textContent.Contains(start))
                return string.Empty;

            return textContent.Split(new string[] { start }, StringSplitOptions.None)[1].Split(new string[] { end }, StringSplitOptions.None)[0];
        }

        public static string GetTextBefore(this string textContent, string end)
        {
            return textContent.Split(new [] { end }, StringSplitOptions.None)[0];
        }
    }
}
