using System.Collections.Generic;
using System.Xml.Serialization;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Configs
{
    public class QuestConfig
    {
        public bool Enabled { get; set; }

        public string JsonDirPath { get; set; }

        public string TemplatePath { get; set; }

        public string OutputPath { get; set; }

        public VersionMode VersionMode { get; set; } = VersionMode.Retail;

        public OutputMode OutputMode { get; set; } = OutputMode.WoWeuCN;

        public string QuestieDir { get; set; }

        public string QuestieFilterPath { get; set; }

        [XmlArray("FileMergeList")]
        [XmlArrayItem("DataPath")]
        public List<string> FileMergeList { get; set; } = new List<string>();

        [XmlArray("QuestObjectiveListRetail")]
        [XmlArrayItem("DataPath")]
        public List<string> QuestObjectiveListRetail { get; set; } = new List<string>();

        [XmlArray("QuestObjectiveListClassic")]
        [XmlArrayItem("DataPath")]
        public List<string> QuestObjectiveListClassic { get; set; } = new List<string>();

        [XmlArray("QuestCacheListRetail")]
        [XmlArrayItem("DataPath")]
        public List<string> QuestCacheListRetail { get; set; } = new List<string>();

        [XmlArray("QuestCacheListClassic")]
        [XmlArrayItem("DataPath")]
        public List<string> QuestCacheListClassic { get; set; } = new List<string>();
    }
}
