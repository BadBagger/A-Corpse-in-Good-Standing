# R03 - Salt Market - imagegen Ready Source Packet

Packet ID: R03_B_reference_board

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
| salt_market_generated_reference_market_awning_texture | `docs/art/reference/act_i/salt_market/market_awning_texture.png` | `docs/art/reference/act_i/salt_market/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| salt_market_generated_reference_public_crowd_mood | `docs/art/reference/act_i/salt_market/public_crowd_mood.png` | `docs/art/reference/act_i/salt_market/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |
| salt_market_generated_reference_salt_signage_grime | `docs/art/reference/act_i/salt_market/salt_signage_grime.png` | `docs/art/reference/act_i/salt_market/README.md` | compare_against_locked_palette_and_existing_hotspot_readability |

## salt_market_generated_reference_market_awning_texture

- Source: `docs/art/reference/act_i/salt_market/market_awning_texture.png`
- Placement target: `docs/art/reference/act_i/salt_market`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Salt Market on Isla Mordida: market awning texture. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/salt_market/market_awning_texture.png. Use only as paintover reference; do not import directly as a final background plate.

## salt_market_generated_reference_public_crowd_mood

- Source: `docs/art/reference/act_i/salt_market/public_crowd_mood.png`
- Placement target: `docs/art/reference/act_i/salt_market`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Salt Market on Isla Mordida: public crowd mood. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/salt_market/public_crowd_mood.png. Use only as paintover reference; do not import directly as a final background plate.

## salt_market_generated_reference_salt_signage_grime

- Source: `docs/art/reference/act_i/salt_market/salt_signage_grime.png`
- Placement target: `docs/art/reference/act_i/salt_market`
- Runtime policy: never_import_directly_to_godot
- Handoff check: review as mood or texture reference only, never as a final room plate

Prompt:

```text
Reference image only for Salt Market on Isla Mordida: salt signage grime. Produce a mood/texture/silhouette reference board for an ink-and-wash noir point-and-click background. Keep it non-final and non-layout-authoritative. Emphasize material, edge breakup, lighting feel, and palette-safe dressing ideas. limited ink-and-wash noir palette: bone paper white #E4DCC8, wet black #0C1013, harbor slate #2A3A40, absinthe green #7D9B4E only for wrong light, whale-oil amber #C98A3C only for warmth, no arterial red unless explicitly approved.
```

Negative prompt:

```text
finished game background, full room plate, new hotspot layout, text UI, readable signage that must become canon, explicit sexual content, arterial red, photorealism
```

Output contract: Save reference image to docs/art/reference/act_i/salt_market/salt_signage_grime.png. Use only as paintover reference; do not import directly as a final background plate.

