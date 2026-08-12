# CHECKPOINT: Act II Greybox Scaffold

Act II now has registered greybox Popochiu rooms for the planned paper-trail spine. This is playable structure, not final writing or final art.

## GATES

| Gate | Status | Actual | Threshold |
|---|---:|---|---|
| Act II planning graph | PASS | 5 rooms, 29 nodes, 29 edges | Acyclic and planning-locked |
| Act II background source worklist | PASS | 57 source tasks | Planning-only source list exists |
| Popochiu registration | PASS | 5 Act II rooms registered | All planned rooms in `game/popochiu_data.cfg` |
| Room load/instantiate | PASS | 5 scenes load headless | No missing room data or scenes |
| Hotspot coverage | PASS | required exits and spine hotspots present | Kane, Float, Customs, Kestrel, Sabine return |
| Progression gates | PASS | seal, writ, cut paper, tide table, Tomas papers, Sabine reveal are gated | No major paper-trail skips |
| Confession unlocks | PASS | `cf_bt_harbor`, `cf_bt_tomas`, `cf_pride_kestrel` wired to Act II actions | No passive committed betrayal |

## BLOCKERS

1. This is still greybox. Final Act II dialogue expansion remains intentionally limited until Act I has a real playtest verdict.
2. Final Act II art remains blocked. Use the source worklist; do not paint rooms yet.
3. The rooms reuse the existing Act I greybox room/hotspot scripts. A later cleanup should rename these to act-neutral scripts when the room system stabilizes.

## DEVIATIONS

Act II uses the existing `act_i_flags` storage functions for temporary flags. This avoids save-state refactoring before the room loop is proven, but it should be cleaned up before Act II locks.

## NEXT

Add a deterministic Act II route recorder that proves Kane-to-Sabine progression end to end.
