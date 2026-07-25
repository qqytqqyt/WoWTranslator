using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Text;
using TextContentToolkit.Models;

namespace TextContentToolkit.Readers
{
    internal sealed class WoWeuCNWriterProfile
    {
        /// <summary>Used in the generated lua symbols: WoWeuCN_Tooltips_&lt;EntityName&gt;Data_* / load&lt;EntityName&gt;Data*().</summary>
        public string EntityName;

        /// <summary>Indent in front of the data table declaration ("" for items, "  " for the others).</summary>
        public string HeaderIndent = string.Empty;

        /// <summary>Encode non-white line colours as |cffrrggbb markup (items and spells).</summary>
        public bool EncodeColors;

        /// <summary>Round colour channels (spells) instead of truncating (items).</summary>
        public bool RoundColorChannels;

        /// <summary>Optional final text substitution per line (the spell compression table).</summary>
        public Func<string, string> TextTransform;

        /// <summary>Write identical adjacent payloads as a "¿id" back-reference (spells).</summary>
        public bool DedupIdenticalPayloads;

        /// <summary>Return true to leave the record out of the output.</summary>
        public Func<Tooltip, bool> SkipRecord;
    }

    /// <summary>
    /// Writes the WoWeuCN addon data format shared by items/spells/units/achievements:
    /// per-100000-id blocks of "payload", --id lines wrapped in load&lt;Entity&gt;Data&lt;block&gt;()
    /// functions, each followed by a WoWeuCN_Tooltips_&lt;Entity&gt;IndexData_&lt;block&gt; index table.
    /// </summary>
    internal static class WoWeuCNTooltipWriter
    {
        private const int BlockSize = 100000;

        public static void Write(string outputPath, WoWeuCNWriterProfile profile, Dictionary<string, Tooltip> tips)
        {
            var sb = new StringBuilder();
            var orderedTips = tips.Select(t => t.Value).OrderBy(t => int.Parse(t.Id)).ToList();
            var currentIndex = 0;
            var currentBlock = 0;
            var maxRelativeId = 1;
            var idIndexMapping = new int[BlockSize + 1];
            var lastPayload = string.Empty;
            var lastId = string.Empty;

            foreach (var tooltip in orderedTips)
            {
                var id = int.Parse(tooltip.Id);
                if (id >= currentBlock + BlockSize)
                {
                    sb.AppendLine(" };").AppendLine("end").AppendLine();
                    AppendIndex(sb, profile, currentBlock, idIndexMapping, maxRelativeId);
                    maxRelativeId = 1;
                    idIndexMapping = new int[BlockSize + 1];

                    while (id >= currentBlock + BlockSize)
                        currentBlock += BlockSize;

                    currentIndex = 0;
                }

                if (currentIndex == 0)
                {
                    sb.AppendLine("function load" + profile.EntityName + "Data" + currentBlock + "()");
                    sb.AppendLine(profile.HeaderIndent + "WoWeuCN_Tooltips_" + profile.EntityName + "Data_" + currentBlock + " = {");
                    currentIndex = 1;
                    lastPayload = string.Empty;
                    lastId = string.Empty;
                }

                if (profile.SkipRecord != null && profile.SkipRecord(tooltip))
                    continue;

                var payload = BuildPayload(profile, tooltip);

                // Baseline back-references ("¿id") are written literally and never take part in
                // dedup again, otherwise a reference could end up pointing at another reference.
                var isBackReference = tooltip.TooltipLines.Count > 0 && tooltip.TooltipLines[0].Line.StartsWith("¿");

                if (profile.DedupIdenticalPayloads && !isBackReference && payload == lastPayload && lastId.Length > 0)
                {
                    sb.Append("\"¿" + lastId + "x");
                }
                else
                {
                    if (profile.DedupIdenticalPayloads && !isBackReference)
                    {
                        lastPayload = payload;
                        lastId = tooltip.Id;
                    }

                    sb.Append(payload);
                }

                if (tooltip.TooltipLines.Any())
                    sb.Remove(sb.Length - 1, 1);

                sb.Append("\",").Append(" --" + tooltip.Id).AppendLine();

                idIndexMapping[id - currentBlock] = currentIndex;
                maxRelativeId = id - currentBlock;
                currentIndex++;
            }

            sb.Append("};").AppendLine();
            AppendIndex(sb, profile, currentBlock, idIndexMapping, maxRelativeId);
            sb.Append("end");

            File.WriteAllText(outputPath, sb.ToString());
        }

        private static string BuildPayload(WoWeuCNWriterProfile profile, Tooltip tooltip)
        {
            var tempSb = new StringBuilder();
            tempSb.Append("\"");
            foreach (var tooltipLine in tooltip.TooltipLines)
            {
                string text;
                if (profile.EncodeColors)
                {
                    var r = ToChannel(tooltipLine.R, profile.RoundColorChannels);
                    var g = ToChannel(tooltipLine.G, profile.RoundColorChannels);
                    var b = ToChannel(tooltipLine.B, profile.RoundColorChannels);
                    if (r == 255 && g == 255 && b == 255)
                    {
                        text = tooltipLine.Line;
                    }
                    else
                    {
                        var colourText = "|cff" + ToHex2(r) + ToHex2(g) + ToHex2(b);
                        text = tooltipLine.Line.Replace("|c", "|#|c").Replace("|r", "|r" + colourText)
                            .Replace("|#", "|r");
                        text = colourText + text + "|r";
                        text = text.Replace(colourText + "|r", string.Empty);
                    }
                }
                else
                {
                    text = tooltipLine.Line;
                }

                if (profile.TextTransform != null)
                    text = profile.TextTransform(text);

                tempSb.Append(text).Append("£");
            }

            return tempSb.ToString();
        }

        private static void AppendIndex(StringBuilder sb, WoWeuCNWriterProfile profile, int block, int[] idIndexMapping, int maxRelativeId)
        {
            sb.AppendLine("WoWeuCN_Tooltips_" + profile.EntityName + "IndexData_" + block + " = {");
            for (var i = 1; i <= maxRelativeId; ++i)
            {
                if (idIndexMapping[i] != 0)
                    sb.AppendLine().Append(idIndexMapping[i]).Append(",");
                else
                    sb.Append("nil,");
            }

            sb.AppendLine().Append("};").AppendLine();
        }

        private static int ToChannel(double value, bool round)
        {
            return round ? (int)Math.Round(value * 255) : (int)(value * 255);
        }

        private static string ToHex2(int channel)
        {
            var text = Convert.ToString(channel, 16);
            return text.Length < 2 ? "0" + text : text;
        }
    }
}
