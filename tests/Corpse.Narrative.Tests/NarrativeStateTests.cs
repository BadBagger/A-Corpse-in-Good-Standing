using Corpse.Narrative;

namespace Corpse.Narrative.Tests;

public class NarrativeStateTests
{
    [Fact]
    public void Journal_Add_Is_Idempotent_And_Can_Degrade_Text_Only()
    {
        var journal = new Journal();
        var entry = new JournalEntry("j_returned_nine_days", "Nine Days", "The returned get nine days.");

        Assert.True(journal.Add(entry));
        Assert.False(journal.Add(entry));
        Assert.True(journal.Degrade(entry.Id));

        var stored = Assert.Single(journal.Entries);
        Assert.True(stored.Degraded);
        Assert.Equal(entry.Text, stored.Text);
    }

    [Fact]
    public void Confession_Spent_State_Is_Global_And_Permanent()
    {
        var ledger = new ConfessionLedger();

        Assert.True(ledger.Discover("cf_bt_manifest"));
        Assert.True(ledger.Spend("cf_bt_manifest"));
        Assert.False(ledger.Discover("cf_bt_manifest"));
        Assert.False(ledger.Spend("cf_bt_manifest"));

        Assert.Contains("cf_bt_manifest", ledger.Spent);
        Assert.DoesNotContain("cf_bt_manifest", ledger.Discovered);
    }

    [Fact]
    public void Opponent_Spoken_Confession_Is_Locked_Out_Of_Player_Pool()
    {
        var ledger = new ConfessionLedger();

        Assert.True(ledger.Discover("cf_greed_plate"));
        Assert.True(ledger.LockOpponentSpoken("cf_greed_plate"));
        Assert.False(ledger.Discover("cf_greed_plate"));
        Assert.False(ledger.Spend("cf_greed_plate"));

        Assert.Contains("cf_greed_plate", ledger.LockedByOpponent);
    }

    [Fact]
    public void Ink_Tags_Update_Journal_And_Confession_State()
    {
        var state = new GameNarrativeState();
        var processor = new InkTagProcessor(PrologueJournalCatalog.Entries);

        processor.ApplyTags([
            "journal:add:j_returned_nine_days",
            "confession:discover:cf_cow_leftroom",
            "confession:spent:cf_cow_leftroom"
        ], state);

        Assert.True(state.Journal.Contains("j_returned_nine_days"));
        Assert.Contains("cf_cow_leftroom", state.Confessions.Spent);
        Assert.DoesNotContain("cf_cow_leftroom", state.Confessions.Discovered);
    }

    [Fact]
    public void Narrative_State_Roundtrips_To_Json()
    {
        var state = new GameNarrativeState { CurrentDay = 6 };
        state.Journal.Add(PrologueJournalCatalog.Entries[0]);
        state.Confessions.Discover("cf_pride_voice");
        state.Confessions.Spend("cf_pride_voice");

        var path = Path.Combine(Path.GetTempPath(), $"corpse_narrative_{Guid.NewGuid():N}.json");
        try
        {
            NarrativeStateStore.Save(path, state);
            var loaded = NarrativeStateStore.Load(path);

            Assert.Equal(6, loaded.CurrentDay);
            Assert.True(loaded.Journal.Contains("j_returned_nine_days"));
            Assert.Contains("cf_pride_voice", loaded.Confessions.Spent);
        }
        finally
        {
            if (File.Exists(path))
            {
                File.Delete(path);
            }
        }
    }
}

