using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using TextContentToolkit.Configs;
using TextContentToolkit.Models;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers
{
    public abstract class TooltipsReader
    {
        private static readonly Regex VersionRegex = new Regex(@"(?<!\d)(\d{4,})(?!\d)", RegexOptions.Compiled);
        private static readonly Regex OutputEntryRegex = new Regex("^\\s*\"(?<payload>.*)\",\\s*--(?<id>\\d+)\\s*$", RegexOptions.Compiled);
        private static readonly Regex SegmentRegex = new Regex(@"[._-](\d+)$", RegexOptions.Compiled);

        protected TooltipsConfig TooltipsConfig { get; set; }

        public void Execute()
        {
            var inputPaths = ResolveInputPaths();
            Write(TooltipsConfig.OutputPath, inputPaths, TooltipsConfig.OutputMode);
        }

        public void ExecuteOnQuestieFolder()
        {
            var dirInfo = new DirectoryInfo(TooltipsConfig.QuestieDir);

            foreach (var fileInfo in dirInfo.GetFiles("*.lua"))
            {
                var outputPath = Path.Combine(TooltipsConfig.QuestieDir, "output", fileInfo.Name);
                var inputPaths = new List<string> { fileInfo.FullName };
                var locale = fileInfo.Name.Split('.')[0];
                Write(outputPath, inputPaths, OutputMode.Questie, locale);
            }
        }

        protected void MergeFromBaselineOutput(string outputPath, Dictionary<string, Tooltip> tipsById)
        {
            if (!TooltipsConfig.UseOutputAsBaseline || string.IsNullOrWhiteSpace(outputPath) || !File.Exists(outputPath))
            {
                return;
            }

            foreach (var line in File.ReadLines(outputPath))
            {
                var match = OutputEntryRegex.Match(line);
                if (!match.Success)
                {
                    continue;
                }

                var id = match.Groups["id"].Value;
                var payload = match.Groups["payload"].Value;

                var tooltip = new Tooltip { Id = id };
                foreach (var tooltipLine in payload.Split(new[] { '£' }, StringSplitOptions.None))
                {
                    tooltip.TooltipLines.Add(new TooltipLine
                    {
                        Line = tooltipLine
                    });
                }

                tipsById[id] = tooltip;
            }
        }

        private List<string> ResolveInputPaths()
        {
            var configuredPaths = (TooltipsConfig.VersionMode == VersionMode.Retail
                    ? TooltipsConfig.ToolTipDataListRetail
                    : TooltipsConfig.ToolTipDataListClassic)
                .Where(path => !string.IsNullOrWhiteSpace(path))
                .Select(Path.GetFullPath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (!TooltipsConfig.AutoDetectLatestInputs)
            {
                return configuredPaths;
            }

            var autoDetectedPaths = ResolveLatestInputFiles(configuredPaths);
            return autoDetectedPaths.Any() ? autoDetectedPaths : configuredPaths;
        }

        private List<string> ResolveLatestInputFiles(List<string> configuredPaths)
        {
            var inputDirectory = ResolveInputDirectory(configuredPaths);
            if (string.IsNullOrWhiteSpace(inputDirectory) || !Directory.Exists(inputDirectory))
            {
                return new List<string>();
            }

            var pattern = string.IsNullOrWhiteSpace(TooltipsConfig.InputFilePattern)
                ? "*.lua"
                : TooltipsConfig.InputFilePattern;

            var outputFullPath = string.IsNullOrWhiteSpace(TooltipsConfig.OutputPath)
                ? string.Empty
                : Path.GetFullPath(TooltipsConfig.OutputPath);

            var filePrefix = ResolveFilePrefix(configuredPaths);
            var candidates = new List<DetectedInputFile>();

            foreach (var filePath in Directory.GetFiles(inputDirectory, pattern))
            {
                if (!string.IsNullOrWhiteSpace(outputFullPath) &&
                    filePath.Equals(outputFullPath, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var fileName = Path.GetFileName(filePath);
                if (fileName.IndexOf("_output_", StringComparison.OrdinalIgnoreCase) >= 0)
                {
                    continue;
                }

                if (!string.IsNullOrWhiteSpace(filePrefix) &&
                    !fileName.StartsWith(filePrefix, StringComparison.OrdinalIgnoreCase))
                {
                    continue;
                }

                var fileNameWithoutExt = Path.GetFileNameWithoutExtension(filePath);
                var versionMatches = VersionRegex.Matches(fileNameWithoutExt);
                if (versionMatches.Count == 0)
                {
                    continue;
                }

                int version;
                if (!int.TryParse(versionMatches[versionMatches.Count - 1].Value, out version))
                {
                    continue;
                }

                var segment = 0;
                var segmentMatch = SegmentRegex.Match(fileNameWithoutExt);
                if (segmentMatch.Success)
                {
                    int.TryParse(segmentMatch.Groups[1].Value, out segment);
                }

                candidates.Add(new DetectedInputFile
                {
                    Path = Path.GetFullPath(filePath),
                    Name = fileName,
                    Version = version,
                    Segment = segment
                });
            }

            if (!candidates.Any())
            {
                return new List<string>();
            }

            var latestVersion = candidates.Max(c => c.Version);
            return candidates
                .Where(c => c.Version == latestVersion)
                .OrderBy(c => c.Segment)
                .ThenBy(c => c.Name, StringComparer.OrdinalIgnoreCase)
                .Select(c => c.Path)
                .ToList();
        }

        private string ResolveInputDirectory(List<string> configuredPaths)
        {
            var configuredInputDirectory = TooltipsConfig.VersionMode == VersionMode.Retail
                ? TooltipsConfig.InputFolderRetail
                : TooltipsConfig.InputFolderClassic;

            if (!string.IsNullOrWhiteSpace(configuredInputDirectory))
            {
                return Path.GetFullPath(configuredInputDirectory);
            }

            var firstConfiguredPath = configuredPaths.FirstOrDefault();
            if (!string.IsNullOrWhiteSpace(firstConfiguredPath))
            {
                var configuredDirectory = Path.GetDirectoryName(firstConfiguredPath);
                if (!string.IsNullOrWhiteSpace(configuredDirectory))
                {
                    return configuredDirectory;
                }
            }

            if (string.IsNullOrWhiteSpace(TooltipsConfig.OutputPath))
            {
                return string.Empty;
            }

            return Path.GetDirectoryName(Path.GetFullPath(TooltipsConfig.OutputPath));
        }

        private string ResolveFilePrefix(List<string> configuredPaths)
        {
            if (!string.IsNullOrWhiteSpace(TooltipsConfig.OutputPath))
            {
                var outputName = Path.GetFileNameWithoutExtension(TooltipsConfig.OutputPath);
                var markerIndex = outputName.IndexOf("_output_", StringComparison.OrdinalIgnoreCase);
                if (markerIndex > 0)
                {
                    return outputName.Substring(0, markerIndex);
                }
            }

            var firstConfiguredPath = configuredPaths.FirstOrDefault();
            if (string.IsNullOrWhiteSpace(firstConfiguredPath))
            {
                return string.Empty;
            }

            var fileName = Path.GetFileNameWithoutExtension(firstConfiguredPath);
            var versionMatch = VersionRegex.Match(fileName);
            return versionMatch.Success
                ? fileName.Substring(0, versionMatch.Index)
                : fileName;
        }

        protected abstract void Write(string outputPath, List<string> inputPaths, OutputMode outputMode, string locale = "zhCN");

        private sealed class DetectedInputFile
        {
            public string Path { get; set; }

            public string Name { get; set; }

            public int Version { get; set; }

            public int Segment { get; set; }
        }
    }
}
