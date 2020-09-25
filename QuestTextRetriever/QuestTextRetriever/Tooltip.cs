using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestTextRetriever
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

}
