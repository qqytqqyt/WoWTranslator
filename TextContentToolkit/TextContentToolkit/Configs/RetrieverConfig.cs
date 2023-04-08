using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TextContentToolkit.Configs
{
    public class RetrieverConfig
    {
        public bool RunReaders { get; set; } = true;

        public bool RunQuestieFolders { get; set; } = false;

        public QuestConfig QuestConfig { get; set; }= new QuestConfig();

        public ItemConfig ItemConfig { get; set; } = new ItemConfig();

        public SpellConfig SpellConfig { get; set; } = new SpellConfig();

        public UnitConfig UnitConfig { get; set; } = new UnitConfig();

        public AchievementConfig AchievementConfig { get; set; } = new AchievementConfig();
    }
}
