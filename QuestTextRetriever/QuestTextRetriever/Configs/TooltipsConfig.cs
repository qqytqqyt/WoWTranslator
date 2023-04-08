using System.Collections.Generic;
using System.Xml.Serialization;
using QuestTextRetriever.Utils;

namespace QuestTextRetriever.Configs
{
    public class TooltipsConfig
    {
        public string OutputPath { get; set; }

        public OutputMode OutputMode { get; set; } = OutputMode.WoWeuCN;

        public string QuestieDir { get; set; }

        public VersionMode VersionMode { get; set; } = VersionMode.Retail;

        public string QuestieFilterPath { get; set; }

        [XmlArray("ToolTipDataListRetail")]
        [XmlArrayItem("DataPath")]
        public List<string> ToolTipDataListRetail { get; set; } = new List<string>();

        [XmlArray("ToolTipDataListClassic")]
        [XmlArrayItem("DataPath")]
        public List<string> ToolTipDataListClassic { get; set; } = new List<string>();
    }

    public class ItemConfig : TooltipsConfig { }

    public class UnitConfig : TooltipsConfig { }

    public class SpellConfig : TooltipsConfig { }

    public class AchievementConfig : TooltipsConfig { }
}
