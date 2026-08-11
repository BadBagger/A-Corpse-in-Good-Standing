# R07 - The Almshouse - Meshy Ready Source Packet

Packet ID: R07_A_meshy_helper_geometry

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
| almshouse_meshy_source_model_cot_rows | `art/src/backgrounds/act_i/source_models/almshouse/cot_rows.glb` | `art/src/backgrounds/act_i/source_models/almshouse/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| almshouse_meshy_source_model_privacy_screens | `art/src/backgrounds/act_i/source_models/almshouse/privacy_screens.glb` | `art/src/backgrounds/act_i/source_models/almshouse/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| almshouse_meshy_source_model_prosper_sitting_silhouette_block | `art/src/backgrounds/act_i/source_models/almshouse/prosper_sitting_silhouette_block.glb` | `art/src/backgrounds/act_i/source_models/almshouse/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| almshouse_meshy_source_model_window_frame | `art/src/backgrounds/act_i/source_models/almshouse/window_frame.glb` | `art/src/backgrounds/act_i/source_models/almshouse/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |

## almshouse_meshy_source_model_cot_rows

- Source: `art/src/backgrounds/act_i/source_models/almshouse/cot_rows.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/almshouse.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Almshouse on Isla Mordida: cot rows. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/almshouse/cot_rows.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## almshouse_meshy_source_model_privacy_screens

- Source: `art/src/backgrounds/act_i/source_models/almshouse/privacy_screens.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/almshouse.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Almshouse on Isla Mordida: privacy screens. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/almshouse/privacy_screens.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## almshouse_meshy_source_model_prosper_sitting_silhouette_block

- Source: `art/src/backgrounds/act_i/source_models/almshouse/prosper_sitting_silhouette_block.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/almshouse.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Almshouse on Isla Mordida: Prosper sitting silhouette block. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/almshouse/prosper_sitting_silhouette_block.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## almshouse_meshy_source_model_window_frame

- Source: `art/src/backgrounds/act_i/source_models/almshouse/window_frame.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/almshouse.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for The Almshouse on Isla Mordida: window frame. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/almshouse/window_frame.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

