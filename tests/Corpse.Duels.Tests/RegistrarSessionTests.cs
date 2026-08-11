using Corpse.Duels;

namespace Corpse.Duels.Tests;

public class RegistrarSessionTests
{
    private static readonly string Root = FindRepoRoot();
    private static readonly string ConfessionsPath = Path.Combine(Root, "data", "confessions.json");
    private static readonly string RegistrarPath = Path.Combine(Root, "duels", "opponents", "registrar.json");

    private static readonly string[] StarterPool =
    [
        "cf_greed_boots",
        "cf_pride_list",
        "cf_lust_float",
        "cf_lust_schedule",
        "cf_pride_grammar",
        "cf_pride_counselor",
        "cf_cruel_soupline",
        "cf_cruel_sentences",
        "cf_cow_leftroom",
        "cf_cow_bigger",
        "cf_cow_passive",
        "cf_bt_manifest"
    ];

    private static readonly string[] WinningCounters =
    [
        "cf_cruel_sentences",
        "cf_greed_boots",
        "cf_pride_list",
        "cf_cow_bigger",
        "cf_cow_passive",
        "cf_lust_schedule",
        "cf_pride_counselor",
        "cf_bt_manifest"
    ];

    [Fact]
    public void Registrar_Content_Loads_With_Eight_Attacks()
    {
        var opponent = DuelContent.LoadOpponent(RegistrarPath);

        Assert.Equal("registrar", opponent.Id);
        Assert.Equal(8, opponent.Attacks.Count);
        Assert.All(opponent.Attacks, attack => Assert.False(string.IsNullOrWhiteSpace(attack.Text)));
    }

    [Fact]
    public void Every_Registrar_Attack_Has_Two_Valid_Starter_Counters_Before_Lockout()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath).ToDictionary(confession => confession.Id);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);

        foreach (var attack in opponent.Attacks)
        {
            var validCounters = StarterPool
                .Select(id => confessions[id])
                .Where(counter => counter.Id != attack.LocksConfessionId)
                .Where(counter => ConfessionDuelResolver.IsValidCounter(attack, counter))
                .Select(counter => counter.Id)
                .ToList();

            Assert.True(validCounters.Count >= 2, $"{attack.Id} only has {validCounters.Count} valid starter counters: {string.Join(", ", validCounters)}");
        }
    }

    [Fact]
    public void Registrar_Session_Wins_After_Eight_Correct_Counters()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);
        var session = new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions),
            new DuelState(StarterPool.ToHashSet(), new HashSet<string>(), new HashSet<string>()));

        foreach (var counter in WinningCounters)
        {
            var result = session.Play(counter);
            Assert.True(result.CounterResult.IsCorrect, $"{result.Attack.Id} rejected {counter}: {result.CounterResult.Reason}");
            Assert.False(result.Lost);
        }

        Assert.True(session.Won);
        Assert.Equal(8, session.AttackIndex);
        Assert.Equal(0, session.State.Salt);
        Assert.All(WinningCounters, id => Assert.Contains(id, session.State.SpentConfessionIds));
    }

    [Fact]
    public void Scripted_Win_Path_Keeps_At_Least_Two_Valid_Choices_Per_Round()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath).ToDictionary(confession => confession.Id);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);
        var session = new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions.Values),
            new DuelState(StarterPool.ToHashSet(), new HashSet<string>(), new HashSet<string>()));

        foreach (var counter in WinningCounters)
        {
            var attack = session.BeginCurrentAttack();
            var validCounters = session.State.AvailableConfessionIds
                .Except(session.State.SpentConfessionIds)
                .Except(session.State.LockedConfessionIds)
                .Select(id => confessions[id])
                .Where(candidate => ConfessionDuelResolver.IsValidCounter(attack, candidate))
                .Select(candidate => candidate.Id)
                .ToList();

            Assert.True(validCounters.Count >= 2, $"{attack.Id} only has {validCounters.Count} valid choices before selection: {string.Join(", ", validCounters)}");
            Assert.Contains(counter, validCounters);

            var result = session.Play(counter);
            Assert.True(result.CounterResult.IsCorrect, $"{attack.Id} rejected scripted counter {counter}: {result.CounterResult.Reason}");
        }
    }

    [Fact]
    public void Registrar_Session_Loses_After_Three_Wrong_Spent_Counters()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);
        var session = new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions),
            new DuelState(
                new[] { "cf_greed_drink", "cf_greed_scales", "cf_greed_plate" }.ToHashSet(),
                new HashSet<string>(),
                new HashSet<string>()));

        foreach (var counter in new[] { "cf_greed_drink", "cf_greed_scales", "cf_greed_plate" })
        {
            session.Play(counter);
        }

        Assert.True(session.Lost);
        Assert.False(session.Won);
        Assert.Equal(3, session.State.Salt);
    }

    [Fact]
    public void Spoken_Attack_Locks_Matching_Confession_Out_Of_Defense_Pool()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);
        var session = new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions),
            new DuelState(StarterPool.Append("cf_greed_plate").ToHashSet(), new HashSet<string>(), new HashSet<string>()));

        session.Play("cf_cruel_sentences");
        var result = session.Play("cf_greed_plate");

        Assert.False(result.CounterResult.Spent);
        Assert.Contains("cf_greed_plate", session.State.LockedConfessionIds);
        Assert.Equal(0, session.State.Salt);
    }

    [Fact]
    public void Beginning_Attack_Applies_Spoken_Lockout_Before_Player_Selects()
    {
        var confessions = DuelContent.LoadConfessions(ConfessionsPath);
        var opponent = DuelContent.LoadOpponent(RegistrarPath);
        var session = new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions),
            new DuelState(StarterPool.Append("cf_greed_plate").ToHashSet(), new HashSet<string>(), new HashSet<string>()));

        session.Play("cf_cruel_sentences");
        var attack = session.BeginCurrentAttack();

        Assert.Equal("reg_collection_plate", attack.Id);
        Assert.Contains("cf_greed_plate", session.State.LockedConfessionIds);
    }

    private static string FindRepoRoot()
    {
        var directory = new DirectoryInfo(AppContext.BaseDirectory);
        while (directory is not null)
        {
            if (File.Exists(Path.Combine(directory.FullName, "CorpseInGoodStanding.sln")))
            {
                return directory.FullName;
            }
            directory = directory.Parent;
        }

        throw new DirectoryNotFoundException("Could not find repo root.");
    }
}
