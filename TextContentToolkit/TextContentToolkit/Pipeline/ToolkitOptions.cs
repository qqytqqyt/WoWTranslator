using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace TextContentToolkit.Pipeline
{
    internal sealed class ToolkitOptions
    {
        public static readonly string[] AllCategories = { "quests", "items", "spells", "units", "achievements" };

        public string DataRoot { get; set; }

        public bool DryRun { get; set; }

        public bool MarkParsedOnly { get; set; }

        public List<string> Categories { get; set; } = new List<string>(AllCategories);

        public string QuestieDir { get; set; }

        public bool ShowHelp { get; set; }

        public string Error { get; set; }

        public static ToolkitOptions Parse(string[] args)
        {
            var options = new ToolkitOptions();

            for (var i = 0; i < args.Length; i++)
            {
                var arg = args[i];
                switch (arg.ToLowerInvariant())
                {
                    case "-h":
                    case "--help":
                    case "/?":
                        options.ShowHelp = true;
                        return options;

                    case "--dry-run":
                    case "-n":
                        options.DryRun = true;
                        break;

                    case "--mark-parsed":
                        options.MarkParsedOnly = true;
                        break;

                    case "--data":
                        if (i + 1 >= args.Length)
                        {
                            options.Error = "--data requires a path argument.";
                            return options;
                        }

                        options.DataRoot = args[++i];
                        break;

                    case "--categories":
                    case "--category":
                        if (i + 1 >= args.Length)
                        {
                            options.Error = "--categories requires a comma separated list (e.g. items,spells).";
                            return options;
                        }

                        options.Categories = args[++i]
                            .Split(new[] { ',' }, StringSplitOptions.RemoveEmptyEntries)
                            .Select(c => c.Trim().ToLowerInvariant())
                            .ToList();

                        var unknown = options.Categories.FirstOrDefault(c => !AllCategories.Contains(c));
                        if (unknown != null)
                        {
                            options.Error = "Unknown category: " + unknown + " (valid: " + string.Join(",", AllCategories) + ")";
                            return options;
                        }

                        break;

                    case "--questie":
                        if (i + 1 >= args.Length)
                        {
                            options.Error = "--questie requires a folder path argument.";
                            return options;
                        }

                        options.QuestieDir = args[++i];
                        break;

                    default:
                        options.Error = "Unknown argument: " + arg;
                        return options;
                }
            }

            if (string.IsNullOrEmpty(options.DataRoot))
                options.DataRoot = LocateDataRoot();

            if (string.IsNullOrEmpty(options.DataRoot))
            {
                options.Error = "Could not locate the Data folder. Pass it explicitly with --data <path>.";
                return options;
            }

            if (!Directory.Exists(options.DataRoot))
            {
                options.Error = "Data folder does not exist: " + options.DataRoot;
                return options;
            }

            options.DataRoot = Path.GetFullPath(options.DataRoot);
            return options;
        }

        /// <summary>
        /// Walks up from the exe location and the current directory looking for a "Data"
        /// folder that contains at least one of the known category folders.
        /// </summary>
        private static string LocateDataRoot()
        {
            var startingPoints = new[]
            {
                AppDomain.CurrentDomain.BaseDirectory,
                Directory.GetCurrentDirectory()
            };

            foreach (var start in startingPoints)
            {
                var current = new DirectoryInfo(start);
                while (current != null)
                {
                    var candidate = Path.Combine(current.FullName, "Data");
                    if (Directory.Exists(candidate) &&
                        AllCategories.Any(category => Directory.Exists(Path.Combine(candidate, category))))
                    {
                        return candidate;
                    }

                    current = current.Parent;
                }
            }

            return null;
        }

        public static void PrintHelp()
        {
            Console.WriteLine("TextContentToolkit - convention driven parser for WoW scanner data.");
            Console.WriteLine();
            Console.WriteLine("Usage: TextContentToolkit [options]");
            Console.WriteLine();
            Console.WriteLine("Scans Data/<category>/<variant>/ folders (categories: " + string.Join(", ", AllCategories) + ").");
            Console.WriteLine("Any .lua/.wdb file with a build number in its name that is not an output and not");
            Console.WriteLine("yet marked '.parsed.' is treated as new input. New inputs are merged on top of the");
            Console.WriteLine("latest '*output*' file of the folder (new data wins) into <category>_output_<build>.lua,");
            Console.WriteLine("then renamed to *.parsed.* so the next run skips them.");
            Console.WriteLine();
            Console.WriteLine("Options:");
            Console.WriteLine("  --data <path>          Data root folder (default: auto-detected by walking up).");
            Console.WriteLine("  --dry-run, -n          Show what would be parsed/written/renamed, change nothing.");
            Console.WriteLine("  --mark-parsed          Only rename all new inputs to *.parsed.* without parsing");
            Console.WriteLine("                         (migration helper when outputs already contain their data).");
            Console.WriteLine("  --categories <list>    Only process these categories, e.g. items,spells.");
            Console.WriteLine("  --questie <folder>     Legacy mode: generate Questie locale files from <folder>/*.lua.");
            Console.WriteLine("  --help                 Show this help.");
        }
    }
}
