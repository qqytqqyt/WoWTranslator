using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TextContentToolkit.Models
{
    public class Script
    {
        public string NpcId { get; set; }

        public string NameEN { get; set; }

        public string NameCN { get; set; }

        public List<string> ScriptListCN { get; set; } = new List<string>();

        public List<string> ScriptListEN { get; set; } = new List<string>();
    }

    public class ScriptObject
    {
        public long Hash { get; set; }

        public string Text { get; set; }
    }

    public class SimpleScriptObject
    {
        public string ScriptId { get; set; }

        public string TextEN { get; set; }

        public string TextCN { get; set; }

        public bool UseEmote { get; set; }
    }
}
