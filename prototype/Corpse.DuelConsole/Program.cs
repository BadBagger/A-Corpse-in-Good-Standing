using Corpse.Duels;
using Corpse.DuelConsole;

var root = FindRepoRoot();
var confessionsPath = Path.Combine(root, "data", "confessions.json");
var registrarPath = Path.Combine(root, "duels", "opponents", "registrar.json");

var confessions = DuelContent.LoadConfessions(confessionsPath).ToDictionary(confession => confession.Id);
var opponent = DuelContent.LoadOpponent(registrarPath);
var scriptedWin = args.Contains("--scripted-win");
var debugValid = args.Contains("--debug-valid");
var balance = args.Contains("--balance");
var recordPlaytest = args.Contains("--record-playtest");
var help = args.Contains("--help") || args.Contains("-h");
if (help)
{
    Console.WriteLine("A Corpse in Good Standing - Registrar duel prototype");
    Console.WriteLine();
    Console.WriteLine("Usage:");
    Console.WriteLine("  dotnet run --project prototype/Corpse.DuelConsole");
    Console.WriteLine("  dotnet run --project prototype/Corpse.DuelConsole -- --scripted-win");
    Console.WriteLine("  dotnet run --project prototype/Corpse.DuelConsole -- --balance");
    Console.WriteLine("  dotnet run --project prototype/Corpse.DuelConsole -- --debug-valid");
    Console.WriteLine("  dotnet run --project prototype/Corpse.DuelConsole -- --record-playtest");
    return 0;
}

if (balance)
{
    PrintBalanceReport(opponent, confessions);
    return 0;
}

var session = PrototypeDuel.CreateSession(opponent, confessions);
var scriptedCounters = new Queue<string>(PrototypeDuel.ScriptedWinCounters);

Console.WriteLine("A CORPSE IN GOOD STANDING");
Console.WriteLine("Confession Duel Prototype: The Registrar");
Console.WriteLine("Pick a confession by number. Wrong answers still spend the card. Three Salt loses.");
Console.WriteLine();

while (!session.Won && !session.Lost)
{
    var attack = session.BeginCurrentAttack();
    Console.WriteLine($"ACCUSATION {session.AttackIndex + 1}/{opponent.Attacks.Count} - Salt {session.State.Salt}/3");
    Console.WriteLine($"REGISTRAR: \"{attack.Text}\"");
    if (!string.IsNullOrWhiteSpace(attack.LocksConfessionId) && confessions.TryGetValue(attack.LocksConfessionId, out var locked))
    {
        Console.WriteLine($"[Dragged out: {locked.Id} is locked for this duel.]");
    }
    Console.WriteLine();

    var options = PrototypeDuel.CurrentOptions(session, confessions);
    var validCounters = PrototypeDuel.ValidCounters(attack, options);

    for (var i = 0; i < options.Count; i++)
    {
        var confession = options[i];
        var marker = debugValid && validCounters.Any(valid => valid.Id == confession.Id) ? " *" : "";
        Console.WriteLine($"{i + 1,2}. [{confession.Category} {confession.Weight}] {confession.Text} ({confession.Id}){marker}");
    }

    var selectedId = scriptedWin
        ? scriptedCounters.Dequeue()
        : PromptForChoice(options);

    var selected = confessions[selectedId];
    Console.WriteLine();
    Console.WriteLine($"CORVIN: \"{selected.Text}\"");
    var result = session.Play(selectedId);
    if (result.CounterResult.IsCorrect)
    {
        Console.WriteLine($"CORVIN: \"{selected.Elaboration}\"");
        Console.WriteLine($"[Accepted. Damage {result.CounterResult.Damage}.]");
    }
    else
    {
        Console.WriteLine($"[Rejected. {result.CounterResult.Reason} Salt {session.State.Salt}/3.]");
    }
    Console.WriteLine();
}

Console.WriteLine(session.Won
    ? "RESULT: Corvin wins. The Registrar writes his name back."
    : "RESULT: Corvin loses. The Registrar will be selling those truths by supper.");

if (recordPlaytest)
{
    WritePlaytestRecord(root, session);
}

return session.Won ? 0 : 2;

static string PromptForChoice(IReadOnlyList<Confession> options)
{
    while (true)
    {
        Console.Write("> ");
        var raw = Console.ReadLine();
        if (int.TryParse(raw, out var index) && index >= 1 && index <= options.Count)
        {
            return options[index - 1].Id;
        }
        Console.WriteLine($"Choose a number from 1 to {options.Count}.");
    }
}

