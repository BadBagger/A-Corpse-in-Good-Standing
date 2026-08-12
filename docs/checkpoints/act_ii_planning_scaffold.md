# CHECKPOINT: Act II Planning Scaffold

Act II is scaffolded as validated design data only. This intentionally does not create playable rooms, final dialogue, final art, or a Godot/Popochiu room graph, because Act I human review still gates production work beyond the demo boundary.

## GATES

| Gate | Status | Actual | Threshold |
|---|---:|---|---|
| Act II graph schema | PASS | `docs/act_ii_puzzle_dependency_graph.json` exists and parses | Graph exists, parses |
| Build-order guard | PASS | `planning_only_blocked_until_act_i_human_review` | Must not claim playable Act II |
| Clock model | PASS | narrative clock only; realtime countdown false | No realtime timer |
| Puzzle graph | PASS | 5 rooms, 29 nodes, 29 edges, acyclic | No missing refs, no cycles |
| Required spine | PASS | Kane offer -> seal -> Customs -> cut paper -> tide table -> Kestrel -> Tomas -> Sabine reveal | All required nodes reachable and completion-bound |
| Act availability | PASS | all listed confession unlocks are Act I/II only | No Act III confession available in Act II |
| COMMITTED unlock guard | PASS | committed confessions require committed-action nodes/edges | No passive COMMITTED acquisition |
| Betrayal endgame guard | PASS | `cf_bt_again` is forbidden until Act III | Never unlock before Act III |
| Float content line | PASS | hard-R non-explicit, agency tag, no Cold Girl tag | Section 2.3 guard preserved |
| Background source worklist | PASS | 5 rooms, 57 source tasks: 19 Meshy helpers, 15 generated refs, 15 interactive layers, 8 navigation silhouettes | Planning only; no final art before Act I human review |

## BLOCKERS

1. Act I human review is still required before Act II greybox production.
2. Act II hotspot/dialogue writing remains locked by the script note: do not write Act II dialogue until Act I has been in front of strangers.
3. Act II final art remains locked; source planning is now ready, but paintover and production sheets should wait.

## DEVIATIONS

None from the build brief. This is a planning scaffold, not an implementation checkpoint.

## NEXT

Use `tools/Run-ActIIPlanningGates.ps1` after any Act II planning change; when Act I review is accepted, convert the graph and source worklist into the Act II greybox room task list.
