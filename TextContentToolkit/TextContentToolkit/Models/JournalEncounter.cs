using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace TextContentToolkit.Models
{
    public class JournalEncounter
    {
        public int Id { get; set; }

        public string Name { get; set; }

        public string Description { get; set; }

        public List<JournalItem> Items { get; set; } = new List<JournalItem>();

        public List<JournalSection> Sections { get; set; } = new List<JournalSection>();

        public JournalInstance Instance { get; set; }
    }

    public class JournalItem
    {
        public JournalItemItem Item { get; set; }
    }

    public class JournalItemItem
    {
        public int Id { get; set; }

        public string Name { get; set; }
    }

    public class JournalSection
    {
        public string Title { get; set; }

        public string Body_Text { get; set; }

        public List<JournalSection> Sections { get; set; } = new List<JournalSection>();
    }

    public class JournalInstance
    {
        public int Id { get; set; }

        public string Name { get; set; }
    }
}
