using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using TextContentToolkit.Readers;

namespace TextContentToolkit.Pipeline
{
    /// <summary>
    /// Convention driven pipeline: for every Data/&lt;category&gt;/&lt;variant&gt; folder, finds new
    /// input files by name, merges them on top of the latest output (new data wins) and
    /// renames the consumed inputs to *.parsed.* so the next run skips them.
    /// </summary>
    internal static class DataPipeline
    {
        public static void Run(ToolkitOptions options)
        {
            Console.WriteLine("Data root: " + options.DataRoot + (options.DryRun ? "  (dry run)" : string.Empty));

            foreach (var category in ToolkitOptions.AllCategories)
            {
                if (!options.Categories.Contains(category))
                    continue;

                var categoryDir = Path.Combine(options.DataRoot, category);
                if (!Directory.Exists(categoryDir))
                {
                    Console.WriteLine("[skip] " + category + ": folder not found");
                    continue;
                }

                foreach (var variantDir in Directory.GetDirectories(categoryDir).OrderBy(d => d))
                {
                    var variantName = Path.GetFileName(variantDir);
                    if (variantName.StartsWith("_") || variantName.Equals("output", StringComparison.OrdinalIgnoreCase))
                        continue;

                    try
                    {
                        ProcessFolder(category, variantDir, options);
                    }
                    catch (Exception e)
                    {
                        Console.WriteLine("[error] " + category + "/" + variantName + ": " + e.Message);
                        Console.WriteLine("        Inputs were NOT renamed; fix the problem and re-run.");
                    }
                }
            }
        }

        private static void ProcessFolder(string category, string folder, ToolkitOptions options)
        {
            var label = category + "/" + Path.GetFileName(folder);
            var files = DataFileClassifier.Classify(folder);
            var candidates = files.Where(f => f.Kind == DataFileKind.NewInput).ToList();

            // only the quest pipeline understands .wdb caches
            if (category != "quests")
            {
                foreach (var wdb in candidates.Where(f => f.IsWdb))
                    Console.WriteLine("[warn] " + label + ": ignoring " + wdb.Name + " (.wdb is only used for quests)");

                candidates = candidates.Where(f => !f.IsWdb).ToList();
            }

            var newInputs = DataFileClassifier.SortInputs(candidates);

            if (newInputs.Count == 0)
            {
                Console.WriteLine("[skip] " + label + ": no new inputs");
                return;
            }

            var baseline = DataFileClassifier.FindBaseline(files);
            var outputBuild = Math.Max(newInputs.Max(f => f.Build), baseline != null ? baseline.Build : 0);
            var outputPath = Path.Combine(folder,
                outputBuild > 0 ? category + "_output_" + outputBuild + ".lua" : category + "_output.lua");

            if (options.MarkParsedOnly)
            {
                Console.WriteLine("[mark] " + label);
                foreach (var input in newInputs)
                {
                    if (options.DryRun)
                    {
                        Console.WriteLine("       would mark: " + input.Name);
                        continue;
                    }

                    var markedPath = DataFileClassifier.GetParsedPath(input.Path);
                    File.Move(input.Path, markedPath);
                    Console.WriteLine("       marked:   " + input.Name + " -> " + Path.GetFileName(markedPath));
                }

                return;
            }

            Console.WriteLine("[run]  " + label);
            foreach (var input in newInputs)
                Console.WriteLine("       input:    " + input.Name);
            Console.WriteLine("       baseline: " + (baseline != null ? baseline.Name : "(none)"));
            Console.WriteLine("       output:   " + Path.GetFileName(outputPath));

            if (options.DryRun)
                return;

            if (category == "quests")
            {
                var objectivePaths = newInputs.Where(f => !f.IsWdb).Select(f => f.Path).ToList();
                var cachePaths = newInputs.Where(f => f.IsWdb).Select(f => f.Path).ToList();
                new QuestReader().Execute(objectivePaths, cachePaths, baseline != null ? baseline.Path : null, outputPath);
            }
            else
            {
                var reader = CreateTooltipsReader(category);
                var inputPaths = newInputs.Select(f => f.Path).ToList();
                reader.Execute(inputPaths, baseline != null ? baseline.Path : null, outputPath);
            }

            foreach (var input in newInputs)
            {
                var parsedPath = DataFileClassifier.GetParsedPath(input.Path);
                File.Move(input.Path, parsedPath);
                Console.WriteLine("       renamed:  " + input.Name + " -> " + Path.GetFileName(parsedPath));
            }
        }

        private static TooltipsReader CreateTooltipsReader(string category)
        {
            switch (category)
            {
                case "items":
                    return new ItemReader();
                case "spells":
                    return new SpellReader();
                case "units":
                    return new UnitReader();
                case "achievements":
                    return new AchievementReader();
                default:
                    throw new InvalidOperationException("No reader for category: " + category);
            }
        }
    }
}
