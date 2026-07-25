using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using TextContentToolkit.Configs;
using TextContentToolkit.Readers;

namespace TextContentToolkit.Runtime
{
    internal static class ToolkitRunner
    {
        public static void Execute(RetrieverConfig config)
        {
            if (config == null)
            {
                throw new InvalidOperationException("RetrieverConfig cannot be null.");
            }

            var executionSteps = BuildExecutionSteps(config);
            if (!config.RunReaders && !config.RunQuestieFolders)
            {
                Console.WriteLine("No work requested (both RunReaders and RunQuestieFolders are false).");
                return;
            }

            if (config.RunReaders)
            {
                EnsureOutputDirectories(executionSteps);
                foreach (var step in executionSteps)
                {
                    RunStep(step.Name, step.Enabled, step.RunStandard);
                }
            }

            if (config.RunQuestieFolders)
            {
                EnsureQuestieDirectories(executionSteps);
                foreach (var step in executionSteps)
                {
                    RunStep(step.Name + " (Questie)", step.Enabled, step.RunQuestie);
                }
            }
        }

        private static List<ExecutionStep> BuildExecutionSteps(RetrieverConfig config)
        {
            return new List<ExecutionStep>
            {
                new ExecutionStep(
                    "Items",
                    config.ItemConfig.Enabled,
                    config.ItemConfig.OutputPath,
                    config.ItemConfig.QuestieDir,
                    () => new ItemReader(config.ItemConfig).Execute(),
                    () => new ItemReader(config.ItemConfig).ExecuteOnQuestieFolder()),

                new ExecutionStep(
                    "Achievements",
                    config.AchievementConfig.Enabled,
                    config.AchievementConfig.OutputPath,
                    config.AchievementConfig.QuestieDir,
                    () => new AchievementReader(config.AchievementConfig).Execute(),
                    null),

                new ExecutionStep(
                    "Spells",
                    config.SpellConfig.Enabled,
                    config.SpellConfig.OutputPath,
                    config.SpellConfig.QuestieDir,
                    () => new SpellReader(config.SpellConfig).Execute(),
                    null),

                new ExecutionStep(
                    "Units",
                    config.UnitConfig.Enabled,
                    config.UnitConfig.OutputPath,
                    config.UnitConfig.QuestieDir,
                    () => new UnitReader(config.UnitConfig).Execute(),
                    () => new UnitReader(config.UnitConfig).ExecuteOnQuestieFolder()),

                new ExecutionStep(
                    "Quests",
                    config.QuestConfig.Enabled,
                    config.QuestConfig.OutputPath,
                    config.QuestConfig.QuestieDir,
                    () => new QuestReader(config.QuestConfig).Execute(),
                    () => new QuestReader(config.QuestConfig).ExecuteOnQuestieFolder())
            };
        }

        private static void RunStep(string name, bool enabled, Action action)
        {
            if (!enabled)
            {
                Console.WriteLine("[skip] " + name);
                return;
            }

            if (action == null)
            {
                Console.WriteLine("[skip] " + name + " (not supported)");
                return;
            }

            Console.WriteLine("[run] " + name);
            action();
        }

        private static void EnsureOutputDirectories(IEnumerable<ExecutionStep> steps)
        {
            foreach (var step in steps.Where(s => s.Enabled))
            {
                if (string.IsNullOrWhiteSpace(step.OutputPath))
                {
                    throw new InvalidOperationException("Missing OutputPath for enabled step: " + step.Name);
                }

                var outputDirectory = Path.GetDirectoryName(step.OutputPath);
                if (!string.IsNullOrWhiteSpace(outputDirectory))
                {
                    Directory.CreateDirectory(outputDirectory);
                }
            }
        }

        private static void EnsureQuestieDirectories(IEnumerable<ExecutionStep> steps)
        {
            foreach (var step in steps.Where(s => s.Enabled && s.RunQuestie != null))
            {
                if (string.IsNullOrWhiteSpace(step.QuestieDirectory))
                {
                    throw new InvalidOperationException("Missing QuestieDir for enabled step: " + step.Name);
                }

                if (!Directory.Exists(step.QuestieDirectory))
                {
                    throw new DirectoryNotFoundException("QuestieDir not found for " + step.Name + ": " + step.QuestieDirectory);
                }

                Directory.CreateDirectory(Path.Combine(step.QuestieDirectory, "output"));
            }
        }
    }
}
