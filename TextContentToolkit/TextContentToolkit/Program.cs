using System;
using TextContentToolkit.Pipeline;

namespace TextContentToolkit
{
    internal class Program
    {
        private static void Main(string[] args)
        {
            var options = ToolkitOptions.Parse(args);

            if (options.ShowHelp)
            {
                ToolkitOptions.PrintHelp();
                return;
            }

            if (options.Error != null)
            {
                Console.WriteLine(options.Error);
                Console.WriteLine();
                ToolkitOptions.PrintHelp();
                Environment.ExitCode = 1;
                return;
            }

            if (!string.IsNullOrEmpty(options.QuestieDir))
            {
                QuestieRunner.Run(options.QuestieDir);
                return;
            }

            DataPipeline.Run(options);
        }
    }
}