static void PrintBalanceReport(Opponent opponent, IReadOnlyDictionary<string, Confession> confessions)
{
    var session = PrototypeDuel.CreateSession(opponent, confessions);
    var scriptedCounters = new Queue<string>(PrototypeDuel.ScriptedWinCounters);
    Console.WriteLine("Registrar duel balance report");
    Console.WriteLine("round,attack,options,valid,scripted_counter,scripted_valid");

    while (!session.Won && !session.Lost)
    {
        var attack = session.BeginCurrentAttack();
        var options = PrototypeDuel.CurrentOptions(session, confessions);
        var validCounters = PrototypeDuel.ValidCounters(attack, options);
        var scriptedCounter = scriptedCounters.Dequeue();
        var scriptedValid = validCounters.Any(counter => counter.Id == scriptedCounter);
        Console.WriteLine($"{session.AttackIndex + 1},{attack.Id},{options.Count},{validCounters.Count},{scriptedCounter},{scriptedValid}");
        session.Play(scriptedCounter);
    }
}

static void WritePlaytestRecord(string root, DuelSession session)
{
    Console.WriteLine();
    Console.WriteLine("PLAYTEST NOTES");
    Console.WriteLine("Answer yes, mixed, or no for the numbered prompts. Short notes are fine elsewhere.");
    Console.WriteLine();

    var criteria = new[]
    {
        "I understood why at least half my successful counters worked.",
        "I understood why at least half my failed counters failed.",
        "Spending a confession felt costly, not like disposable menu noise.",
        "The lockout rule felt fair once an accusation dragged a confession out.",
        "I wanted to read the elaboration after picking a confession.",
        "The categories gave me a useful hint without solving the duel for me.",
        "The Registrar felt like an opponent, not a quiz screen.",
        "The final Betrayal choice felt like a meaningful escalation.",
        "The duel made me want to collect more confessions elsewhere in the game.",
        "I would rather tune this system than replace it."
    };

    var answers = new List<string>();
    for (var i = 0; i < criteria.Length; i++)
    {
        answers.Add(PromptForText($"{i + 1}. {criteria[i]}"));
    }

    var satisfying = PromptForText("Most satisfying counter");
    var confusing = PromptForText("Most confusing counter");
    var mislabeled = PromptForText("Did any category feel mislabeled?");
    var vague = PromptForText("Did any attack feel too vague?");
    var emotionallyWrong = PromptForText("Did any valid counter feel emotionally wrong even if mechanically correct?");
    var difficulty = PromptForText("Did the choices feel too easy, too hard, or about right?");
    var decision = PromptForDecision();

    var resultsDir = Path.Combine(root, "docs", "playtest", "results");
    Directory.CreateDirectory(resultsDir);
    var filename = $"registrar_duel_{DateTime.Now:yyyyMMdd_HHmmss}.md";
    var path = Path.Combine(resultsDir, filename);

    var lines = new List<string>
    {
        "# Registrar Duel Playtest Result",
        "",
        $"Date: {DateTime.Now:yyyy-MM-dd HH:mm:ss}",
        $"Blind result: {(session.Won ? "won" : "lost")}",
        $"Salt at end: {session.State.Salt}/3",
        "",
        "## Criteria",
        ""
    };

    for (var i = 0; i < criteria.Length; i++)
    {
        lines.Add($"{i + 1}. {criteria[i]}");
        lines.Add($"   - {answers[i]}");
    }

    lines.AddRange([
        "",
        "## Notes",
        "",
        $"Most satisfying counter: {satisfying}",
        "",
        $"Most confusing counter: {confusing}",
        "",
        $"Did any category feel mislabeled? {mislabeled}",
        "",
        $"Did any attack feel too vague? {vague}",
        "",
        $"Did any valid counter feel emotionally wrong even if mechanically correct? {emotionallyWrong}",
        "",
        $"Did the choices feel too easy, too hard, or about right? {difficulty}",
        "",
        $"Decision: {decision}",
        ""
    ]);

    File.WriteAllLines(path, lines);
    Console.WriteLine();
    Console.WriteLine($"Saved playtest notes: {path}");
}

static string PromptForText(string prompt)
{
    Console.Write($"{prompt}: ");
    return Console.ReadLine()?.Trim() ?? "";
}

static string PromptForDecision()
{
    while (true)
    {
        var decision = PromptForText("Keep / revise / kill").ToLowerInvariant();
        if (decision is "keep" or "revise" or "kill")
        {
            return decision;
        }

        Console.WriteLine("Enter keep, revise, or kill.");
    }
}

static string FindRepoRoot()
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
