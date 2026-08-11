# Act I Location Art Targets

This document maps the current Act I greybox into final-art planning notes. It is derived from the authored Act I script, the generated room scaffold, and the automated greybox playtest report. Use it before painting backgrounds, placing final hotspots, or asking Meshy/Blender for location props.

Locked gameplay note: the Registrar Confession Duel format stays unchanged. Do not add a second confession-spend interface in the Church, the Float, or any room texture pass.

Coordinate source: `docs/art/act_i_hotspot_map.csv` is generated from the current Godot room scenes with `tools/Export-ActIHotspotMap.ps1`. `docs/art/act_i_hotspot_overlay.svg` is the matching visual contact sheet for fast room-layout review, `docs/art/act_i_hotspot_layout_audit.md` records coordinate bounds plus close-pair review warnings, `docs/art/act_i_background_manifest.json` / `docs/art/act_i_background_brief.md` define the background source/export contract, `docs/art/act_i_background_asset_status.md` tracks present vs pending background assets, `docs/art/act_i_blockout_tasks.md` defines the Blender greybox proof tasks, `docs/art/act_i_background_palette_audit.md` records G9/G10 palette status for exported backgrounds, `docs/art/corvin_animation_manifest.json` defines Corvin's sprite-sheet contract, `docs/art/corvin_meshy_source_intake.json` records the current Meshy source intake, `docs/art/blender_corvin_import_probe.json` records the current Blender import preflight, `docs/art/ink_shader_spike_still_render_status.json` records the R1/R2 still-render proof, `docs/art/ink_shader_spike_still_image_audit.json` records the R1/R2 PNG image audit, and `docs/art/ink_shader_spike_manifest.json` defines the ink-wash shader proof contract. Regenerate these after changing room scaffold positions, hotspot wiring, the character animation plan, or the render pipeline.

## Global Composition Rules

- Native background target: 1920 x 1080.
- Camera style: side-on adventure-game staging, with Corvin usually read in profile or three-quarter profile.
- Walkable band: keep the primary navigation readable around y 650-800 unless a room explicitly needs a raised platform or desk barrier.
- Hotspot readability: the puzzle-relevant object should be the brightest readable shape in its local cluster.
- Hotspot coordinates must stay inside the 1920 x 1080 stage. Close-pair warnings in the generated layout audit are review prompts, not automatic failures; solve them with silhouette, lighting, spacing, or local interaction grouping before final background paint.
- `pending` in the generated asset-status report means production work remains. It is not a Step 4 failure until the art pass begins and the expected `.blend`, paintover, export PNG, and Godot import targets become required deliverables.
- The generated blockout tasks are the first art-pass checklist: prove camera framing, navigation pulls, critical hotspot silhouettes, wet-verb readability, and close-pair separation before paint.
- Palette discipline: bone/paper white `#E4DCC8`, wet black `#0C1013`, harbor slate `#2A3A40`, absinthe green `#7D9B4E`, whale-oil amber `#C98A3C`, arterial red `#8E1B22` only by explicit scene approval.
- The generated palette audit treats missing background exports as pending, but any exported PNG is checked at +/-13 RGB tolerance, must be at least 98% in-gamut, and contributes to the arterial-red scene count.
- Corvin's generated animation contract is deliberately heavier than the current greybox: three decay variants, four directions, five animation sets, 12 fps, and 129 tracked source/export/import slots. The side profile remains the production priority, but the contract budgets all required directions up front.
- The current Meshy intake treats `art/src/characters/corvin/meshy/corvin_act_i_clean.glb` as the canonical Act I clean source. The biped ZIP is useful reference/rig/motion material, but it does not satisfy the full animation contract without cleanup and custom wet/use cycles.
- The Blender import preflight creates `art/src/characters/corvin/corvin_act_i_clean.blend` and `art/src/shaders/ink_wash_shader_spike.blend` from the canonical GLB when Blender is available. These are starter sources, not final shader proof renders.
- The still-render proof produces `art/export/shader_spike/corvin_act_i_clean_side_raw.png` and `art/export/shader_spike/corvin_act_i_clean_side_ink_ramp.png`. These are R1/R2 proofs only; they do not clear the yaw hatching stability gate.
- The still image audit proves those R1/R2 PNGs are 1920x1080 and nonblank, and reports palette proximity without treating it as final G9 conformance.
- The ink-wash shader spike must be proved before final sprite-sheet production: 12 fps, 24-frame yaw turn, object/world-anchored hatching, screen-space bad control, pairwise delta plus first-to-last drift checks, locked-palette output, and no diffusion-per-frame production art.
- The metrics runner `tools/Test-InkShaderSpikeMetrics.ps1` is pending-friendly before renders exist, but once any yaw-turn sequence exists it requires at least 24 `frame_*.png` files and fails over-threshold hatching motion.
- Lighting grammar: amber means alive/warm/safe, green means wrong/institutional/Church, except the Grey Float, where amber is deliberately unsafe.

