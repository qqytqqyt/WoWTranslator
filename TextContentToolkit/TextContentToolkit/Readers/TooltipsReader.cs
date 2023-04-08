using System;
using System.Collections.Generic;
using System.Diagnostics.Eventing;
using System.IO;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using TextContentToolkit.Configs;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    public abstract class TooltipsReader
    {
        protected TooltipsConfig TooltipsConfig { get; set; }

        public void Execute()
        {
            Write(TooltipsConfig.OutputPath, TooltipsConfig.VersionMode == VersionMode.Retail ? TooltipsConfig.ToolTipDataListRetail : TooltipsConfig.ToolTipDataListClassic, TooltipsConfig.OutputMode);
        }

        public void ExecuteOnQuestieFolder()
        {
            var dirInfo = new DirectoryInfo(TooltipsConfig.QuestieDir);

            foreach (var fileInfo in dirInfo.GetFiles("*.lua"))
            {
                var outputPath = Path.Combine(TooltipsConfig.QuestieDir, "output", fileInfo.Name);

                var inputPaths = new List<string>();
                inputPaths.Add(fileInfo.FullName);
                var locale = fileInfo.Name.Split('.')[0];
                Write(outputPath, inputPaths, OutputMode.Questie, locale);
            }
        }

        protected abstract void Write(string outputPath, List<string> inputPaths, OutputMode outputMode, string locale = "zhCN");
    }
}
