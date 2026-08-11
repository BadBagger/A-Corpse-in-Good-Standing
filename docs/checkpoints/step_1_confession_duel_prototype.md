# Step 1 Checkpoint - Confession Duel Prototype

## Scope

This checkpoint covers the isolated Confession Duel prototype only:

- 1 opponent: The Registrar
- 12 player confessions in the prototype starter pool
- no Godot, Popochiu, Ink runtime binding, rooms, or art
- standalone `net8.0` C# domain library with a separate test assembly
- playable console prototype for human review

Per the build brief, do not begin room scaffolding until this checkpoint has been played and accepted.

## Current Build

- Domain logic: `duels/Corpse.Duels`
- Opponent data: `duels/opponents/registrar.json`
- Generated confession data: `data/confessions.json`
- Tests: `tests/Corpse.Duels.Tests`
- Console prototype: `prototype/Corpse.DuelConsole`

## Playtest Commands

```powershell
dotnet run --project prototype\Corpse.DuelConsole
dotnet run --project prototype\Corpse.DuelConsole -- --debug-valid
dotnet run --project prototype\Corpse.DuelConsole -- --balance
dotnet run --project prototype\Corpse.DuelConsole -- --record-playtest
```

Use the normal mode first. Use `--debug-valid` only after a blind run, because it marks mechanically valid counters.
Use `--record-playtest` when the blind run should be saved under `docs/playtest/results`.

Use `docs/playtest/registrar_duel_playtest.md` to record the fun-gate decision.

## Automated Gate Command

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step1Gates.ps1
```

## Prototype Starter Pool

```text
cf_greed_boots
cf_pride_list
cf_lust_float
cf_lust_schedule
cf_pride_grammar
cf_pride_counselor
cf_cruel_soupline
cf_cruel_sentences
cf_cow_leftroom
cf_cow_bigger
cf_cow_passive
cf_bt_manifest
```

## Implemented Rules

- A counter must strictly exceed the attack weight.
- A counter category must match or trump the attack category.
- A wrong counter is still permanently spent and adds 1 Salt.
- Three Salt loses the duel.
- Opponent-spoken confessions are locked out of the player's defense pool.
- A correct confession with elaboration deals 2 damage and clears the accusation.
- A correct confession without elaboration deals 1 damage; the accusation remains until 2 total damage is reached.

## Validated Gates

```text
G3/G14: PASS
  total=62
  GREED=12
  LUST=12
  PRIDE=12
  CRUELTY=11
  COWARDICE=11
  BETRAYAL=4

G13: PASS
  registrar attacks=8
  each attack has >=2 valid starter counters before first encounter
  scripted path keeps >=2 valid choices before each selection

Unit tests: PASS
  14/14

Console smoke: PASS
  scripted Registrar win succeeds
```

Latest balance snapshot:

```text
round,attack,options,valid,scripted_counter,scripted_valid
1,reg_manifest,12,6,cf_cruel_sentences,True
2,reg_collection_plate,11,11,cf_greed_boots,True
3,reg_clients_voice,10,8,cf_pride_list,True
4,reg_soup_line,8,4,cf_cow_bigger,True
5,reg_left_room,6,2,cf_cow_passive,True
6,reg_float,4,4,cf_lust_schedule,True
7,reg_counselor,3,3,cf_pride_counselor,True
8,reg_kestrel_number,2,2,cf_bt_manifest,True
```

## Blocker

The remaining Step 1 gate is not automated: Kyle must play the prototype and decide whether the 12-confession loop is fun enough to keep, revise, or kill before Step 2.
