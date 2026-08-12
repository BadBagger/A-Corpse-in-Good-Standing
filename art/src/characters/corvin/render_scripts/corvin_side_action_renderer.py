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
    import mathutils
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
    if os.path.exists(args.out) and not args.audit_contract:
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
    bpy.context.scene.render.engine = "BLENDER_WORKBENCH"
    bpy.context.scene.render.fps = args.fps
    bpy.context.scene.frame_start = 1
    bpy.context.scene.frame_end = args.frames
    bpy.context.scene.render.resolution_x = args.cell_width
    bpy.context.scene.render.resolution_y = args.cell_height
    bpy.context.scene.render.resolution_percentage = 100
    bpy.context.scene.render.film_transparent = True
    bpy.context.scene.render.image_settings.file_format = "PNG"
    bpy.context.scene.render.image_settings.color_mode = "RGBA"
    bpy.context.scene.display.shading.light = "STUDIO"
    bpy.context.scene.display.shading.color_type = "MATERIAL"
    bpy.context.scene.display.shading.background_type = "WORLD"
    bpy.context.scene.world.color = (0.047, 0.063, 0.075)


def configure_materials(animation):
    palette = {
        "body": (0.164, 0.227, 0.251, 1.0),
        "bone": (0.894, 0.863, 0.784, 1.0),
        "green": (0.490, 0.608, 0.306, 1.0),
    }
    color = palette["body"]
    if animation == "wet":
        color = palette["green"]
    for mesh in [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]:
        material = bpy.data.materials.new(f"Corvin_{animation}_ink_runtime")
        material.diffuse_color = color
        mesh.data.materials.clear()
        mesh.data.materials.append(material)


def scene_bounds(objects):
    min_corner = mathutils.Vector((float("inf"), float("inf"), float("inf")))
    max_corner = mathutils.Vector((float("-inf"), float("-inf"), float("-inf")))
    for obj in objects:
        for corner in obj.bound_box:
            world = obj.matrix_world @ mathutils.Vector(corner)
            min_corner.x = min(min_corner.x, world.x)
            min_corner.y = min(min_corner.y, world.y)
            min_corner.z = min(min_corner.z, world.z)
            max_corner.x = max(max_corner.x, world.x)
            max_corner.y = max(max_corner.y, world.y)
            max_corner.z = max(max_corner.z, world.z)
    if min_corner.x == float("inf"):
        raise SystemExit("Cannot frame Corvin render: no mesh bounds found.")
    return min_corner, max_corner


def configure_camera(direction):
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    min_corner, max_corner = scene_bounds(meshes)
    center = (min_corner + max_corner) * 0.5
    height = max(0.1, max_corner.z - min_corner.z)
    width = max(0.1, max(max_corner.x - min_corner.x, max_corner.y - min_corner.y))

    camera_data = bpy.data.cameras.new("Corvin_Side_Action_Camera")
    camera = bpy.data.objects.new("Corvin_Side_Action_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    bpy.context.scene.camera = camera
    side = 1.0 if direction == "side_right" else -1.0
    camera.location = (center.x + (6.0 * side), center.y, center.z)
    aim = center - camera.location
    camera.rotation_euler = aim.to_track_quat("-Z", "Y").to_euler()
    camera.data.type = "ORTHO"
    camera.data.ortho_scale = max(height * 1.18, width * 1.6, 2.2)


def frame_nonblank(image):
    pixels = list(image.pixels)
    alpha = pixels[3::4]
    return sum(1 for value in alpha if value > 0.01) > 200


def assemble_sheet(frame_paths, out_path, cell_width, cell_height):
    sheet = bpy.data.images.new(
        "Corvin_side_action_sheet",
        width=cell_width * len(frame_paths),
        height=cell_height,
        alpha=True,
        float_buffer=False,
    )
    sheet_pixels = [0.0] * (sheet.size[0] * sheet.size[1] * 4)
    nonblank_frames = 0

    for frame_index, frame_path in enumerate(frame_paths):
        image = bpy.data.images.load(frame_path, check_existing=False)
        try:
            if image.size[0] != cell_width or image.size[1] != cell_height:
                raise SystemExit(
                    f"Rendered frame has wrong size: {frame_path} got {image.size[0]}x{image.size[1]}."
                )
            pixels = list(image.pixels)
            if frame_nonblank(image):
                nonblank_frames += 1
            for y in range(cell_height):
                for x in range(cell_width):
                    src = ((y * cell_width) + x) * 4
                    dst_x = (frame_index * cell_width) + x
                    dst = ((y * sheet.size[0]) + dst_x) * 4
                    sheet_pixels[dst : dst + 4] = pixels[src : src + 4]
        finally:
            bpy.data.images.remove(image)

    if nonblank_frames != len(frame_paths):
        raise SystemExit(
            f"Refusing to write sprite sheet: {nonblank_frames}/{len(frame_paths)} frames are nonblank."
        )

    sheet.pixels.foreach_set(sheet_pixels)
    sheet.file_format = "PNG"
    os.makedirs(os.path.dirname(out_path), exist_ok=True)
    sheet.save(filepath=out_path)
    bpy.data.images.remove(sheet)


def render_frames(args, action, animation):
    armature = find_render_armature()
    armature.animation_data_create()
    armature.animation_data.action = action
    configure_scene(args)
    configure_materials(animation)
    configure_camera(args.direction)

    output_dir = os.path.dirname(args.out)
    os.makedirs(output_dir, exist_ok=True)
    stem = os.path.splitext(os.path.basename(args.out))[0]
    frame_dir = os.path.join(output_dir, f"{stem}_frames")
    os.makedirs(frame_dir, exist_ok=True)
    frame_paths = []

    for frame in range(1, args.frames + 1):
        bpy.context.scene.frame_set(frame)
        frame_path = os.path.join(frame_dir, f"{stem}_{frame:04d}.png")
        if os.path.exists(frame_path):
            os.remove(frame_path)
        bpy.context.scene.render.filepath = frame_path
        bpy.ops.render.render(write_still=True)
        frame_paths.append(frame_path)

    assemble_sheet(frame_paths, args.out, args.cell_width, args.cell_height)
    print(
        f"Corvin side-action sheet rendered: action={args.action}, "
        f"direction={args.direction}, frames={args.frames}, out={args.out}"
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
    render_frames(args, action, _animation)


if __name__ == "__main__":
    main()
