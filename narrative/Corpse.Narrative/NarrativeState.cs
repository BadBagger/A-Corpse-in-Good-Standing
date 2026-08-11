using System.Text.Json;
using System.Text.Json.Serialization;

namespace Corpse.Narrative;

public sealed record JournalEntry(
    string Id,
    string Title,
    string Text,
    bool Degraded = false);

public sealed class Journal
{
    private readonly Dictionary<string, JournalEntry> _entries = [];

    public IReadOnlyCollection<JournalEntry> Entries => _entries.Values;

    public bool Add(JournalEntry entry)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(entry.Id);
        return _entries.TryAdd(entry.Id, entry);
    }

    public bool Contains(string id)
    {
        return _entries.ContainsKey(id);
    }

    public bool Degrade(string id)
    {
        if (!_entries.TryGetValue(id, out var entry))
        {
            return false;
        }

        _entries[id] = entry with { Degraded = true };
        return true;
    }

    public JournalSnapshot ToSnapshot()
    {
        return new JournalSnapshot(_entries.Values.OrderBy(entry => entry.Id).ToList());
    }

    public static Journal FromSnapshot(JournalSnapshot snapshot)
    {
        var journal = new Journal();
        foreach (var entry in snapshot.Entries)
        {
            journal.Add(entry);
        }

        return journal;
    }
}

public sealed record JournalSnapshot(IReadOnlyList<JournalEntry> Entries);

public sealed class ConfessionLedger
{
    private readonly HashSet<string> _discovered = [];
    private readonly HashSet<string> _spent = [];
    private readonly HashSet<string> _lockedByOpponent = [];

    public IReadOnlySet<string> Discovered => _discovered;
    public IReadOnlySet<string> Spent => _spent;
    public IReadOnlySet<string> LockedByOpponent => _lockedByOpponent;

    public bool Discover(string id)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(id);
        if (_spent.Contains(id) || _lockedByOpponent.Contains(id))
        {
            return false;
        }

        return _discovered.Add(id);
    }

    public bool Spend(string id)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(id);
        if (!_discovered.Contains(id) || _lockedByOpponent.Contains(id))
        {
            return false;
        }

        _discovered.Remove(id);
        return _spent.Add(id);
    }

    public bool LockOpponentSpoken(string id)
    {
        ArgumentException.ThrowIfNullOrWhiteSpace(id);
        _discovered.Remove(id);
        return _lockedByOpponent.Add(id);
    }

    public ConfessionLedgerSnapshot ToSnapshot()
    {
        return new ConfessionLedgerSnapshot(
            _discovered.Order().ToList(),
            _spent.Order().ToList(),
            _lockedByOpponent.Order().ToList());
    }

    public static ConfessionLedger FromSnapshot(ConfessionLedgerSnapshot snapshot)
    {
        var ledger = new ConfessionLedger();
        foreach (var id in snapshot.Discovered)
        {
            ledger._discovered.Add(id);
        }
        foreach (var id in snapshot.Spent)
        {
            ledger._spent.Add(id);
        }
        foreach (var id in snapshot.LockedByOpponent)
        {
            ledger._lockedByOpponent.Add(id);
        }

        return ledger;
    }
}

public sealed record ConfessionLedgerSnapshot(
    IReadOnlyList<string> Discovered,
    IReadOnlyList<string> Spent,
    IReadOnlyList<string> LockedByOpponent);

public sealed class GameNarrativeState
{
    public int CurrentDay { get; set; } = 3;
    public Journal Journal { get; set; } = new();
    public ConfessionLedger Confessions { get; set; } = new();

    public GameNarrativeSnapshot ToSnapshot()
    {
        return new GameNarrativeSnapshot(CurrentDay, Journal.ToSnapshot(), Confessions.ToSnapshot());
    }

    public static GameNarrativeState FromSnapshot(GameNarrativeSnapshot snapshot)
    {
        return new GameNarrativeState
        {
            CurrentDay = snapshot.CurrentDay,
            Journal = Journal.FromSnapshot(snapshot.Journal),
            Confessions = ConfessionLedger.FromSnapshot(snapshot.Confessions)
        };
    }
}

public sealed record GameNarrativeSnapshot(
    int CurrentDay,
    JournalSnapshot Journal,
    ConfessionLedgerSnapshot Confessions);

public static class NarrativeStateStore
{
    private static readonly JsonSerializerOptions Options = new()
    {
        WriteIndented = true,
        Converters = { new JsonStringEnumConverter() }
    };

    public static void Save(string path, GameNarrativeState state)
    {
        Directory.CreateDirectory(Path.GetDirectoryName(Path.GetFullPath(path))!);
        File.WriteAllText(path, JsonSerializer.Serialize(state.ToSnapshot(), Options));
    }

    public static GameNarrativeState Load(string path)
    {
        var json = File.ReadAllText(path);
        var snapshot = JsonSerializer.Deserialize<GameNarrativeSnapshot>(json, Options)
            ?? throw new InvalidDataException($"Could not deserialize narrative state: {path}");
        return GameNarrativeState.FromSnapshot(snapshot);
    }
}

