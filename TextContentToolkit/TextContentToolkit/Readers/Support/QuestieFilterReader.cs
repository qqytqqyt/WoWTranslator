using System.Collections.Generic;
using System.IO;
using TextContentToolkit.Utils;

namespace TextContentToolkit.Readers.Support
{
    internal static class QuestieFilterReader
    {
        public static HashSet<string> ReadIds(string filterPath)
        {
            var validIds = new HashSet<string>();
            if (string.IsNullOrWhiteSpace(filterPath))
            {
                return validIds;
            }

            foreach (var line in File.ReadAllLines(filterPath))
            {
                if (!line.Trim().StartsWith("["))
                {
                    continue;
                }

                var id = line.FirstBetween("[", "]");
                if (!string.IsNullOrWhiteSpace(id))
                {
                    validIds.Add(id);
                }
            }

            return validIds;
        }
    }
}
