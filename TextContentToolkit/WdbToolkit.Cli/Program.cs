using System.Text;
using System.Text.Json;
using WdbToolkit;

namespace WdbToolkit.Cli;

/// <summary>
/// Diagnostic tool for WoW quest cache (questcache.wdb) files.
///
///   wdbtool analyze &lt;file.wdb&gt; [--corpus titles.lua] [--samples N] [--failures N]
///   wdbtool export  &lt;file.wdb&gt; --out out.json [--corpus titles.lua]
///   wdbtool batch   &lt;directory&gt; [--corpus-dir dir] [--recurse]
/// </summary>
public static class Program
{
    public static int Main(string[] args)
    {
        Console.OutputEncoding = Encoding.UTF8;

        if (args.Length < 2)
        {
            PrintUsage();
            return 1;
        }

        var command = args[0].ToLowerInvariant();
        var target = args[1];
        var options = ParseFlags(args.Skip(2).ToArray());

        try
        {
            switch (command)
            {
                case "analyze":
                    return Analyze(target, options);
                case "export":
                    return Export(target, options);
                case "batch":
                    return Batch(target, options);
                default:
                    PrintUsage();
                    return 1;
            }
        }
        catch (QuestCacheFormatException ex)
        {
            Console.Error.WriteLine("FORMAT ERROR: " + ex.Message);
            return 2;
        }
    }

    private static int Analyze(string wdbPath, Dictionary<string, string> options)
    {
        var result = Parse(wdbPath, options);
        Console.WriteLine(result.BuildSummary());

        var samples = GetInt(options, "samples", 3);
        foreach (var quest in result.Quests.Take(samples))
        {
            Console.WriteLine($"  [{quest.Id}] {quest.LogTitle}  (offset={quest.StringHeaderOffset}, trailing={quest.TrailingSize}, {quest.Strategy})");
            if (quest.LogDescription.Length > 0)
                Console.WriteLine($"    objectives: {Truncate(quest.LogDescription, 80)}");
            if (quest.QuestDescription.Length > 0)
                Console.WriteLine($"    description: {Truncate(quest.QuestDescription, 80)}");
            if (quest.QuestCompletionLog.Length > 0)
                Console.WriteLine($"    completion: {Truncate(quest.QuestCompletionLog, 80)}");
        }

        var failureCount = GetInt(options, "failures", 10);
        foreach (var failure in result.Failures.Take(failureCount))
            Console.WriteLine($"  FAIL [{failure.Id}] len={failure.PayloadLength}: {failure.Reason}");
        if (result.Failures.Count > failureCount)
            Console.WriteLine($"  ... and {result.Failures.Count - failureCount} more failures");

        var mismatches = result.Quests.Where(q => q.MatchesCorpus == false).Take(5).ToList();
        foreach (var quest in mismatches)
            Console.WriteLine($"  CORPUS MISMATCH [{quest.Id}]: cache='{quest.LogTitle}'");

        return result.Stats.Failed == 0 ? 0 : 3;
    }

    private static int Export(string wdbPath, Dictionary<string, string> options)
    {
        if (!options.TryGetValue("out", out var outPath))
        {
            Console.Error.WriteLine("export requires --out <file.json>");
            return 1;
        }

        var result = Parse(wdbPath, options);
        var payload = new
        {
            file = result.FilePath,
            header = new
            {
                signature = result.Header.Signature,
                build = result.Header.ClientBuild,
                locale = result.Header.Locale,
                cacheVersion = result.Header.CacheVersion,
            },
            layout = result.Layout.Describe(),
            stats = new
            {
                total = result.Stats.TotalRecords,
                parsed = result.Stats.Parsed,
                failed = result.Stats.Failed,
                corpusMatched = result.Stats.CorpusMatched,
                corpusMismatched = result.Stats.CorpusMismatched,
            },
            quests = result.Quests.Select(q => new
            {
                id = q.Id,
                title = q.LogTitle,
                objectives = q.LogDescription,
                description = q.QuestDescription,
                completion = q.QuestCompletionLog,
                area = q.AreaDescription,
                portraitGiverText = q.PortraitGiverText,
                portraitGiverName = q.PortraitGiverName,
                portraitTurnInText = q.PortraitTurnInText,
                portraitTurnInName = q.PortraitTurnInName,
            }),
            failures = result.Failures.Select(f => new { id = f.Id, reason = f.Reason }),
        };

        File.WriteAllText(outPath, JsonSerializer.Serialize(payload, new JsonSerializerOptions
        {
            WriteIndented = true,
            Encoder = System.Text.Encodings.Web.JavaScriptEncoder.UnsafeRelaxedJsonEscaping,
        }));

        Console.WriteLine(result.BuildSummary());
        Console.WriteLine($"exported {result.Quests.Count} quests to {outPath}");
        return 0;
    }

