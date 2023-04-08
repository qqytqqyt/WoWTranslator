using System.Collections.Generic;
using System.Linq;

namespace TextContentToolkit.Models
{
    public class Tooltip
    {
        public string Id;

        public List<TooltipLine> TooltipLines { get; set; } = new List<TooltipLine>();

        public string Type;
    }

    public class TooltipLine
    {
        public string Line { get; set; }

        public double R { get; set; } = 1;

        public double G { get; set; } = 1;

        public double B { get; set; } = 1;
    }

    public static class TooltipExtension
    {
        public static bool HasChinese(this string text)
        {
            return text.Any(c => c >= 512);
        }
    }

}
