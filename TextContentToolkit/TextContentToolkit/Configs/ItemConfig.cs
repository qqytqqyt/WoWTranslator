using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace QuestTextRetriever.Configs
{
    public class ItemConfig : TooltipsConfig
    {
        public ItemConfig()
        {
            OutputPath = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retails_items_output_48676.lua";
            QuestieDir = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\items";
            QuestieFilterPath =
                @"G:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\Questie\Database\Wotlk\wotlkItemDB.lua";

            ToolTipDataListRetail = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retail_items.46144.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retail_items.46802.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retail_items.47213.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retail_items.48001.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow\retail_items.48676.lua"
            };

            ToolTipDataListClassic = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow_classic\wlk_items_45166.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow_classic\wlk_items_45327.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow_classic\wlk_items_47612.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\items\wow_classic\wlk_items_47720.lua"
            };
        }
    }

    public class UnitConfig : TooltipsConfig
    {
        public UnitConfig()
        {
            OutputPath = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\units\wow\retail_units_output_48676.lua";
            QuestieDir = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\units";
            QuestieFilterPath =
                @"G:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\Questie\Database\Wotlk\wotlkItemDB.lua";

            ToolTipDataListRetail = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\units\wow\dragon_units_46144.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\units\wow\dragon_units_48676.lua"
            };

            ToolTipDataListClassic = new List<string>()
        }
    }

    public class SpellConfig : TooltipsConfig
    {
        public SpellConfig()
        {
            OutputPath = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_output_48676.lua";
            QuestieDir = @"G:\OneDrive\OwnProjects\WoWTranslator\Data\questie\WLK-input\items";
            QuestieFilterPath =
                @"G:\Games\World of Warcraft\_classic_beta_\Interface\AddOns\Questie\Database\Wotlk\wotlkItemDB.lua";

            ToolTipDataListRetail = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46144.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46144.1.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46144.2.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46658.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46658.1.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_46658.2.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_47213.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow\retail_spells_48676.lua"
        };

            ToolTipDataListClassic = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow_classic\wlk_spells_45166.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\spells\wow_classic\wlk_spells_47720.lua"
            };
        }
    }

    public class AchievementConfig : TooltipsConfig
    {
        public AchievementConfig()
        {
            OutputPath =
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow\retail_achievements_output_48676.lua";

            ToolTipDataListRetail = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow_classic\retails_achievements_47168.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow\retails_achievements_48001.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow\retails_achievements_48676.lua",
            };

            ToolTipDataListClassic = new List<string>
            {
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow_classic\wlk_achievements_47585.lua",
                @"G:\OneDrive\OwnProjects\WoWTranslator\Data\achievements\wow_classic\wlk_achievements_47612.lua",
            };
        }
    }
}
