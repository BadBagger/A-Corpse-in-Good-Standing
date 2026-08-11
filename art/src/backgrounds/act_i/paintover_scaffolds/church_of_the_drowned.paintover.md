# R09 - Church of the Drowned Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/church_of_the_drowned.psd`
- Blockout reference: `art/export/backgrounds/act_i/church_of_the_drowned_bg.png`
- Godot import target: `game/rooms/church_of_the_drowned/background/church_of_the_drowned_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-church_of_the_drowned`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: absinthe-green institutional wrongness, bone paperwork, Church commerce staging
- Risk tags: confession_source_readability

Layer stack:

- 00_blockout_reference_locked
- 01_palette_keys_locked
- 02_value_silhouette_pass
- 03_navigation_and_walk_band
- 04_puzzle_hotspot_readability
- 05_local_lighting_amber_green
- 06_ink_hatching_texture
- 07_final_paint
- 08_export_notes

Critical hotspots:
- Confession booth at 780, 650: item_reward
- Teodor's stall at 940, 700: blocked_feedback, confession_source, item_reward, gated
- Poor box at 620, 720: confession_source

Close-pair review:
- None under threshold.

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
