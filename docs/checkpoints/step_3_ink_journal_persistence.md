# Step 3 Checkpoint - Ink, Journal, Confession Persistence

## Scope

This checkpoint starts Step 3 after the prologue scaffold.

Implemented now:

- Official `inklecate` Windows compiler v1.2.1 under `tools/ink`.
- Prologue Ink source: `ink/prologue.ink`.
- Confession ID contract file: `ink/confessions.ink`.
- Generated Ink JSON output: `ink/build/prologue.ink.json`.
- Ink validation script:
  - compiles prologue Ink
  - verifies confession tags reference IDs from `data/confessions.json`
  - verifies journal tags reference runtime journal IDs
  - verifies item tags reference Popochiu inventory IDs
  - rejects unsupported gameplay tags
  - fails if Ink duplicates confession text
- Standalone `net8.0` narrative domain library: `narrative/Corpse.Narrative`.
- Journal state model with text-only degradation.
- Global confession ledger:
  - discovered
  - spent
  - opponent-spoken locked
- JSON save/load for narrative state.
- Tests for journal, global spent-state, opponent lockout, tag processing, and JSON persistence.
- Godot runtime narrative autoload: `N` at `game/autoloads/narrative_state.gd`.
- Godot Ink tag bridge autoload: `InkBridge` at `game/autoloads/ink_bridge.gd`.
- Runtime bridge validation: `tools/godot_validate_ink_bridge.gd`.
- Compiled Ink line extraction for speaker/text playback from named knots.
- Prologue HUD journal and Litany summary panels.
- Prologue HUD dialogue panel fed by authored Ink text.
- Mudflats interactions now apply tags from named Ink knots through `InkBridge`.
- Narrative state snapshot/restore hooks:
  - `N.to_snapshot()`
  - `N.apply_snapshot(snapshot)`
  - `N.clear_runtime_state()`
- Popochiu Globals save/load bridge:
  - `game/popochiu_globals.gd:on_save()`
  - `game/popochiu_globals.gd:on_load(data)`
- Popochiu slot-file validation through `E.save_game(4, "STEP3_NARRATIVE_VALIDATION")`.
- Popochiu load validation through `E.load_game(4)`.
- Corvin greybox sprite flip proxy so Popochiu can flip the placeholder polygon during room load.

Not implemented yet:

- Godot C# runtime bridge for reading the compiled Ink story during play.
- Full Ink story choice/branch runtime in Godot.
- Production save/load UI and slot selection flow.

## Automated Gate Command

```powershell
powershell -ExecutionPolicy Bypass -File tools\Run-Step3Gates.ps1
```

## Current Evidence

Latest run:

```text
Step 1 automated gates passed.
Step 2 automated gates passed.
Ink compile passed.
Ink validation passed: tags checked against runtime contract.
Godot Ink bridge validation passed.
Narrative snapshot and Popochiu Globals hook roundtrip passed.
Popochiu slot 4 save file contains and restores narrative custom data.
Popochiu `E.load_game(4)` restores narrative custom data from the slot.
Corpse.Narrative.Tests: 5/5 passed.
Step 3 automated gates passed.
```

## Runtime Notes

The Godot narrative autoload is intentionally small and mirrors the tested C# domain contract:

- `add_journal(id)`
- `degrade_journal(id)`
- `discover_confession(id)`
- `spend_confession(id)`
- `lock_opponent_spoken_confession(id)`

It saves to `user://narrative_state.json` so the prologue scaffold can prove persistence without forcing the duel library to import Godot types.

`InkBridge` reads compiled Ink JSON from `ink/build/prologue.ink.json`, extracts exported tags for a named knot, and applies supported tags through `N`. Current room scripting uses this as a bridge, not as a full Ink runtime.

`InkBridge.play_knot(knot_name)` now returns authored dialogue lines as dictionaries:

```text
speaker, text, tags
```

The Mudflats scaffold uses this to fill the HUD dialogue panel while applying journal, Litany, and item tags from the same authored Ink knot.

Ink authoring rule: `#` lines are runtime tags. Use `//` for comments. The gate rejects unsupported `#` tags so notes do not accidentally become runtime metadata.

Popochiu integration note: Popochiu's save system serializes `game/popochiu_globals.gd` via `on_save()` and restores it via `on_load(custom_data)`. The current bridge stores `N.to_snapshot()` under `custom_data.narrative` and restores it with `N.apply_snapshot()`.

The runtime validator writes Popochiu slot 4 with `E.save_game(4, "STEP3_NARRATIVE_VALIDATION")`, checks that `globals.custom_data.narrative` contains journal, Litany, and item state, clears `N`, then verifies `E.load_game(4)` restores that narrative state. It restores or removes the previous slot 4 file afterward.

Corvin's temporary polygon body now uses `game/characters/corvin/polygon_flip_proxy.gd`, which gives the placeholder `Sprite2D` node a `flip_h` property compatible with Popochiu's character loader.
