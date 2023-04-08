using System;
using System.Collections.Generic;

namespace TextContentToolkit.Utils
{
    public static class StringUtils
    {
        public static readonly List<string> GrayedOutIndicatorText = new List<string>
        {
            "点伤害",
            "点治疗",
            "点生命值",
            "点法力值",
            "点物理伤害",
            "点魔法伤害",
            "点火焰伤害",
            "点冰霜伤害",
            "点暗影伤害",
            "点自然伤害",
            "点神圣伤害",
            "点奥术伤害",
            "点混乱伤害",
            "点流血伤害",
        };

        public static string TrimTextAfter(this string textContent, string separator)
        {
            if (!textContent.Contains(separator))
                return textContent;

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
