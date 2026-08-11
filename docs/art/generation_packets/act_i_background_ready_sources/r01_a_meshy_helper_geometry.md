# R01 - Mudflats - Meshy Ready Source Packet

Packet ID: R01_A_meshy_helper_geometry

Guardrails:
- This packet includes ready-to-generate source assets only.
- Do not generate final background plates from this packet.
- Do not include interactive or navigation PSD work in this packet.
- Save outputs exactly to the listed source paths.
- Run source intake again after files are saved.

Counts:
- Items: 3
- Tool: Meshy

| ID | Source | Drop Zone | Review Gate |
|---|---|---|---|
| mudflats_meshy_source_model_bollard_silhouettes | `art/src/backgrounds/act_i/source_models/mudflats/bollard_silhouettes.glb` | `art/src/backgrounds/act_i/source_models/mudflats/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| mudflats_meshy_source_model_distant_leviathan_ribs | `art/src/backgrounds/act_i/source_models/mudflats/distant_leviathan_ribs.glb` | `art/src/backgrounds/act_i/source_models/mudflats/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |
| mudflats_meshy_source_model_mud_ridge_reference_forms | `art/src/backgrounds/act_i/source_models/mudflats/mud_ridge_reference_forms.glb` | `art/src/backgrounds/act_i/source_models/mudflats/README.md` | open_room_blend_and_confirm_scale_silhouette_palette_before_paintover |

## mudflats_meshy_source_model_bollard_silhouettes

- Source: `art/src/backgrounds/act_i/source_models/mudflats/bollard_silhouettes.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/mudflats.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Mudflats on Isla Mordida: bollard silhouettes. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/mudflats/bollard_silhouettes.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## mudflats_meshy_source_model_distant_leviathan_ribs

- Source: `art/src/backgrounds/act_i/source_models/mudflats/distant_leviathan_ribs.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/mudflats.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Mudflats on Isla Mordida: distant leviathan ribs. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/mudflats/distant_leviathan_ribs.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

## mudflats_meshy_source_model_mud_ridge_reference_forms

- Source: `art/src/backgrounds/act_i/source_models/mudflats/mud_ridge_reference_forms.glb`
- Placement target: `art/src/backgrounds/act_i/blockouts/mudflats.blend`
- Runtime policy: never_import_directly_to_godot
- Handoff check: import into the room Blender blockout as helper geometry only

Prompt:

```text
Create a single reusable 3D source prop for Mudflats on Isla Mordida: mud ridge reference forms. Fixed-camera point-and-click adventure source asset, stylized 1740s occult harbor noir, strong silhouette, simple readable geometry, usable as Blender blockout/paintover reference, neutral grey material groups, no scene floor, no full room, no characters, no text labels. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
whole room, complete environment, final background, camera blur, unreadable tiny detail, modern objects, extra characters, explicit sexual content, arterial red, photoreal gore
```

Output contract: Download as GLB to art/src/backgrounds/act_i/source_models/mudflats/mud_ridge_reference_forms.glb. Import into Blender only as helper geometry; final room art still comes from greybox plus paintover.

