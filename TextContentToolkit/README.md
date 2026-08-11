# TextContentToolkit

Convention-driven parser for WoW scanner data. It turns scanner lua dumps and client
cache files into the WoWeuCN addon data files, with no configuration files: everything
is derived from where a file sits and what it is named.

## Daily workflow

1. After scanning in game, double-click `Data\<category>\pull_inputs.bat` for the
   category you scanned. It copies `WoWeuCN_Scanner.lua` (and for quests also
   `Cache\WDB\zhCN\questcache.wdb`) from every WoW install branch into the right
   variant folder — see "Pulling scans" below. Alternatively drop files in manually:

   | Category      | Folder                        | Input files                                  |
   |---------------|-------------------------------|----------------------------------------------|
   | Quests        | `Data\quests\<variant>\`      | objectives `*.lua` and `questcache*.wdb`     |
   | Items         | `Data\items\<variant>\`       | scanner `*.lua`                              |
   | Spells        | `Data\spells\<variant>\`      | scanner `*.lua`                              |
   | Units         | `Data\units\<variant>\`       | scanner `*.lua`                              |
   | Achievements  | `Data\achievements\<variant>\`| scanner `*.lua`                              |

   `<variant>` is `wow` (retail), `wow_classic` or `wow_classic_era`. New variant
   folders can simply be created and are picked up automatically.

   The file name does not matter - every `.lua`/`.wdb` file that is not an output and
   not yet `.parsed.` counts as new input. Including the client **build number**
   (4-6 digits) in the name is still recommended: it orders the inputs and names the
   output. Several files for one build are ordered by a trailing segment number:
   `retail_spells_68256.lua`, `retail_spells_68256.1.lua`, `retail_spells_68256.2.lua`, ...
   A stray `.wdb` in a non-quest folder is warned about and left untouched.

2. Run the toolkit (no arguments needed):

   ```
   TextContentToolkit\TextContentToolkit\bin\Debug\TextContentToolkit.exe
   ```

   The `Data` folder is located automatically by walking up from the exe; use
   `--data <path>` to override. Use `--dry-run` first if you want to see the plan.

3. For every folder that contains new inputs the toolkit:
   - loads the **latest existing `*output*` file** (highest build number) as baseline,
   - parses the new inputs in build/segment order on top of it — **new data wins**,
     but for quests a translated (Chinese) field is never replaced by untranslated text
     and an empty record never erases existing data,
   - writes `<category>_output_<build>.lua` into the same folder (`<build>` = highest
     build involved; just `<category>_output.lua` when no build number is known),
   - renames each consumed input to `*.parsed.lua` / `*.parsed.wdb`.

   Folders without new inputs are skipped. Running twice is a no-op.

4. Copy the newest `*_output_*.lua` files into the addon as before.

## Pulling scans (`pull_inputs.bat` / `pull_scans.ps1`)

Each category folder has a `pull_inputs.bat` that calls the shared
`Data\pull_scans.ps1`. For every WoW install branch it takes
`<branch>\WTF\Account\411375915#1\SavedVariables\WoWeuCN_Scanner.lua` (and for
quests also `<branch>\Cache\WDB\zhCN\questcache.wdb`) and copies it into the
matching variant folder — test branches land in their live folder:

| WoW branch                          | Data variant folder |
|-------------------------------------|---------------------|
| `_retail_`, `_ptr_`, `_xptr_`, `_beta_` | `wow`           |
| `_classic_`, `_classic_ptr_`, `_classic_beta_` | `wow_classic` |
| `_classic_era_`, `_classic_era_ptr_`   | `wow_classic_era` |
| `_anniversary_`, `_anniversary_ptr_`   | `wow_anniversary` |

Rules:
- a file is only taken when it is **newer than the newest `*output*` file** of the
  target folder (i.e. the scan happened after the last parse);
- a scanner lua is only taken when it **actually contains data for the category**
  (the matching SavedVariables tables are non-empty - see "Scanner sections" below);
- the copy is **stripped to the category's own sections**: unrelated tables keep
  their declaration but lose their entries, so a scan that accidentally captured
  several categories never carries foreign data into the folder (the scan time is
  preserved on the copy for parse ordering);
- copies are named `scanner_<branch>_<timestamp>.lua` / `questcache_<branch>_<timestamp>.wdb`,
  so live and PTR scans and still-unparsed older inputs never overwrite each other -
  everything is kept for the next parse (the toolkit parses build-less inputs in
  file-time order, so the newest scan wins merge conflicts);
- running the script twice copies nothing new;
- `pull_scans.ps1 -CategoryDir <dir> -DryRun` previews without copying.

Edit the `$variantMap` at the top of `pull_scans.ps1` to add/remove branches, and
`-WowRoot`/`-Account` if the installation moves.

## Scanner sections (how category data is recognized inside the lua)

A `WoWeuCN_Scanner.lua` holds many top-level SavedVariables tables. Both the pull
script and the parsers only look at the tables of their own category:

| Category      | SavedVariables tables                                  |
|---------------|--------------------------------------------------------|
| Items         | `WoWeuCN_Scanner_ItemToolTips0/100000/...`             |
| Spells        | `WoWeuCN_Scanner_SpellToolTips0/100000/...`            |
| Units         | `WoWeuCN_Scanner_UnitToolTips0/100000/...`             |
| Achievements  | `WoWeuCN_Scanner_Achivements0/...` (addon's spelling)  |
| Quests        | `WoWeuCN_Scanner_QuestToolTips`                        |

Everything else (`*NameData`, `EncounterData`, `Decor`, `*Index`, ...) is ignored, so
one scan file can safely be pulled into several categories - each parser extracts
only its own sections and quest data can never leak into the items output. Files
without any table declarations (bare extracts, previous outputs) are parsed whole,
as before.

## File-name rules (how a file is classified)

- not `.lua`/`.wdb`   -> ignored
- contains `.parsed.` -> already merged, skipped
- contains `output`   -> output file (baseline candidate, never parsed)
- anything else       -> **new input, will be parsed on the next run**

## Command line

```
TextContentToolkit.exe [options]
  --data <path>        Data root (default: auto-detected)
  --dry-run, -n        Print the plan, change nothing
  --categories <list>  Restrict to some categories, e.g. items,spells
  --mark-parsed        Rename all new inputs to *.parsed.* WITHOUT parsing them
                       (use when outputs already contain their data)
  --questie <folder>   Legacy Questie l10n generation from <folder>\*.lua
  --help
```

## Rebuilding from scratch

Outputs are cumulative snapshots, so normally only the latest one matters. To fully
rebuild a folder: delete (or move away) its `*output*` files, rename the wanted
`*.parsed.*` inputs back (remove the `.parsed` part), and run the toolkit.

## Notes

- Old loose files that predate this pipeline were moved to `..\DataArchive\`
  (mirroring the `Data\` structure). Nothing in there is read by the toolkit.
- The quest template is embedded in the code (`QuestReader.TemplateLine`); the old
  `template.txt` files and all `Config*.xml` files are gone.
- Quest caches (`.wdb`) of any build are parsed by the self-calibrating `WdbToolkit`
  library; known titles from the previous output and the objectives files anchor the
  calibration, so keep objectives and caches of the same build together when possible.
- `retail_spells_output_63660.1.lua` was actually the newest spell output (the old
  config was never updated to name it 65459); the automatic output naming prevents
  this from happening again.
