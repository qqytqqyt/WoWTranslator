namespace QuestTextRetriever.Models
{
    public class Quest
    {
        public string Id { get; set; }

        public string Title { get; set; }

        public string Objectives { get; set; }

        public string Description { get; set; }

        public string Progress { get; set; }

        public string Completion { get; set; }

        public string Translator { get; set; }
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

        public string Objectives { get; set; }
    }
}
