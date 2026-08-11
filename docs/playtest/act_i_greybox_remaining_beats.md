# Act I Greybox Remaining Beats Review

Purpose: turn the Step 4 "compressed scene" blocker into a concrete review list before final art.

Inputs:
- `docs/script/act_i_full_script_build_document.md`
- `docs/playtest/results/act_i_greybox_auto_report.md`
- `docs/checkpoints/step_4_act_i_greybox_room_graph.md`

## Current Read

The Act I greybox is mechanically playable end to end. The three Rites are solvable in any order, Sabine stays blocked until all three are complete, and the accepted Registrar duel format is preserved.

The remaining issue is not broken progression. It is review readiness: several beats are implemented as first-pass greybox pacing rather than final scene direction, UI polish, VO timing, or final art layout.

## Locked During Greybox

These are intentionally not expanded before the next human playtest:

| Beat | Decision | Reason |
|---|---|---|
| Registrar duel route | Keep accepted eight-counter format | User accepted the duel format; room work must not disturb it. |
| Second confession-spend UI | Do not add | The Teodor petitioner booth remains a fixed authored beat so it does not create a competing duel/spend interface. |
| Act II/III confession grants mentioned in Act I script | Keep deferred | The Litany source of truth marks them later, and G15 forbids early acquisition. |
| Final animation/audio/visual skin | Defer | Needs human pacing feedback first, especially with full VO selected. |
| Final room paintover/layout lock | Defer | Greybox interaction density and sightlines should be playtested first. |

## Resolved Since First Step 4

| Area | Current status |
|---|---|
| Tomas returned-rule intro | Expanded and protected by Ink bridge validation. |
| Tomas Act I hint hub | Expanded with memory decay, Registry, Prosper, Borrowed Heartbeat, self-knowledge, and route pressure beats. |
| Fish Hall | Blockout, export, Godot background, day-count proof, drain wet beat, and Act I-safe confession handling are present. |
| Church / Teodor | Chit booth, rate-card gate, posting panic, three fixed petitioner beats, `FL_kane_seen`, and Kane pressure line are wired. |
| Act I background coverage | 11 room exports present; final paintover source files remain pending by design. |
| Palette audit | Current Act I exports pass the automated G9/G10 audit with no arterial-red scene usage. |

## Remaining Review Candidates

| Candidate | What to Check | Action After Playtest |
|---|---|---|
| Registrar duel readability | Can a blind player understand attack category, weight pressure, Salt, spent cards, and why a counter failed? | Tune UI copy, animation, audio stings, and input focus without changing duel rules. |
| Three Rite pacing | Does each Rite feel like a complete Monkey Island-style branch rather than a checklist item? | Expand or trim room beats based on where the player stalls or skims. |
| Teodor booth | Does the fixed petitioner/Kane sequence land emotionally without feeling like a missing choice interface? | Keep fixed if it works; only revisit confession spending after the accepted duel is still fun in context. |
| Full VO timing | Are lines short enough when spoken, and do jokes still trade fast? | Cut lines before recording, especially repeated hint or exposition beats. |
| Room sightlines | Are puzzle-relevant props brightest and readable in greybox positions? | Lock camera/object placement before paintover. |
| Wet verb discoverability | Does the player learn that wet is a reusable verb instead of one tutorial gag? | Add in-world nudges if the player forgets it after Mudflats. |
| Act I source contradictions | Do script-mentioned later confessions confuse implementation review? | Keep Litany act gates authoritative unless Kyle explicitly revises the library. |

## Next Gate Recommendation

Run `tools/Start-ActIHumanPlaytest.ps1 -RefreshAutomatedReport` for one human Act I greybox playtest from cold start using `docs/playtest/act_i_human_greybox_playtest.md` and the automated report as the expected route, then record specific line-level cuts, expansions, and prop-readability fixes before final art.
