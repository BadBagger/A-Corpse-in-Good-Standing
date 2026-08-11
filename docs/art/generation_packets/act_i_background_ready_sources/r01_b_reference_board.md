# R01 - Mudflats - imagegen Ready Source Packet

Packet ID: R01_B_reference_board

Guardrails:
- This packet includes ready-to-generate source assets only.
- Do not generate final background plates from this packet.
- Do not include interactive or navigation PSD work in this packet.
- Save outputs exactly to the listed source paths.
- Run source intake again after files are saved.

Counts:
- Items: 3
- Tool: imagegen

| ID | Source | Drop Zone | Review Gate |
|---|---|---|---|
| mudflats_generated_reference_cold_horizon_wash | `docs/art/reference/act_i/mudflats/cold_horizon_wash.png` | `docs/art/reference/act_i/mudflats/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| mudflats_generated_reference_dawn_haze | `docs/art/reference/act_i/mudflats/dawn_haze.png` | `docs/art/reference/act_i/mudflats/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| mudflats_generated_reference_wet_silt_texture | `docs/art/reference/act_i/mudflats/wet_silt_texture.png` | `docs/art/reference/act_i/mudflats/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |

## mudflats_generated_reference_cold_horizon_wash

- Source: `docs/art/reference/act_i/mudflats/cold_horizon_wash.png`
- Placement target: `docs/art/reference/act_i/mudflats`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Mudflats on Isla Mordida: cold horizon wash. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/mudflats/cold_horizon_wash.png. Use only as paintover reference; do not import directly as a final background plate.

## mudflats_generated_reference_dawn_haze

- Source: `docs/art/reference/act_i/mudflats/dawn_haze.png`
- Placement target: `docs/art/reference/act_i/mudflats`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Mudflats on Isla Mordida: dawn haze. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/mudflats/dawn_haze.png. Use only as paintover reference; do not import directly as a final background plate.

## mudflats_generated_reference_wet_silt_texture

- Source: `docs/art/reference/act_i/mudflats/wet_silt_texture.png`
- Placement target: `docs/art/reference/act_i/mudflats`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Mudflats on Isla Mordida: wet silt texture. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/mudflats/wet_silt_texture.png. Use only as paintover reference; do not import directly as a final background plate.

