# R03 - Salt Market - Meshy Ready Source Packet

Packet ID: R03_A_meshy_helper_geometry

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
| salt_market_meshy_source_model_boot_stall | `art/src/backgrounds/act_i/source_models/salt_market/boot_stall.glb` | `art/src/backgrounds/act_i/source_models/salt_market/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| salt_market_meshy_source_model_crowd_silhouette_blockers | `art/src/backgrounds/act_i/source_models/salt_market/crowd_silhouette_blockers.glb` | `art/src/backgrounds/act_i/source_models/salt_market/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| salt_market_meshy_source_model_hanging_lamps | `art/src/backgrounds/act_i/source_models/salt_market/hanging_lamps.glb` | `art/src/backgrounds/act_i/source_models/salt_market/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| salt_market_meshy_source_model_market_stall_shells | `art/src/backgrounds/act_i/source_models/salt_market/market_stall_shells.glb` | `art/src/backgrounds/act_i/source_models/salt_market/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |

## salt_market_meshy_source_model_boot_stall

- Source: `art/src/backgrounds/act_i/source_models/salt_market/boot_stall.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/salt_market.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Salt Market on Isla Mordida: boot stall. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/salt_market/boot_stall.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## salt_market_meshy_source_model_crowd_silhouette_blockers

- Source: `art/src/backgrounds/act_i/source_models/salt_market/crowd_silhouette_blockers.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/salt_market.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Salt Market on Isla Mordida: crowd silhouette blockers. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/salt_market/crowd_silhouette_blockers.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## salt_market_meshy_source_model_hanging_lamps

- Source: `art/src/backgrounds/act_i/source_models/salt_market/hanging_lamps.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/salt_market.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Salt Market on Isla Mordida: hanging lamps. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/salt_market/hanging_lamps.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## salt_market_meshy_source_model_market_stall_shells

- Source: `art/src/backgrounds/act_i/source_models/salt_market/market_stall_shells.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/salt_market.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Salt Market on Isla Mordida: market stall shells. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/salt_market/market_stall_shells.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

