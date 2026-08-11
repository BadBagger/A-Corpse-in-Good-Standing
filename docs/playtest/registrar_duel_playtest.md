# Registrar Duel Playtest

## Purpose

This is the human fun gate for Step 1. The automated checks prove the duel is legal and winnable; this playtest decides whether the loop is worth building the game around.

Play once blind before using debug mode.

## Run

```powershell
dotnet run --project prototype\Corpse.DuelConsole
```

To save the blind run notes directly into `docs/playtest/results`, use:

```powershell
dotnet run --project prototype\Corpse.DuelConsole -- --record-playtest
```

Optional after the blind run:

```powershell
dotnet run --project prototype\Corpse.DuelConsole -- --debug-valid
dotnet run --project prototype\Corpse.DuelConsole -- --balance
```

## Pass Criteria

Mark each as `yes`, `mixed`, or `no`.

```text
1. I understood why at least half my successful counters worked.
2. I understood why at least half my failed counters failed.
3. Spending a confession felt costly, not like disposable menu noise.
4. The lockout rule felt fair once an accusation dragged a confession out.
5. I wanted to read the elaboration after picking a confession.
6. The categories gave me a useful hint without solving the duel for me.
7. The Registrar felt like an opponent, not a quiz screen.
8. The final Betrayal choice felt like a meaningful escalation.
9. The duel made me want to collect more confessions elsewhere in the game.
10. I would rather tune this system than replace it.
```

## Notes To Capture

```text
Blind result:
  won / lost

Salt at end:

Most satisfying counter:

Most confusing counter:

Did any category feel mislabeled?

Did any attack feel too vague?

Did any valid counter feel emotionally wrong even if mechanically correct?

Did the choices feel too easy, too hard, or about right?

Keep / revise / kill:
```

## Decision

The prototype passes Step 1 only if the final answer is `keep` or `revise`. If the answer is `kill`, do not continue to Step 2; redesign the duel first.
