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
of the record. The block position follows one of two schemes (`QuestCacheLayoutMode`):

- **HeaderAtFixedOffset** (all builds up to retail 68256 and all classic builds): the
  block sits right after the fixed numeric struct, so its offset F is (nearly) constant
  per build, with per-record +4n drift from variable arrays such as TreasurePickerID.
- **HeaderBeforeStrings** (observed from retail build 68914): the block moved to sit
  immediately before the string bytes, so its offset varies per record and is solved
  from the end-anchor equation `offset + 12 + sum(lengths) + trailing == payload length`.

Inference per file:

1. **Calibration** (`QuestCacheCalibrator`): sample records and build a candidate layout
   for each scheme - offset voting weighted by decoded byte count for the fixed scheme,
   trailing-size voting for the adjacent scheme. Both candidates are then *verified* by
   direct extraction, scored by how many payload bytes they explain; a wrong scheme only
   matches tiny coincidental fragments (a few bytes) while the true one accounts for the
   whole text block (hundreds), so the comparison is decisive even without a corpus.
   When a corpus of known titles (scanner lua) is supplied, the title bytes are located
   directly, which also measures the trailing size exactly.
2. **Extraction** (`QuestRecordExtractor`): apply the calibrated layout per record and
   recover deviants via +-4-byte header shifts, trailing-size scans, and corpus title
   search. Untitled hidden quests (title length 0) are supported. All candidate probing
   uses exception-free byte-level UTF-8 validation - the hot loops must never throw.

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
classic: 452 (TBC) -> 456 (WLK) -> 472 (Cata) -> 476 -> 480 (MoP); build 68914+ uses
the header-before-strings scheme instead of a fixed offset. Trailing size is 0 except
for rare records carrying conditional quest texts.

Performance: a full directory sweep (~450k records over 36 builds) takes a few seconds.
A fresh build with no corpus yet still calibrates from structure alone; passing stale
titles (e.g. a previous build's output) is fine - mismatching records fall back to the
cache text without triggering expensive scans.
