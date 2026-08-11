using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;

namespace TextContentToolkit.Pipeline
{
    internal enum DataFileKind
    {
        NewInput,
        ParsedInput,
        Output,
        Ignored
    }

    internal sealed class DataFile
    {
        public string Path { get; set; }

        public string Name { get; set; }

        public DataFileKind Kind { get; set; }

        public int Build { get; set; }

        public int Segment { get; set; }

        public bool IsWdb { get; set; }

        public DateTime LastWriteTime { get; set; }
    }

    /// <summary>
    /// Classifies the files of one data folder purely by extension and name:
    ///  - not .lua/.wdb            -> Ignored
    ///  - name contains ".parsed." -> ParsedInput (already merged into an output, skipped)
    ///  - name contains "output"   -> Output (the latest build is the merge baseline)
    ///  - anything else            -> NewInput (will be parsed, then renamed to *.parsed.*)
    /// A build number in the name is optional; it only drives input ordering and the
    /// output file name.
    /// </summary>
    internal static class DataFileClassifier
    {
        private static readonly Regex BuildRegex = new Regex(@"(?<!\d)(\d{4,6})(?!\d)", RegexOptions.Compiled);
        private static readonly Regex SegmentRegex = new Regex(@"^[._-](\d{1,3})(?!\d)", RegexOptions.Compiled);

        public static List<DataFile> Classify(string directory)
        {
            var result = new List<DataFile>();
            foreach (var filePath in Directory.GetFiles(directory))
            {
                var file = ClassifyFile(filePath);
                if (file != null)
                    result.Add(file);
            }

            return result;
        }

        public static DataFile ClassifyFile(string filePath)
        {
            var name = Path.GetFileName(filePath);
            var extension = Path.GetExtension(name);
            var isWdb = extension.Equals(".wdb", StringComparison.OrdinalIgnoreCase);
            var isLua = extension.Equals(".lua", StringComparison.OrdinalIgnoreCase);

            var file = new DataFile
            {
                Path = Path.GetFullPath(filePath),
                Name = name,
                IsWdb = isWdb,
                Kind = DataFileKind.Ignored,
                LastWriteTime = File.GetLastWriteTimeUtc(filePath)
            };

            if (!isWdb && !isLua)
                return file;

            var nameWithoutExtension = Path.GetFileNameWithoutExtension(name);
            var buildMatches = BuildRegex.Matches(nameWithoutExtension);
            if (buildMatches.Count > 0)
            {
                var lastMatch = buildMatches[buildMatches.Count - 1];
                file.Build = int.Parse(lastMatch.Value);

                // A short trailing number after the build ("xxx_52212.1", "xxx_52038_2") is a
                // segment counter used when one build was scanned into multiple files.
                var afterBuild = nameWithoutExtension.Substring(lastMatch.Index + lastMatch.Length);
                var segmentMatch = SegmentRegex.Match(afterBuild);
                if (segmentMatch.Success)
                    file.Segment = int.Parse(segmentMatch.Groups[1].Value);
            }

            if (name.IndexOf(".parsed.", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                file.Kind = DataFileKind.ParsedInput;
                return file;
            }

            if (name.IndexOf("output", StringComparison.OrdinalIgnoreCase) >= 0)
            {
                file.Kind = DataFileKind.Output;
                return file;
            }

            file.Kind = DataFileKind.NewInput;
            return file;
        }

        /// <summary>Returns the .parsed.* name for an input file ("a.68256.lua" -> "a.68256.parsed.lua").</summary>
        public static string GetParsedPath(string filePath)
        {
            var directory = Path.GetDirectoryName(filePath);
            var nameWithoutExtension = Path.GetFileNameWithoutExtension(filePath);
            var extension = Path.GetExtension(filePath);

            var candidate = Path.Combine(directory, nameWithoutExtension + ".parsed" + extension);
            var counter = 2;
            while (File.Exists(candidate))
            {
                candidate = Path.Combine(directory, nameWithoutExtension + ".parsed." + counter + extension);
                counter++;
            }

            return candidate;
        }

        /// <summary>
        /// Parse order (later files win merge conflicts): build, then segment, then file
        /// timestamp - so for free-form names without a build number the newest scan wins.
        /// </summary>
        public static List<DataFile> SortInputs(IEnumerable<DataFile> inputs)
        {
            return inputs
                .OrderBy(f => f.Build)
                .ThenBy(f => f.Segment)
                .ThenBy(f => f.LastWriteTime)
                .ThenBy(f => f.Name, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public static DataFile FindBaseline(IEnumerable<DataFile> files)
        {
            return files
                .Where(f => f.Kind == DataFileKind.Output && !f.IsWdb)
                .OrderByDescending(f => f.Build)
                .ThenByDescending(f => f.Segment)
                .ThenByDescending(f => f.Name, StringComparer.OrdinalIgnoreCase)
                .FirstOrDefault();
        }
    }
}
