using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text.RegularExpressions;
using TextContentToolkit.Models;
using TextContentToolkit.Readers;
using TextContentToolkit.Utils;

namespace TextContentToolkit
{
    public class SpellReader : TooltipsReader
    {
        private static readonly List<string> BlackListedPostfix = new List<string>
        {
            "瞬发",
            "冷却时间",
            "施法时间",
            "需引导",
            "被动"
        };

        private static readonly Dictionary<string, string> TextToSim = new Dictionary<string, string>
        {
            { "瞬发", "À" },
            { "施法时间", "Á" },
            { "码射程", "Â" },
            { "秒", "Ã" },
            { "冷却时间", "Ä" },
            { "|cffffd100", "Å" },
            { "|r|cff7f7f7f", "Æ" },
            { "|r", "Ç" },
            { "近战范围", "È" },
            { "持续", "É" },
            { "造成", "Ê" },

            { "点伤害", "Ë" },
            { "点治疗", "Ì" },
            { "点生命值", "Í" },
            { "点法力值", "Î" },
            { "点物理伤害", "Ï" },
            { "点魔法伤害", "Ð" },
            { "点火焰伤害", "Ñ" },
            { "点冰霜伤害", "Ò" },
            { "点暗影伤害", "Ó" },
            { "点神圣伤害", "Ô" },
            { "点奥术伤害", "Õ" },
            { "点混乱伤害", "Ö" },
            { "点流血伤害", "Ø" }
        };

        internal override WoWeuCNWriterProfile Profile
        {
            get
            {
                return new WoWeuCNWriterProfile
                {
                    EntityName = "Spell",
                    HeaderIndent = "  ",
                    EncodeColors = true,
                    RoundColorChannels = true,
                    DedupIdenticalPayloads = true,
                    TextTransform = ApplyTextToSim,
                    SkipRecord = ShouldSkip
                };
            }
        }

        private static string ApplyTextToSim(string text)
        {
            foreach (var textToSim in TextToSim)
                text = text.Replace(textToSim.Key, textToSim.Value);

            return text;
        }

        private static bool ShouldSkip(Tooltip spellTips)
        {
            // baseline back-references ("¿id") always survive
            if (spellTips.TooltipLines.Count > 0 && spellTips.TooltipLines[0].Line.StartsWith("¿"))
                return false;

            if (spellTips.TooltipLines.Count < 2)
                return true;

            if (spellTips.TooltipLines.Count <= 4 &&
                BlackListedPostfix.Any(b => spellTips.TooltipLines.Last().Line.EndsWith(b)))
                return true;

            return false;
        }

        protected override bool IsRelevantSection(string tableName)
        {
            return tableName.Contains("SpellToolTips");
        }

        protected override void Read(string inputPath, Dictionary<string, Tooltip> tips)
        {
            var usedId = new HashSet<string>();
            foreach (var line in ReadCategoryLines(inputPath))
            {
                if (line.Contains("DND"))
                    continue;

                var raw = ScannerTooltipParser.TryParse(line, stripRedColorCodes: true, hasTypeMarker: false);
                if (raw == null)
                    continue;

                if (usedId.Contains(raw.Id))
                    continue;
                usedId.Add(raw.Id);

                if (!raw.HasBody)
                    continue;

                var spellTips = new Tooltip { Id = raw.Id };
                foreach (var entry in raw.Entries)
                {
                    if (!spellTips.TooltipLines.Any() && !entry.Line.HasChinese())
                        break;

                    // red
                    if (entry.R == "0.99999779462814" && entry.G == "0.12548992037773" && entry.B == "0.12548992037773")
                        continue;

                    if (entry.R == "1" && entry.G == "0.12549020349979" && entry.B == "0.12549020349979")
                        continue;

                    var spellTipLine = new TooltipLine
                    {
                        Line = entry.Line,
                        R = Math.Round(double.Parse(entry.R), 2),
                        G = Math.Round(double.Parse(entry.G), 2),
                        B = Math.Round(double.Parse(entry.B), 2)
                    };

                    foreach (var grayedOutIndicator in StringUtils.GrayedOutIndicatorText)
                    {
                        var matches = Regex.Matches(spellTipLine.Line, @"(\d+(,\d+)*)" + grayedOutIndicator).OfType<Match>().ToList();
                        var orderedMatches = matches.OrderByDescending(m => m.Length);
                        foreach (var match in orderedMatches)
                        {
                            var result = match.Result("$1");
                            result = "|cff7f7f7f" + result + "|r";
                            spellTipLine.Line = spellTipLine.Line.Replace(match.Value, result + grayedOutIndicator);
                        }
                    }

                    spellTips.TooltipLines.Add(spellTipLine);
                }

                if (!spellTips.TooltipLines.Any())
                    continue;

                Store(tips, spellTips);
            }
        }
    }
}
