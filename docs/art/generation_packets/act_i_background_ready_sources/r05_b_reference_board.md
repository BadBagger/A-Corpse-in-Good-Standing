# R05 - Harbor Registry - imagegen Ready Source Packet

Packet ID: R05_B_reference_board

Guardrails:
- This packet includes ready-to-generate source assets only.
- Do not generate final background plates from this packet.
- Do not include interactive or navigation PSD work in this packet.
- Save outputs exactly to the listed source paths.
- Run source intake again after files are saved.

Counts:
- Items: 4
- Tool: imagegen

| ID | Source | Drop Zone | Review Gate |
|---|---|---|---|
| harbor_registry_generated_reference_grime_texture | `docs/art/reference/act_i/harbor_registry/grime_texture.png` | `docs/art/reference/act_i/harbor_registry/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| harbor_registry_generated_reference_ink_wash_edge_breakup | `docs/art/reference/act_i/harbor_registry/ink_wash_edge_breakup.png` | `docs/art/reference/act_i/harbor_registry/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| harbor_registry_generated_reference_non_clickable_dressing_silhouettes | `docs/art/reference/act_i/harbor_registry/non_clickable_dressing_silhouettes.png` | `docs/art/reference/act_i/harbor_registry/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| harbor_registry_generated_reference_palette_safe_mood_reference | `docs/art/reference/act_i/harbor_registry/palette_safe_mood_reference.png` | `docs/art/reference/act_i/harbor_registry/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |

## harbor_registry_generated_reference_grime_texture

- Source: `docs/art/reference/act_i/harbor_registry/grime_texture.png`
- Placement target: `docs/art/reference/act_i/harbor_registry`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Harbor Registry on Isla Mordida: grime texture. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/harbor_registry/grime_texture.png. Use only as paintover reference; do not import directly as a final background plate.

## harbor_registry_generated_reference_ink_wash_edge_breakup

- Source: `docs/art/reference/act_i/harbor_registry/ink_wash_edge_breakup.png`
- Placement target: `docs/art/reference/act_i/harbor_registry`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Harbor Registry on Isla Mordida: ink-wash edge breakup. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/harbor_registry/ink_wash_edge_breakup.png. Use only as paintover reference; do not import directly as a final background plate.

## harbor_registry_generated_reference_non_clickable_dressing_silhouettes

- Source: `docs/art/reference/act_i/harbor_registry/non_clickable_dressing_silhouettes.png`
- Placement target: `docs/art/reference/act_i/harbor_registry`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Harbor Registry on Isla Mordida: non-clickable dressing silhouettes. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/harbor_registry/non_clickable_dressing_silhouettes.png. Use only as paintover reference; do not import directly as a final background plate.

## harbor_registry_generated_reference_palette_safe_mood_reference

- Source: `docs/art/reference/act_i/harbor_registry/palette_safe_mood_reference.png`
- Placement target: `docs/art/reference/act_i/harbor_registry`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Harbor Registry on Isla Mordida: palette-safe mood reference. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/harbor_registry/palette_safe_mood_reference.png. Use only as paintover reference; do not import directly as a final background plate.

