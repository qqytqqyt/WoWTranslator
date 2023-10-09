namespace TextContentToolkit.Models
{
    public class Quest
    {
        public string Id { get; set; }

        public string Title { get; set; }

        public string Objectives { get; set; } = string.Empty;

        public string Description { get; set; } = string.Empty;

        public string Progress { get; set; } = string.Empty;

        public string Completion { get; set; } = string.Empty;

        public string Translator { get; set; } = string.Empty;
    }

    public class QuestApi
    {
        public string Id { get; set; }

        public string Title { get; set; }

        public string Description { get; set; }
    }

    public class QuestObjectives
    {
        public string Id { get; set; }

        public string Title { get; set; }

        public string Objectives { get; set; } = string.Empty;
    }
}
