namespace Corpse.Duels;

public enum SinCategory
{
    GREED = 0,
    LUST = 1,
    PRIDE = 2,
    CRUELTY = 3,
    COWARDICE = 4,
    BETRAYAL = 5
}

public sealed record Confession(
    string Id,
    string Text,
    string Elaboration,
    SinCategory Category,
    int Weight,
    int ActAvailable,
    string Acquisition);

public sealed record Attack(
    string Id,
    string Text,
    SinCategory Category,
    int Weight,
    string? LocksConfessionId = null);

public sealed record Opponent(
    string Id,
    string Name,
    int ActAvailable,
    IReadOnlyList<Attack> Attacks);

public sealed class DuelState
{
    public DuelState(
        HashSet<string> availableConfessionIds,
        HashSet<string> spentConfessionIds,
        HashSet<string> lockedConfessionIds,
        int salt = 0)
    {
        AvailableConfessionIds = availableConfessionIds;
        SpentConfessionIds = spentConfessionIds;
        LockedConfessionIds = lockedConfessionIds;
        Salt = salt;
    }

    public HashSet<string> AvailableConfessionIds { get; }
    public HashSet<string> SpentConfessionIds { get; }
    public HashSet<string> LockedConfessionIds { get; }
    public int Salt { get; set; }
}

public sealed record DuelResult(
    bool IsCorrect,
    bool Spent,
    int Damage,
    int SaltTaken,
    string CounterText,
    string Elaboration,
    string Reason);

public sealed record DuelTurnResult(
    DuelResult CounterResult,
    Attack Attack,
    int NextAttackIndex,
    int Salt,
    bool Won,
    bool Lost);

public sealed class ConfessionDuelResolver
{
    private readonly IReadOnlyDictionary<string, Confession> _confessions;

    public ConfessionDuelResolver(IEnumerable<Confession> confessions)
    {
        _confessions = confessions.ToDictionary(confession => confession.Id);
    }

    public static bool IsValidCounter(Attack attack, Confession counter)
    {
        return counter.Weight > attack.Weight && counter.Category >= attack.Category;
    }

    public DuelResult PlayCounter(Attack attack, string confessionId, DuelState state)
    {
        if (!_confessions.TryGetValue(confessionId, out var counter))
        {
            return new DuelResult(false, false, 0, 0, "", "", "Confession is not defined.");
        }

        if (!state.AvailableConfessionIds.Contains(confessionId))
        {
            return new DuelResult(false, false, 0, 0, counter.Text, counter.Elaboration, "Confession is not available.");
        }

        if (state.SpentConfessionIds.Contains(confessionId))
        {
            return new DuelResult(false, false, 0, 0, counter.Text, counter.Elaboration, "Confession has already been spent.");
        }

        if (state.LockedConfessionIds.Contains(confessionId))
        {
            return new DuelResult(false, false, 0, 0, counter.Text, counter.Elaboration, "Confession has been dragged out by an opponent.");
        }

        state.SpentConfessionIds.Add(confessionId);

        if (!IsValidCounter(attack, counter))
        {
            return new DuelResult(false, true, 0, 1, counter.Text, counter.Elaboration, "Counter does not outrank the attack.");
        }

        if (string.IsNullOrWhiteSpace(counter.Elaboration))
        {
            return new DuelResult(true, true, 1, 0, counter.Text, counter.Elaboration, "Correct counter without elaboration does half damage.");
        }

        return new DuelResult(true, true, 2, 0, counter.Text, counter.Elaboration, "Correct counter with willing elaboration.");
    }
}

public sealed class DuelSession
{
    private const int DamageRequiredToAnswerAttack = 2;
    private readonly Opponent _opponent;
    private readonly ConfessionDuelResolver _resolver;
    private readonly HashSet<int> _begunAttackIndexes = [];
    private int _currentAttackDamage;

    public DuelSession(Opponent opponent, ConfessionDuelResolver resolver, DuelState state)
    {
        _opponent = opponent;
        _resolver = resolver;
        State = state;
    }

    public DuelState State { get; }
    public int AttackIndex { get; private set; }
    public bool Won { get; private set; }
    public bool Lost { get; private set; }

    public Attack? CurrentAttack => AttackIndex < _opponent.Attacks.Count ? _opponent.Attacks[AttackIndex] : null;

    public Attack BeginCurrentAttack()
    {
        var attack = CurrentAttack ?? throw new InvalidOperationException("No attack is available.");
        if (_begunAttackIndexes.Add(AttackIndex) && !string.IsNullOrWhiteSpace(attack.LocksConfessionId))
        {
            State.LockedConfessionIds.Add(attack.LocksConfessionId);
        }

        return attack;
    }

    public DuelTurnResult Play(string confessionId)
    {
        if (Won || Lost)
        {
            throw new InvalidOperationException("Duel has already ended.");
        }

        var attack = BeginCurrentAttack();

        var result = _resolver.PlayCounter(attack, confessionId, State);
        if (result.IsCorrect && result.Damage > 0)
        {
            _currentAttackDamage += result.Damage;
            if (_currentAttackDamage >= DamageRequiredToAnswerAttack)
            {
                AttackIndex++;
                _currentAttackDamage = 0;
                Won = AttackIndex >= _opponent.Attacks.Count;
            }
        }
        else if (result.Spent)
        {
            State.Salt += result.SaltTaken;
            State.AvailableConfessionIds.Remove(confessionId);
        }

        if (result.IsCorrect && result.Spent)
        {
            State.AvailableConfessionIds.Remove(confessionId);
        }

        Lost = State.Salt >= 3;
        return new DuelTurnResult(result, attack, AttackIndex, State.Salt, Won, Lost);
    }
}
