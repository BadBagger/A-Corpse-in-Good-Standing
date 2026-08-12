"""Deterministic Corvin side-action sprite-sheet renderer.

This script is intended to run inside Blender from the command sheet generated
by tools/Export-CorvinSideActionRenderCommands.ps1. It refuses to write a PNG
unless the requested action exists in the loaded .blend and the output contract
matches the locked Act I side-action row.
"""

import argparse
import os
import sys

try:
    import bpy
except ImportError as exc:
    raise SystemExit("This renderer must be executed by Blender Python.") from exc


CELL_WIDTH = 256
CELL_HEIGHT = 512
FPS = 12
ALLOWED = {
    ("talk", "side_right"): {
        "action": "Corvin_act_i_clean_talk_side",
        "frames": 6,
        "width": 1536,
    },
    ("talk", "side_left"): {
        "action": "Corvin_act_i_clean_talk_side",
        "frames": 6,
        "width": 1536,
    },
    ("use", "side_right"): {
        "action": "Corvin_act_i_clean_use_side",
        "frames": 8,
        "width": 2048,
    },
    ("use", "side_left"): {
        "action": "Corvin_act_i_clean_use_side",
        "frames": 8,
        "width": 2048,
    },
    ("wet", "side_right"): {
        "action": "Corvin_act_i_clean_wet_side",
        "frames": 8,
        "width": 2048,
    },
    ("wet", "side_left"): {
        "action": "Corvin_act_i_clean_wet_side",
        "frames": 8,
        "width": 2048,
    },
}


def blender_args():
    if "--" not in sys.argv:
        return []
    return sys.argv[sys.argv.index("--") + 1 :]


def parse_args(expected_animation=None, expected_direction=None):
    parser = argparse.ArgumentParser(
        description="Render one locked Corvin Act I side-action sprite sheet."
    )
    parser.add_argument("--action", required=True)
    parser.add_argument("--direction", required=True, choices=["side_right", "side_left"])
    parser.add_argument("--frames", required=True, type=int)
    parser.add_argument("--fps", required=True, type=int)
    parser.add_argument("--cell-width", required=True, type=int)
    parser.add_argument("--cell-height", required=True, type=int)
    parser.add_argument("--shader-blend", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--audit-contract", action="store_true")
    args = parser.parse_args(blender_args())

    if expected_animation is None:
        expected_animation = infer_animation_from_action(args.action)
    if expected_direction is not None and args.direction != expected_direction:
        raise SystemExit(
            f"Renderer entrypoint direction mismatch: expected {expected_direction}, got {args.direction}."
        )

    key = (expected_animation, args.direction)
    if key not in ALLOWED:
        raise SystemExit(f"Unsupported Corvin side action row: {key}.")

    expected = ALLOWED[key]
    if args.action != expected["action"]:
        raise SystemExit(
            f"Blender action mismatch for {expected_animation} {args.direction}: "
            f"expected {expected['action']}, got {args.action}."
        )
    if args.frames != expected["frames"] or args.fps != FPS:
        raise SystemExit(
            f"Frame contract mismatch for {expected_animation} {args.direction}: "
            f"expected {expected['frames']} at {FPS} fps, got {args.frames} at {args.fps} fps."
        )
    if args.cell_width != CELL_WIDTH or args.cell_height != CELL_HEIGHT:
        raise SystemExit(
            f"Cell contract mismatch: expected {CELL_WIDTH}x{CELL_HEIGHT}, "
            f"got {args.cell_width}x{args.cell_height}."
        )
    if os.path.exists(args.out):
        raise SystemExit(f"Refusing to overwrite existing render output without review: {args.out}")
    if not os.path.exists(args.shader_blend):
        raise SystemExit(f"Missing shader blend: {args.shader_blend}")

    return args, expected_animation, expected


def infer_animation_from_action(action_name):
    for (animation, _direction), spec in ALLOWED.items():
        if spec["action"] == action_name:
            return animation
    raise SystemExit(f"Unknown Corvin Blender action: {action_name}")


def find_action(action_name):
    action = bpy.data.actions.get(action_name)
    if action is None:
        raise SystemExit(
            f"Required Blender action is missing: {action_name}. "
            "No PNG was written. Create the keyed action in the canonical blend first."
        )
    return action


def find_render_armature():
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    if len(armatures) != 1:
        raise SystemExit(
            f"Expected exactly one Corvin armature in the source blend, found {len(armatures)}."
        )
    return armatures[0]


def configure_scene(args):
    bpy.context.scene.render.fps = args.fps
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = args.frames
    bpy.context.scene.render.resolution_x = args.cell_width
    bpy.context.scene.render.resolution_y = args.cell_height
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.image_settings.color_mode = "RGBA"


def render_frames(args, action):
    armature = find_render_armature()
    armature.animation_data_create()
    armature.animation_data.action = action
    configure_scene(args)

    output_dir = os.path.dirname(args.out)
    os.makedirs(output_dir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(args.out))[0]
    frame_dir = os.path.join(output_dir, f"{stem}_frames")
    os.makedirs(frame_dir, exist_ok=True)

    for frame in range(1, args.frames + 1):
        bpy.context.scene.frame_set(frame)
        bpy.context.scene.render.filepath = os.path.join(frame_dir, f"{stem}_{frame:04d}.png")
        bpy.ops.render.render(write_still=True)

    raise SystemExit(
        "Frame renders complete but sheet assembly is intentionally not automatic yet. "
        "Audit frame registration and assemble the sprite sheet before copying to Godot."
    )


def main(expected_animation=None, expected_direction=None):
    args, _animation, _expected = parse_args(expected_animation, expected_direction)
    action = find_action(args.action)
    if args.audit_contract:
        print(
            f"Corvin side-action render contract audited: action={args.action}, "
            f"direction={args.direction}, frames={args.frames}, cell={args.cell_width}x{args.cell_height}"
        )
        return
    render_frames(args, action)


if __name__ == "__main__":
    main()
