using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestTextRetriever
{
    public class Quest
    {
        public string Id { get; set; }

        public string Title { get; set; }

        public string Objectives { get; set; }

        public string Description { get; set; }

        public string Progress { get; set; }

        public string Completion { get; set; }

        public string Translator { get; set; }
    }
}
