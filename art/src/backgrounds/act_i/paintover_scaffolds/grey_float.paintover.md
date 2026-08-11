# R10 - The Grey Float Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/grey_float.psd`
- Blockout reference: `art/export/backgrounds/act_i/grey_float_bg.png`
- Godot import target: `game/rooms/grey_float/background/grey_float_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-grey_float`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: the only unsafe amber room; steam silhouettes and warm privacy without explicit depiction
- Risk tags: confession_source_readability, hard_r_float_staging, unsafe_amber_exception

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
- Bilge regulator at 900, 700: blocked_feedback, item_reward, gated
- Staff corner at 620, 710: confession_source
- Hot pool at 1220, 720: blocked_feedback, gated

Close-pair review:
- None under threshold.

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
