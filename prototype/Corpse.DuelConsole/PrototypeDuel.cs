using Corpse.Duels;

namespace Corpse.DuelConsole;

public static class PrototypeDuel
{
    public static readonly string[] StarterPool =
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

    public static readonly string[] ScriptedWinCounters =
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

    public static List<Confession> CurrentOptions(DuelSession session, IReadOnlyDictionary<string, Confession> confessions)
    {
        return session.State.AvailableConfessionIds
            .Where(id => !session.State.SpentConfessionIds.Contains(id))
            .Where(id => !session.State.LockedConfessionIds.Contains(id))
            .Where(confessions.ContainsKey)
            .Select(id => confessions[id])
            .OrderBy(confession => confession.Category)
            .ThenBy(confession => confession.Weight)
            .ThenBy(confession => confession.Id)
            .ToList();
    }

    public static List<Confession> ValidCounters(Attack attack, IEnumerable<Confession> options)
    {
        return options
            .Where(confession => ConfessionDuelResolver.IsValidCounter(attack, confession))
            .ToList();
    }

    public static DuelSession CreateSession(Opponent opponent, IReadOnlyDictionary<string, Confession> confessions)
    {
        return new DuelSession(
            opponent,
            new ConfessionDuelResolver(confessions.Values),
            new DuelState(StarterPool.ToHashSet(), new HashSet<string>(), new HashSet<string>()));
    }
}
