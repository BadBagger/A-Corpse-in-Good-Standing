using Corpse.Duels;

namespace Corpse.Duels.Tests;

public class DuelRuleTests
{
    private static readonly Confession GreedTwo = new(
        "cf_greed_plate",
        "I've taken change out of a collection plate.",
        "Not coins. Notes. Coins make a sound.",
        SinCategory.GREED,
        2,
        1,
        "OVERHEARD");

    private static readonly Confession PrideThree = new(
        "cf_pride_list",
        "I keep a list of everyone who's ever been wrong about me.",
        "It's alphabetical.",
        SinCategory.PRIDE,
        3,
        1,
        "EXCAVATED");

    private static readonly Confession CrueltyFour = new(
        "cf_cruel_sentences",
        "I've never hit anyone.",
        "I've never had to.",
        SinCategory.CRUELTY,
        4,
        1,
        "EXCAVATED");

    private static readonly Confession CrueltyNoElaboration = CrueltyFour with
    {
        Id = "cf_cruel_blank",
        Elaboration = ""
    };

    private static readonly Confession BetrayalEight = new(
        "cf_bt_manifest",
        "I read it. Twice.",
        "The Kestrel manifest.",
        SinCategory.BETRAYAL,
        8,
        1,
        "EXCAVATED");

    [Fact]
    public void Strictly_Greater_Weight_Is_Required()
    {
        var attack = new Attack("a1", "A greed accusation.", SinCategory.GREED, 2);

        Assert.False(ConfessionDuelResolver.IsValidCounter(attack, GreedTwo));
        Assert.True(ConfessionDuelResolver.IsValidCounter(attack, PrideThree));
    }

    [Fact]
    public void Category_Must_Match_Or_Trump()
    {
        var attack = new Attack("a1", "A cruelty accusation.", SinCategory.CRUELTY, 3);

        Assert.False(ConfessionDuelResolver.IsValidCounter(attack, PrideThree));
        Assert.True(ConfessionDuelResolver.IsValidCounter(attack, CrueltyFour));
        Assert.True(ConfessionDuelResolver.IsValidCounter(attack, BetrayalEight));
    }

    [Fact]
    public void Failed_Play_Still_Spends_The_Confession_And_Adds_Salt()
    {
        var resolver = Resolver(GreedTwo);
        var state = State("cf_greed_plate");
        var attack = new Attack("a1", "A greed accusation.", SinCategory.GREED, 2);

        var result = resolver.PlayCounter(attack, "cf_greed_plate", state);

        Assert.False(result.IsCorrect);
        Assert.True(result.Spent);
        Assert.Equal(1, result.SaltTaken);
        Assert.Contains("cf_greed_plate", state.SpentConfessionIds);
    }

    [Fact]
    public void Correct_Play_With_Elaboration_Does_Full_Damage()
    {
        var resolver = Resolver(CrueltyFour);
        var state = State("cf_cruel_sentences");
        var attack = new Attack("a1", "A pride accusation.", SinCategory.PRIDE, 3);

        var result = resolver.PlayCounter(attack, "cf_cruel_sentences", state);

        Assert.True(result.IsCorrect);
        Assert.True(result.Spent);
        Assert.Equal(2, result.Damage);
        Assert.Equal(0, result.SaltTaken);
    }

    [Fact]
    public void Correct_Play_Without_Elaboration_Does_Half_Damage()
    {
        var resolver = Resolver(CrueltyNoElaboration);
        var state = State("cf_cruel_blank");
        var attack = new Attack("a1", "A pride accusation.", SinCategory.PRIDE, 3);

        var result = resolver.PlayCounter(attack, "cf_cruel_blank", state);

        Assert.True(result.IsCorrect);
        Assert.Equal(1, result.Damage);
        Assert.Equal(0, result.SaltTaken);
    }

    [Fact]
    public void Session_Requires_Two_Damage_To_Advance_An_Attack()
    {
        var full = CrueltyFour with { Id = "cf_cruel_full" };
        var session = new DuelSession(
            new Opponent("registrar", "The Registrar", 1, [new Attack("a1", "A pride accusation.", SinCategory.PRIDE, 3)]),
            Resolver(CrueltyNoElaboration, full),
            State("cf_cruel_blank", "cf_cruel_full"));

        var first = session.Play("cf_cruel_blank");

        Assert.True(first.CounterResult.IsCorrect);
        Assert.False(first.Won);
        Assert.Equal(0, first.NextAttackIndex);
        Assert.DoesNotContain("cf_cruel_blank", session.State.AvailableConfessionIds);

        var second = session.Play("cf_cruel_full");

        Assert.True(second.CounterResult.IsCorrect);
        Assert.True(second.Won);
        Assert.Equal(1, second.NextAttackIndex);
    }

    [Fact]
    public void Spent_And_Locked_Confessions_Cannot_Be_Played_Again()
    {
        var resolver = Resolver(BetrayalEight);
        var attack = new Attack("a1", "Any accusation.", SinCategory.COWARDICE, 7);
        var spentState = State("cf_bt_manifest");
        spentState.SpentConfessionIds.Add("cf_bt_manifest");
        var lockedState = State("cf_bt_manifest");
        lockedState.LockedConfessionIds.Add("cf_bt_manifest");

        Assert.False(resolver.PlayCounter(attack, "cf_bt_manifest", spentState).Spent);
        Assert.False(resolver.PlayCounter(attack, "cf_bt_manifest", lockedState).Spent);
    }

    private static ConfessionDuelResolver Resolver(params Confession[] confessions)
    {
        return new ConfessionDuelResolver(confessions);
    }

    private static DuelState State(params string[] available)
    {
        return new DuelState(
            availableConfessionIds: available.ToHashSet(),
            spentConfessionIds: new HashSet<string>(),
            lockedConfessionIds: new HashSet<string>());
    }
}
