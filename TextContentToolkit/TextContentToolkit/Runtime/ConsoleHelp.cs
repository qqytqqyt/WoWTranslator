using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace TextContentToolkit.Runtime
{
    internal static class ConsoleHelp
    {
        public static void PrintUsage()
        {
            Console.WriteLine("TextContentToolkit usage:");
            Console.WriteLine("  TextContentToolkit.exe [--config <path> | --profile <name>] [--list-configs] [--help]");
            Console.WriteLine("Options:");
            Console.WriteLine("  --config, -c       Use a specific config XML file.");
            Console.WriteLine("  --profile, -p      Resolve config by profile name (example: classic -> ConfigClassic.xml).");
            Console.WriteLine("  --list-configs     List discovered config files.");
            Console.WriteLine("  --help, -h, /?     Show this help message.");
        }

        public static void PrintAvailableConfigs(IEnumerable<string> configFiles)
        {
            var files = configFiles.ToList();
            if (!files.Any())
            {
                Console.WriteLine("No config files found.");
                return;
            }

            Console.WriteLine("Available config files:");
            foreach (var file in files)
            {
                Console.WriteLine("  " + Path.GetFileName(file) + " -> " + file);
            }
        }
    }
}
