# WdbToolkit

Self-calibrating reader for WoW client quest cache files (`questcache.wdb`), replacing the
per-build hand-tuned parsers in `TextContentToolkit/Extensions/QuestCacheReader.cs`.

## Why it works without per-version offsets

Every quest record is the client's dump of the `QUEST_QUERY_RESPONSE` packet:

```
[quest id: int32][record length: int32][payload]
payload = [fixed numeric block]                  <- size changes between builds ("F")
          [bit-packed string lengths, 12 bytes]  <- 9/12/12/9/10/8/10/8/11 bits, MSB-first
          [per-objective data, variable]
          [string bytes: title, objectives text, description, area,
           4 portrait strings, completion log]   <- lengths from the bit block
          [trailing data, usually empty]         <- conditional quest texts ("t")
```

Two facts are stable across every build from Shadowlands/classic-modern through current
retail: the bit widths of the string-length block, and the strings sitting at the *end*
of the record. Everything that changes per build (the fixed block size F, per-record
drift from variable arrays such as TreasurePickerID, trailing size t) can therefore be
*inferred* per file:

1. **Calibration** (`QuestCacheCalibrator`): sample records, scan candidate offsets for
   the length block, keep offsets whose decoded lengths partition the record tail into
   valid UTF-8 for all nine fields. Votes are weighted by decoded byte count so tiny
   coincidental matches lose. When a corpus of known titles (scanner lua) is supplied,
   the title bytes are located directly, which also measures t exactly.
2. **Extraction** (`QuestRecordExtractor`): apply the calibrated layout per record and
   recover deviants via +-4-byte header shifts, trailing-size scans, and corpus title
   search. Untitled hidden quests (title length 0) are supported.

If a future build changes the bit widths themselves, add a new
`QuestStringBlockSpec` and pass it in `QuestCacheParseOptions.Specs`; calibration
picks the spec that fits.

## Library use

```csharp
var options = new QuestCacheParseOptions
{
    ExpectedTitles = QuestTitleCorpus.LoadFromScannerLua("questobjectives68256.lua"), // optional
};
var result = QuestCacheParser.ParseFile("questcache68256.wdb", options);

Console.WriteLine(result.BuildSummary());   // inferred layout, stats, drift/trailing histograms
foreach (var quest in result.Quests)
    Console.WriteLine(quest.Id + " " + quest.LogTitle + " " + quest.QuestDescription);
```

`TextContentToolkit.Readers.SmartQuestCacheReader` wraps this for the toolkit pipeline
(same output conventions as the old readers: quote escaping, `$g...;` gender rewrite,
merge by quest id).

## Diagnostic CLI (wdbtool)

```
dotnet run --project WdbToolkit.Cli -- analyze questcache.wdb [--corpus titles.lua]
dotnet run --project WdbToolkit.Cli -- export  questcache.wdb --out quests.json [--corpus titles.lua]
dotnet run --project WdbToolkit.Cli -- batch   <dir> [--corpus-dir <dir>]
```

`analyze` prints the inferred layout for a new build (the work that used to require
manual hex inspection); `batch` regression-tests a whole directory and pairs each wdb
with a corpus lua by build number in the file name.

Reference layout history recovered from the data on hand: F=444 (9.x) -> 456 (SL/DF)
-> 460 -> 464 -> 468 -> 476 -> 480 -> 484 (11.x retail, with per-record +4n drift);
classic: 452 (TBC) -> 456 (WLK) -> 472 (Cata) -> 476 -> 480 (MoP). Trailing size is 0
except for rare records carrying conditional quest texts.
