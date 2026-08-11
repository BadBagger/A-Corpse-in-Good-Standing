namespace Corpse.Narrative;

public sealed class InkTagProcessor
{
    private readonly IReadOnlyDictionary<string, JournalEntry> _journalCatalog;

    public InkTagProcessor(IEnumerable<JournalEntry> journalEntries)
    {
        _journalCatalog = journalEntries.ToDictionary(entry => entry.Id);
    }

    public void ApplyTags(IEnumerable<string> tags, GameNarrativeState state)
    {
        foreach (var tag in tags)
        {
            ApplyTag(tag, state);
        }
    }

    public bool ApplyTag(string rawTag, GameNarrativeState state)
    {
        var tag = rawTag.Trim();
        if (tag.StartsWith("journal:add:", StringComparison.Ordinal))
        {
            var id = tag["journal:add:".Length..];
            if (_journalCatalog.TryGetValue(id, out var entry))
            {
                state.Journal.Add(entry);
                return true;
            }

            return false;
        }

        if (tag.StartsWith("confession:discover:", StringComparison.Ordinal))
        {
            return state.Confessions.Discover(tag["confession:discover:".Length..]);
        }

        if (tag.StartsWith("confession:spent:", StringComparison.Ordinal))
        {
            return state.Confessions.Spend(tag["confession:spent:".Length..]);
        }

        if (tag.StartsWith("confession:opponent_spoken:", StringComparison.Ordinal))
        {
            return state.Confessions.LockOpponentSpoken(tag["confession:opponent_spoken:".Length..]);
        }

        return false;
    }
}