## Act I World Map

```text
Mudflats
  |
Old Quay
  |
Salt Market hub
  |-- Harbor Registry -- Registrar Duel -- Name Restored
  |-- Bone Chandler -- Almshouse -- Debt Forgiven
  |-- Fish Hall -- day-count proof
  |-- Church of the Drowned -- Grey Float -- Harbormaster Office -- Sabine Office
```

The Salt Market is the hub screen. Old Quay is the emotional return point. The three Rites should feel like separate districts feeding back into one public marketplace.

## R01 Mudflats

Purpose: tutorial wake-up, wetness, body read, first horizon view of Mordida.

Must-read art:
- Mud/silt foreground where Corvin wakes.
- Corvin's hands and wet coat readable enough for look/use tutorial beats.
- Harbor ribs visible in the background as the first large world signal.
- Exit pull toward Old Quay / Salt Market path.

Animation hooks:
- Coat drip idle.
- Sleeve wring/puddle beat.
- Barefoot step in mud for prologue-only silhouette.

## R02 Old Quay

Purpose: Tomas hint hub, day-nine bollard foreshadowing, fresh salt pickup.

Current hotspot anchors:
- Tomas at x 470, y 720.
- Bollard Petra at x 690, y 700.
- Ledger bollard at x 870, y 705.
- Bride bollard at x 1050, y 715.
- Empty flask at x 1180, y 760.
- Rope cleat at x 720, y 800.

Must-read art:
- Three individual silent bollards as a row, not background noise.
- Tomas distinct from the others: still conversational, still humiliatingly useful.
- Rope cleat close enough to Corvin's hand height to sell scraping knuckle salt.
- Flask visible but trash-like; it should not compete with Tomas.

Implemented conditional beat:
- Talking to Tomas after Petra, the ledger bollard, and the bride bollard have all been addressed triggers the all-three-bollards follow-up and sets `FL_bollard_row_reported`. This stays a normal Tomas interaction, not a new confession system.

## R03 Salt Market

Purpose: Act I hub, public recognition scream, early eavesdrops, route fan-out.

Current exits:
- Old Quay, Harbor Registry, Bone Chandler, Almshouse, Fish Hall, Church.

Current hotspot anchors:
- Boot stall at x 300, y 720.
- Fishmonger/two scales at x 520, y 720.
- Market crowd at x 960, y 760.
- Confession queue at x 1180, y 720.
- Church sign at x 1380, y 540.
- Whale-oil lamp at x 1520, y 620.

Must-read art:
- Scattered boots after recognition.
- Fishmonger has honest scales visible and dishonest scales tucked under/behind.
- Confession queue reads as eleven deep without needing eleven detailed portraits.
- Church tariff sign must be legible enough to sell the wet-ink gag.
- Whale-oil lamp gives amber warmth Corvin cannot feel.

Palette:
- Dominant harbor slate and wet black.
- Amber pools around living commerce.
- Green should pull the eye toward Church economy, not tint the whole room.

## R05 Harbor Registry

Purpose: Name Restored Rite, Kestrel ledger theft, Registrar duel setup.

Current hotspot anchors:
- Ledgers wall at x 420, y 660.
- Open roll book at x 640, y 700.
- Desk lamp at x 890, y 650.
- Registrar at x 980, y 690.
- Kestrel ledger at x 1220, y 610.

Must-read art:
- Ledgers as oppressive architecture, not just bookshelves.
- Roll book open enough to stage the scratched-out VALE line.
- Desk lamp placed so wetting it visually distracts the Registrar.
- Kestrel ledger behind or above the Registrar's controlled space.

Duel boundary:
- Final art may frame the Registrar as a duel opponent, but the accepted Litany selector flow and route stay untouched.

## R06 Bone Chandler

Purpose: recover Prosper's watch by trading fresh returned salt.

Current hotspot anchors:
- Wares at x 560, y 700.
- Chess set at x 790, y 680.
- Prosper's watch at x 1010, y 700.

Must-read art:
- Shop inventory made from returned remains should read before the player reads text.
- Chess set should show old white pieces versus newer dark pieces.
- Watch must be clearly under glass / behind counter until the salt trade.

