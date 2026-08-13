# Sectional Background Animation Pipeline

Use this for background elements that must react without regenerating or replacing the whole room plate.

## Rule

The room background remains the canonical plate. Reactive background groups are separate, bounded animation layers with fixed anchors, palette lock, and explicit triggers.

Do not generate whole-room alternate plates for small reactions. Full-room variants drift hotspot coordinates, walk bands, doors, character scale, and lighting.

## Layer Types

| Type | Use | Runtime form |
|---|---|---|
| Idle overlay | A background group with subtle motion | Sprite sheet or AnimatedSprite2D over the plate |
| Reaction overlay | A short response to a player verb | One-shot sprite sheet, then return to idle |
| State overlay | A persistent room change after a puzzle | Static or looping layer keyed by narrative flag |

## Build Steps

1. Mark a rectangular region on the 1920x1080 room plate.
2. Record the footline, anchor point, z-index, trigger verb, and fallback state.
3. Generate or paint only that region's alternate motion frames.
4. Palette-lock to the Act I palette and audit no arterial red unless explicitly approved.
5. Keep transparent pixels outside the region. No slate/green backing rectangle.
6. Add a soft contact shadow/reflection layer when the floor is wet.
7. Register the layer in Godot as a named room setpiece.
8. Trigger it from room interaction logic, never from hardcoded dialogue text.

## Gates

| Gate | Requirement |
|---|---|
| S1 | Overlay bounds remain inside the registered region. |
| S2 | First and last idle frames share the same footline and anchor. |
| S3 | Reaction animation returns to idle or a declared persistent state. |
| S4 | Palette audit passes against the room palette. |
| S5 | The underlying hotspot coordinates do not move. |
| S6 | No generated layer includes an opaque rectangular matte. |
| S7 | Contact shadow/reflection is present when grounded on wet floor. |

## Salt Market First Target

Setpiece id: `salt_market_crowd`

Region:
- Bounds: `x=1070 y=455 w=520 h=330`
- Footline: `y=785`
- Anchor: `Vector2(1070, 455)`
- Z-index: `4`

States:
- `idle_murmur`: subtle head turns, shoulders shifting, lantern flicker catchlights.
- `turn_to_corvin`: crowd turns toward Corvin after the public scream/talk interaction.
- `settle`: crowd resumes murmuring after the reaction.

Trigger:
- Room: `R03 Salt Market`
- Hotspot: `Crowd`
- Verb: `talk`
- Narrative flag after first trigger: `FL_salt_market_crowd_reacted`

Art direction:
- Keep the integrated room plate unchanged.
- Crowd adults remain taller than counters and tables.
- Amber highlights come from nearby stall lanterns.
- Absinthe green is only background wrong-light spill, not the main crowd color.
- No readable text, no UI, no modern clothing.
