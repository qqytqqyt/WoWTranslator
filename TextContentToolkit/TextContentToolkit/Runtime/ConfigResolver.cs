using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;

namespace TextContentToolkit.Runtime
{
    internal sealed class ConfigResolver
    {
        private readonly List<string> m_searchDirectories;

        public ConfigResolver(IEnumerable<string> searchDirectories)
        {
            m_searchDirectories = searchDirectories
                .Where(path => !string.IsNullOrWhiteSpace(path))
                .Select(Path.GetFullPath)
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public List<string> GetConfigFiles()
        {
            var files = new List<string>();
            foreach (var directory in m_searchDirectories)
            {
                if (!Directory.Exists(directory))
                {
                    continue;
                }

                files.AddRange(Directory.GetFiles(directory, "Config*.xml"));
            }

            return files
                .GroupBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .Select(group => group.OrderBy(path => path.Length).First())
                .OrderBy(Path.GetFileName, StringComparer.OrdinalIgnoreCase)
                .ToList();
        }

        public bool TryResolve(RuntimeOptions options, out string configPath, out string error)
        {
            configPath = string.Empty;
            error = string.Empty;

            if (!string.IsNullOrWhiteSpace(options.ConfigPath))
            {
                return TryResolvePath(options.ConfigPath, out configPath, out error);
            }

            if (!string.IsNullOrWhiteSpace(options.Profile))
            {
                var profileCandidates = BuildProfileCandidates(options.Profile);
                configPath = GetConfigFiles()
                    .FirstOrDefault(file => profileCandidates.Contains(Path.GetFileName(file)));

                if (string.IsNullOrWhiteSpace(configPath))
                {
                    error = "Profile config not found: " + options.Profile;
                    return false;
                }

                return true;
            }

            return TryResolvePath("Config.xml", out configPath, out error);
        }

        private bool TryResolvePath(string requestedPath, out string configPath, out string error)
        {
            configPath = string.Empty;
            error = string.Empty;

            var candidates = new List<string>();

            if (Path.IsPathRooted(requestedPath))
            {
                candidates.Add(requestedPath);
            }
            else
            {
                candidates.Add(Path.GetFullPath(requestedPath));
                candidates.AddRange(m_searchDirectories.Select(directory => Path.Combine(directory, requestedPath)));
            }

            foreach (var candidate in candidates.Distinct(StringComparer.OrdinalIgnoreCase))
            {
                if (!File.Exists(candidate))
                {
                    continue;
                }

                configPath = Path.GetFullPath(candidate);
                return true;
            }

            error = "Config file not found: " + requestedPath;
            return false;
        }

        private static HashSet<string> BuildProfileCandidates(string profile)
        {
            var trimmedProfile = profile.Trim();
            var fileName = trimmedProfile.EndsWith(".xml", StringComparison.OrdinalIgnoreCase)
                ? trimmedProfile
                : trimmedProfile + ".xml";

            var candidates = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
            {
                fileName
            };

            if (!fileName.StartsWith("Config", StringComparison.OrdinalIgnoreCase))
            {
                candidates.Add("Config" + fileName);
            }

            return candidates;
        }
    }
}