Tone:
- Keep body-horror artisanal rather than gory. No red accent unless a later pass explicitly budgets it.

## R07 Almshouse

Purpose: Prosper's memory rot and Debt Forgiven Rite.

Current hotspot anchors:
- Cots at x 560, y 720.
- Window at x 780, y 650.
- Half-Coin Prosper at x 980, y 700.

Must-read art:
- Rows of cots with three quiet, maybe-too-still occupants.
- Window facing the harbor.
- Prosper pleasant, unstable, and freshly met every time.
- Writing surface for the debt forgiveness document.

Animation hooks:
- Prosper smile reset / re-meeting beat.
- Hand-memory hesitation before he signs.

## R08 Fish Hall

Purpose: day-count proof and proof Sabine did not visit the body.

Current hotspot anchors:
- Ice table at x 610, y 720.
- Coroner tag at x 960, y 710.
- Visitor book at x 1260, y 690.
- Drain at x 1500, y 780.

Must-read art:
- Ice table with Corvin-shaped absence.
- Coroner tag readable as object silhouette.
- Visitor book positioned as an official record, not random clutter.
- Drain tied visually to harbor return/wet verb.

Design note:
- Keep this room cold and factual. It should feel less dramatic than it is.

## R09 Church Of The Drowned

Purpose: confession economy, Teodor pressure, chit/rate-card setup.

Current hotspot anchors:
- Poor box at x 620, y 720.
- Confession booth at x 780, y 650.
- Teodor's stall/rate card at x 940, y 700.
- Church stall sign at x 1100, y 585.

Must-read art:
- Green institutional light.
- Poor box with crooked reattached lock.
- Booth/stall distinction readable enough to support the joke.
- Teodor visibly sweating through doctrine.
- Queue implies paid grief and inventory, not spectacle.

Duel boundary:
- Do not implement the deferred petitioner-choice/confession-spend booth sequence during this pass. Teodor's scene stays a fixed authored beat.

## R10 Grey Float

Purpose: Borrowed Heartbeat setup, Juno, regulator, warmth.

Current hotspot anchors:
- Juno's table at x 450, y 675.
- Staff corner at x 620, y 710.
- Bilge regulator at x 900, y 700.
- Hot pool at x 1220, y 720.
- Steam screen at x 1450, y 650.

Must-read art:
- The Float is amber-lit but unsafe. This is the exception to the palette rule.
- Juno's table should be a power desk: ledgers, rings, chair nobody borrows.
- Regulator reads as a clockwork heart substitute.
- Steam screen uses silhouette/backlight per hard-R line, never explicit anatomy.
- Staff corner should show workers as people with grievances, not decoration.

Animation hooks:
- Steam layers.
- Slow barge rocking.
- Hot-pool warmth state could use a temporary amber skin overlay on Corvin.

## R11 Harbormaster Office

Purpose: fake pulse/warmth check and final gate before Sabine.

Current hotspot anchors:
- Checklist desk at x 740, y 690.
- Checklist clerk at x 960, y 700.
- Sabine's door at x 1500, y 665.

Must-read art:
- Three boxes beside Corvin's name on the checklist.
- Frosted glass door with Sabine Croix painted in black.
- Clerk positioned as procedural obstruction, not villain.
- One-room-away tension: Sabine's presence should be felt before she appears.

Animation hooks:
- Regulator knock inside coat.
- Clerk pulse check / pen mark.
- Warmth-expired failure should be readable by Corvin's color returning to cold.

## R12 Sabine Office

Purpose: Act I finale, standing restored, wrist/no-pulse romance beat.

Current hotspot anchor:
- Sabine's desk at x 960, y 690.

Must-read art:
- Sabine's desk dry, organized, and dominant.
- Corvin's water pooling on the floor.
- Sabine crosses through the water without reacting.
- Wrist check should be staged with room for silence.

Character rule:
- Sabine never apologizes. Poses, expressions, and VO direction should support explanation without apology.

## Pre-Final-Art Checklist

- Confirm every final background keeps current exits readable.
- Confirm every listed hotspot in `act_i_hotspot_map.csv` and `act_i_hotspot_overlay.svg` remains visible at 1080p before adding decorative detail.
- Build one Corvin side-profile test animation before committing to full room paint.
- Validate the ink-wash/hatching shader on a yaw turn, not only a walk.
- Preserve the accepted Registrar duel route and Litany UI behavior.
- Keep Teodor's deferred booth-choice system out of Act I greybox until a separate mechanic decision is made.
