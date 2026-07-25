using System;

namespace TextContentToolkit.Runtime
{
    internal sealed class ExecutionStep
    {
        public ExecutionStep(string name, bool enabled, string outputPath, string questieDirectory, Action runStandard, Action runQuestie)
        {
            Name = name;
            Enabled = enabled;
            OutputPath = outputPath;
            QuestieDirectory = questieDirectory;
            RunStandard = runStandard;
            RunQuestie = runQuestie;
        }

        public string Name { get; }

        public bool Enabled { get; }

        public string OutputPath { get; }

        public string QuestieDirectory { get; }

        public Action RunStandard { get; }

        public Action RunQuestie { get; }
    }
}