    private static int Batch(string directory, Dictionary<string, string> options)
    {
        var pattern = options.TryGetValue("pattern", out var p) ? p : "*.wdb";
        var searchOption = options.ContainsKey("recurse") ? SearchOption.AllDirectories : SearchOption.TopDirectoryOnly;
        var files = Directory.GetFiles(directory, pattern, searchOption).OrderBy(f => f).ToList();
        options.TryGetValue("corpus-dir", out var corpusDir);

        Console.WriteLine($"{"file",-42} {"build",7} {"records",8} {"parsed",8} {"failed",7} {"match",7} {"layout"}");
        var anyFailed = false;

        foreach (var file in files)
        {
            try
            {
                var corpus = corpusDir != null ? FindCorpusFor(file, corpusDir) : null;
                var result = Parse(file, corpus, options.ContainsKey("trace"));
                var matchRate = result.Stats.CorpusEntries == 0
                    ? "-"
                    : $"{100.0 * result.Stats.CorpusMatched / Math.Max(1, result.Stats.CorpusMatched + result.Stats.CorpusMismatched):F1}%";

                var position = result.Layout.Mode == QuestCacheLayoutMode.HeaderBeforeStrings
                    ? "F=preStrings"
                    : $"F={result.Layout.BaseStringHeaderOffset}{(result.Layout.HasHeaderOffsetDrift ? "+4n" : "")}";

                Console.WriteLine(
                    $"{Path.GetFileName(file),-42} {result.Header.ClientBuild,7} {result.Stats.TotalRecords,8} " +
                    $"{result.Stats.Parsed,8} {result.Stats.Failed,7} {matchRate,7} " +
                    $"{position} t={result.Layout.TrailingSize} conf={result.Layout.Confidence:P0} " +
                    $"verified={result.Layout.VerificationRate:P0}" +
                    (corpus != null ? $" corpus={Path.GetFileName(corpus)}" : ""));

                if (result.Stats.Failed > 0)
                    anyFailed = true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"{Path.GetFileName(file),-42} ERROR: {ex.Message}");
                anyFailed = true;
            }
        }

        return anyFailed ? 3 : 0;
    }

    private static QuestCacheParseResult Parse(string wdbPath, Dictionary<string, string> options)
    {
        options.TryGetValue("corpus", out var corpusPath);
        return Parse(wdbPath, corpusPath, options.ContainsKey("trace"));
    }

    private static QuestCacheParseResult Parse(string wdbPath, string corpusPath, bool trace = false)
    {
        var parseOptions = new QuestCacheParseOptions();
        if (corpusPath != null)
            parseOptions.ExpectedTitles = QuestTitleCorpus.LoadFromScannerLua(corpusPath);
        if (trace)
            parseOptions.Trace = message => Console.Error.WriteLine("[trace] " + message);

        return QuestCacheParser.ParseFile(wdbPath, parseOptions);
    }

    /// <summary>
    /// Pairs a wdb file with a corpus lua by the longest digit run (the build number),
    /// skipping candidates that contain no scanner-format title entries.
    /// </summary>
    private static string FindCorpusFor(string wdbPath, string corpusDir)
    {
        var digits = LongestDigitRun(Path.GetFileNameWithoutExtension(wdbPath));
        if (digits.Length < 4)
            return null;

        foreach (var candidate in Directory.GetFiles(corpusDir, "*.lua")
                     .Where(f => Path.GetFileName(f).Contains(digits))
                     .OrderByDescending(f => new FileInfo(f).Length))
        {
            try
            {
                if (QuestTitleCorpus.LoadFromScannerLua(candidate).Count > 0)
                    return candidate;
            }
            catch (IOException)
            {
            }
        }

        return null;
    }

    private static string LongestDigitRun(string text)
    {
        var best = "";
        var current = "";
        foreach (var c in text + ".")
        {
            if (char.IsDigit(c))
            {
                current += c;
            }
            else
            {
                if (current.Length > best.Length)
                    best = current;
                current = "";
            }
        }

        return best;
    }

    private static Dictionary<string, string> ParseFlags(string[] args)
    {
        var result = new Dictionary<string, string>(StringComparer.OrdinalIgnoreCase);
        for (int i = 0; i < args.Length; i++)
        {
            if (!args[i].StartsWith("--"))
                continue;

            var key = args[i].Substring(2);
            if (i + 1 < args.Length && !args[i + 1].StartsWith("--"))
                result[key] = args[++i];
            else
                result[key] = "true";
        }

        return result;
    }

    private static int GetInt(Dictionary<string, string> options, string key, int fallback)
    {
        return options.TryGetValue(key, out var value) && int.TryParse(value, out var parsed) ? parsed : fallback;
    }

    private static string Truncate(string text, int max)
    {
        text = text.Replace("\r", "\\r").Replace("\n", "\\n");
        return text.Length <= max ? text : text.Substring(0, max) + "...";
    }

    private static void PrintUsage()
    {
        Console.WriteLine("""
            wdbtool - self-calibrating WoW quest cache (questcache.wdb) reader

            usage:
              wdbtool analyze <file.wdb> [--corpus titles.lua] [--samples N] [--failures N] [--trace]
              wdbtool export  <file.wdb> --out out.json [--corpus titles.lua] [--trace]
              wdbtool batch   <directory> [--corpus-dir dir] [--pattern *.wdb] [--recurse] [--trace]

            The corpus is an in-game scanner lua file with ["questId"] = "{{title}}..." entries;
            it is optional but improves calibration and validates results.
            """);
    }
}
