# R03 - Salt Market Paintover Source Scaffold

This is a scaffold for the pending paintover source, not final art.

- Target PSD: `art/src/backgrounds/act_i/salt_market.psd`
- Blockout reference: `art/export/backgrounds/act_i/salt_market_bg.png`
- Godot import target: `game/rooms/salt_market/background/salt_market_bg.png`
- Hotspot overlay: `docs/art/act_i_hotspot_overlay.svg#room-salt_market`
- Camera: 1920x1080 fixed side-on, walk band y 650-800
- Tone: busy public hub, amber life pockets against slate street, boots and queue readable at a glance
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
- Church sign at 1380, 540: wet_verb
- Boot stall at 300, 720: gated
- Fishmonger at 520, 720: confession_source
- Confession queue at 1180, 720: confession_source
- Crowd at 960, 760: confession_source, item_reward

Close-pair review:
- Fishmonger / ToRegistry at 70px
- ConfessionQueue / ToAlmshouse at 88.5px

Paintover lock notes:
- Do not move hotspot centers without updating Godot scenes and regenerating the hotspot map.
- Do not create or mark the target PSD complete until final paint exists.
- Exported PNG must pass G9/G10 palette audit before it can ship.
- Registrar duel scenes must preserve the accepted Litany UI format.
- Grey Float must stay hard-R through steam, silhouette, privacy, and labor staging only.
