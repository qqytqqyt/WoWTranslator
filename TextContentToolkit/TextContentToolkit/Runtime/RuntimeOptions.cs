namespace TextContentToolkit.Runtime
{
    internal sealed class RuntimeOptions
    {
        public bool ShowHelp { get; private set; }

        public bool ListConfigs { get; private set; }

        public string ConfigPath { get; private set; }

        public string Profile { get; private set; }

        public static bool TryParse(string[] args, out RuntimeOptions options, out string error)
        {
            options = new RuntimeOptions();
            error = string.Empty;

            for (var i = 0; i < args.Length; i++)
            {
                var arg = args[i];
                switch (arg.ToLowerInvariant())
                {
                    case "--help":
                    case "-h":
                    case "/?":
                        options.ShowHelp = true;
                        break;
                    case "--list-configs":
                        options.ListConfigs = true;
                        break;
                    case "--config":
                    case "-c":
                        if (!TryReadValue(args, ref i, arg, out var configPath, out error))
                        {
                            return false;
                        }

                        options.ConfigPath = configPath;
                        break;
                    case "--profile":
                    case "-p":
                        if (!TryReadValue(args, ref i, arg, out var profile, out error))
                        {
                            return false;
                        }

                        options.Profile = profile;
                        break;
                    default:
                        error = "Unknown argument: " + arg;
                        return false;
                }
            }

            if (!string.IsNullOrWhiteSpace(options.ConfigPath) && !string.IsNullOrWhiteSpace(options.Profile))
            {
                error = "--config and --profile cannot be used together.";
                return false;
            }

            return true;
        }

        private static bool TryReadValue(string[] args, ref int index, string optionName, out string value, out string error)
        {
            value = string.Empty;
            error = string.Empty;
            var valueIndex = index + 1;
            if (valueIndex >= args.Length || args[valueIndex].StartsWith("-"))
            {
                error = "Missing value for " + optionName + ".";
                return false;
            }

            value = args[valueIndex];
            index = valueIndex;
            return true;
        }
    }
}
