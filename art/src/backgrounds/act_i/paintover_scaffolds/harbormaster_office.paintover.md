# R11 - Harbormaster's Office Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/harbormaster_office.psd`
- Blockout reference: `art/export/backgrounds/act_i/harbormaster_office_bg.png`
- Godot import target: `game/rooms/harbormaster_office/background/harbormaster_office_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-harbormaster_office`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: official amber restraint, frosted glass, checklist as the clearest prop
- Risk tags: general_layout_readability

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
- Checklist clerk at 960, 700: blocked_feedback, gated

Close-pair review:
- None under threshold.

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
