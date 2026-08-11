# R02 - The Old Quay - Meshy Ready Source Packet

Packet ID: R02_A_meshy_helper_geometry

Guardrails:
- This packet includes ready-to-generate source assets only.
- Do not generate final background plates from this packet.
- Do not include interactive or navigation PSD work in this packet.
- Save outputs exactly to the listed source paths.
- Run source intake again after files are saved.

Counts:
- Items: 4
- Tool: Meshy

| ID | Source | Drop Zone | Review Gate |
|---|---|---|---|
| old_quay_meshy_source_model_bollard_row | `art/src/backgrounds/act_i/source_models/old_quay/bollard_row.glb` | `art/src/backgrounds/act_i/source_models/old_quay/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| old_quay_meshy_source_model_dock_pilings | `art/src/backgrounds/act_i/source_models/old_quay/dock_pilings.glb` | `art/src/backgrounds/act_i/source_models/old_quay/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| old_quay_meshy_source_model_harbor_rail_fragments | `art/src/backgrounds/act_i/source_models/old_quay/harbor_rail_fragments.glb` | `art/src/backgrounds/act_i/source_models/old_quay/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| old_quay_meshy_source_model_rope_cleat | `art/src/backgrounds/act_i/source_models/old_quay/rope_cleat.glb` | `art/src/backgrounds/act_i/source_models/old_quay/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |

## old_quay_meshy_source_model_bollard_row

- Source: `art/src/backgrounds/act_i/source_models/old_quay/bollard_row.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/old_quay.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Old Quay on Isla Mordida: bollard row. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/old_quay/bollard_row.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## old_quay_meshy_source_model_dock_pilings

- Source: `art/src/backgrounds/act_i/source_models/old_quay/dock_pilings.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/old_quay.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Old Quay on Isla Mordida: dock pilings. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/old_quay/dock_pilings.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## old_quay_meshy_source_model_harbor_rail_fragments

- Source: `art/src/backgrounds/act_i/source_models/old_quay/harbor_rail_fragments.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/old_quay.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Old Quay on Isla Mordida: harbor rail fragments. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/old_quay/harbor_rail_fragments.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## old_quay_meshy_source_model_rope_cleat

- Source: `art/src/backgrounds/act_i/source_models/old_quay/rope_cleat.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/old_quay.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Old Quay on Isla Mordida: rope cleat. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/old_quay/rope_cleat.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

