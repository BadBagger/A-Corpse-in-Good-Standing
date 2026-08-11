# R08 - The Fish Hall Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/fish_hall.psd`
- Blockout reference: `art/export/backgrounds/act_i/fish_hall_bg.png`
- Godot import target: `game/rooms/fish_hall/background/fish_hall_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-fish_hall`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: ice table and tag as brightest proof objects, cold slate, minimal amber
- Risk tags: wet_readability, confession_source_readability

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
- Visitor book at 1260, 690: confession_source
- Coroner tag at 960, 710: item_reward
- Drain at 1500, 780: wet_verb

Close-pair review:
- None under threshold.

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
