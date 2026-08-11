# R02 - The Old Quay Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/old_quay.psd`
- Blockout reference: `art/export/backgrounds/act_i/old_quay_blockout_bg.png`
- Godot import target: `game/rooms/old_quay/background/old_quay_blockout_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-old_quay`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: wet black pilings, bone bollards, sparse amber lamps, harbor slate negative space
- Risk tags: wet_readability, confession_source_readability, close_pair_spacing

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
- Bollard Tomas at 470, 720: conditional_followup, confession_source
- Empty flask at 1180, 760: item_reward
- Rope cleat at 720, 800: wet_verb, item_reward

Close-pair review:
- BollardLedger / SilentBollards at 40.3px

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
