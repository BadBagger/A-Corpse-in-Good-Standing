$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$motionAuditPath = Join-Path $root "docs\art\corvin_meshy_motion_source_audit.json"
$sourceBlendPath = Join-Path $root "art\src\characters\corvin\corvin_act_i_clean_side_actions.blend"
$statusJsonPath = Join-Path $root "docs\art\corvin_side_action_blend_status.json"
$statusMdPath = Join-Path $root "docs\art\corvin_side_action_blend_status.md"
$timeoutSeconds = 120

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

if (-not (Test-Path -LiteralPath $motionAuditPath)) {
    throw "Missing Corvin side action blend input: $motionAuditPath"
}

$motionAudit = Get-Content -LiteralPath $motionAuditPath -Raw | ConvertFrom-Json
$rows = @($motionAudit.rows)
foreach ($requiredMotion in @("talk", "use")) {
    $row = @($rows | Where-Object { $_.target_animation -eq $requiredMotion })[0]
    if ($null -eq $row -or $row.audit_status -ne "audited_motion_source") {
        throw "Corvin side action blend requires audited $requiredMotion motion source."
    }
}
$wetRow = @($rows | Where-Object { $_.target_animation -eq "wet" })[0]
if ($null -eq $wetRow -or $wetRow.source_role -ne "custom_required") {
    throw "Corvin side action blend requires wet to remain custom_required."
}

$blenderPath = Get-CorpseBlenderPath
if (-not (Test-Path -LiteralPath (Split-Path -Parent $sourceBlendPath))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $sourceBlendPath) | Out-Null
}
if (-not (Test-Path -LiteralPath (Split-Path -Parent $statusJsonPath))) {
    New-Item -ItemType Directory -Path (Split-Path -Parent $statusJsonPath) | Out-Null
}

$talkSource = Join-Path $root ((@($rows | Where-Object { $_.target_animation -eq "talk" })[0].source_path) -replace "/", "\")
$useSource = Join-Path $root ((@($rows | Where-Object { $_.target_animation -eq "use" })[0].source_path) -replace "/", "\")
$tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_corvin_side_action_blend_" + [System.Guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $tempDir | Out-Null
$scriptPath = Join-Path $tempDir "author_side_action_blend.py"
$stdoutPath = Join-Path $tempDir "blender_stdout.txt"
$stderrPath = Join-Path $tempDir "blender_stderr.txt"
$resultPath = Join-Path $tempDir "result.json"

$python = @"
import bpy
import json
import math
import os

talk_source = r'''$talkSource'''
use_source = r'''$useSource'''
blend_out = r'''$sourceBlendPath'''
result_json = r'''$resultPath'''

CELL_ACTIONS = {
    "Corvin_act_i_clean_talk_side": {
        "source": talk_source,
        "source_action": "Armature|Listening_Gesture|baselayer",
        "target_frames": 6,
        "source_start": 1,
        "source_end": 61,
        "loop": True,
    },
    "Corvin_act_i_clean_use_side": {
        "source": use_source,
        "source_action": "Armature|Collect_Object|baselayer",
        "target_frames": 8,
        "source_start": 1,
        "source_end": 81,
        "loop": False,
    },
}

def clear_scene():
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete()
    for datablock_group in (
        bpy.data.meshes,
        bpy.data.armatures,
        bpy.data.actions,
        bpy.data.materials,
        bpy.data.images,
    ):
        for datablock in list(datablock_group):
            if datablock.users == 0:
                datablock_group.remove(datablock)


def import_source(path):
    bpy.ops.import_scene.gltf(filepath=path)
    armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
    meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
    if len(armatures) != 1:
        raise RuntimeError(f"Expected one armature in {path}, found {len(armatures)}")
    if not meshes:
        raise RuntimeError(f"Expected at least one mesh in {path}")
    return armatures[0], meshes


def cleanup_imported_props():
    for obj in list(bpy.context.scene.objects):
        if obj.type == "MESH" and obj.name != "char1":
            bpy.data.objects.remove(obj, do_unlink=True)


def find_action(name):
    action = bpy.data.actions.get(name)
    if action is None:
        raise RuntimeError(f"Missing imported action: {name}")
    return action


def sample_pose(source_action, armature, target_action, target_frame, source_frame):
    armature.animation_data_create()
    armature.animation_data.action = source_action
    bpy.context.scene.frame_set(source_frame)
    bpy.context.view_layer.update()
    sampled_pose = []
    for pose_bone in armature.pose.bones:
        sampled_pose.append({
            "name": pose_bone.name,
            "location": tuple(pose_bone.location),
            "rotation_mode": pose_bone.rotation_mode,
            "rotation_quaternion": tuple(pose_bone.rotation_quaternion),
            "scale": tuple(pose_bone.scale),
        })
    armature.animation_data.action = target_action
    bpy.context.scene.frame_set(target_frame)
    for sample in sampled_pose:
        pose_bone = armature.pose.bones[sample["name"]]
        pose_bone.location = sample["location"]
        pose_bone.rotation_mode = "QUATERNION"
        pose_bone.rotation_quaternion = sample["rotation_quaternion"]
        pose_bone.scale = sample["scale"]
        pose_bone.keyframe_insert(data_path="location", frame=target_frame)
        pose_bone.keyframe_insert(data_path="rotation_quaternion", frame=target_frame)
        pose_bone.keyframe_insert(data_path="scale", frame=target_frame)


def action_stats(action):
    fcurves = []
    if hasattr(action, "fcurves"):
        fcurves = list(action.fcurves)
    elif hasattr(action, "layers"):
        for layer in action.layers:
            for strip in getattr(layer, "strips", []):
                for channelbag in getattr(strip, "channelbags", []):
                    fcurves.extend(list(getattr(channelbag, "fcurves", [])))
    keyed_frames = set()
    for fcurve in fcurves:
        for keyframe in fcurve.keyframe_points:
            keyed_frames.add(int(round(keyframe.co.x)))
    return {
        "fcurve_count": len(fcurves),
        "keyframe_count": sum(len(fcurve.keyframe_points) for fcurve in fcurves),
        "keyed_frame_count": len(keyed_frames),
        "keyed_frames": sorted(keyed_frames),
    }


clear_scene()
base_armature = None
base_meshes = []
created_actions = []

for target_name, spec in CELL_ACTIONS.items():
    clear_scene()
    armature, meshes = import_source(spec["source"])
    cleanup_imported_props()
    source_action = find_action(spec["source_action"])
    target_action = bpy.data.actions.new(target_name)
    target_action.use_fake_user = True
    armature.animation_data_create()
    armature.animation_data.action = target_action

    source_span = max(1, spec["source_end"] - spec["source_start"])
    for index in range(spec["target_frames"]):
        if spec["target_frames"] == 1:
            source_frame = spec["source_start"]
        else:
            source_frame = spec["source_start"] + int(round((index / (spec["target_frames"] - 1)) * source_span))
        if spec["loop"] and index == spec["target_frames"] - 1:
            source_frame = spec["source_start"]
        sample_pose(source_action, armature, target_action, index + 1, source_frame)

    created_actions.append({
        "name": target_name,
        "frames": spec["target_frames"],
        "source_action": spec["source_action"],
        "source_path": spec["source"],
        "stats": action_stats(target_action),
    })
    if target_name == "Corvin_act_i_clean_use_side":
        base_armature = armature
        base_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]

if base_armature is None:
    raise RuntimeError("No base armature remained after action authoring.")

# Hand-authored wet action on the same rig. It is deliberately small: lean, sleeve lift, drip hold, settle.
wet = bpy.data.actions.new("Corvin_act_i_clean_wet_side")
wet.use_fake_user = True
base_armature.animation_data_create()
base_armature.animation_data.action = wet
bone_names = [bone.name for bone in base_armature.pose.bones]

def set_bone_rotation(name, frame, euler_xyz):
    pose_bone = base_armature.pose.bones.get(name)
    if pose_bone is None:
        return
    pose_bone.rotation_mode = "XYZ"
    pose_bone.rotation_euler = tuple(math.radians(value) for value in euler_xyz)
    pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)

def set_bone_location(name, frame, loc):
    pose_bone = base_armature.pose.bones.get(name)
    if pose_bone is None:
        return
    pose_bone.location = loc
    pose_bone.keyframe_insert(data_path="location", frame=frame)

for frame in range(1, 9):
    bpy.context.scene.frame_set(frame)
    for pose_bone in base_armature.pose.bones:
        pose_bone.location = (0.0, 0.0, 0.0)
        pose_bone.rotation_mode = "XYZ"
        pose_bone.rotation_euler = (0.0, 0.0, 0.0)
        pose_bone.scale = (1.0, 1.0, 1.0)
        pose_bone.keyframe_insert(data_path="location", frame=frame)
        pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)
        pose_bone.keyframe_insert(data_path="scale", frame=frame)

wet_poses = {
    2: {"Spine": (2, 0, -3), "RightArm": (0, 0, -8), "RightForeArm": (0, 0, -12)},
    3: {"Spine": (4, 0, -6), "RightArm": (0, 0, -20), "RightForeArm": (0, 0, -25)},
    4: {"Spine": (5, 0, -7), "RightArm": (0, 0, -28), "RightForeArm": (0, 0, -36), "RightHand": (0, 0, -10)},
    5: {"Spine": (5, 0, -7), "RightArm": (0, 0, -25), "RightForeArm": (0, 0, -32), "RightHand": (0, 0, -14)},
    6: {"Spine": (3, 0, -4), "RightArm": (0, 0, -14), "RightForeArm": (0, 0, -18)},
    7: {"Spine": (1, 0, -2), "RightArm": (0, 0, -5), "RightForeArm": (0, 0, -7)},
}
for frame, rotations in wet_poses.items():
    for bone_name, euler_xyz in rotations.items():
        set_bone_rotation(bone_name, frame, euler_xyz)
set_bone_location("Hips", 4, (0.0, -0.01, 0.0))
set_bone_location("Hips", 5, (0.0, -0.01, 0.0))

created_actions.append({
    "name": "Corvin_act_i_clean_wet_side",
    "frames": 8,
    "source_action": "hand_authored_custom_brine",
    "source_path": "",
    "stats": action_stats(wet),
})

base_armature.name = "Corvin_Act_I_Clean_Rig"
base_armature.data.name = "Corvin_Act_I_Clean_Armature"
for obj in base_meshes:
    obj.name = "Corvin_Act_I_Clean_Mesh" if obj.name == "char1" else obj.name

bpy.context.scene.render.fps = 12
bpy.context.scene.frame_start = 1
bpy.context.scene.frame_end = 8

os.makedirs(os.path.dirname(blend_out), exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=blend_out)

with open(result_json, "w", encoding="utf-8") as f:
    json.dump({
        "blend": blend_out,
        "actions": created_actions,
        "armature": base_armature.name,
        "mesh_count": len([obj for obj in bpy.context.scene.objects if obj.type == "MESH"]),
        "armature_count": len([obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]),
        "bone_count": len(bone_names),
    }, f, indent=2)
"@

Set-Content -LiteralPath $scriptPath -Value $python -Encoding UTF8
$process = Start-Process -FilePath $blenderPath `
    -ArgumentList @("--background", "--factory-startup", "--python", $scriptPath) `
    -NoNewWindow `
    -PassThru `
    -RedirectStandardOutput $stdoutPath `
    -RedirectStandardError $stderrPath

if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
    Stop-Process -Id $process.Id -Force
    throw "Corvin side action blend authoring timed out after $timeoutSeconds seconds."
}
if (-not (Test-Path -LiteralPath $resultPath)) {
    $stderr = if (Test-Path -LiteralPath $stderrPath) { Get-Content -LiteralPath $stderrPath -Raw } else { "" }
    throw "Corvin side action blend authoring did not write result JSON. stderr=$stderr"
}

$result = Get-Content -LiteralPath $resultPath -Raw | ConvertFrom-Json
$actionRows = @($result.actions)
foreach ($actionName in @("Corvin_act_i_clean_talk_side", "Corvin_act_i_clean_use_side", "Corvin_act_i_clean_wet_side")) {
    if ($actionName -notin @($actionRows | ForEach-Object { $_.name })) {
        throw "Corvin side action blend missing authored action: $actionName"
    }
}
if ([int]$result.armature_count -ne 1 -or [int]$result.mesh_count -lt 1 -or [int]$result.bone_count -lt 20) {
    throw "Corvin side action blend has invalid rig structure."
}

$status = [ordered]@{
    generated_from = "tools/Author-CorvinSideActionBlend.ps1"
    status = "authored_actions_pending_render_audit"
    timeout_seconds = $timeoutSeconds
    blend_path = Get-RelativePath -Path $sourceBlendPath
    blend_present = (Test-Path -LiteralPath $sourceBlendPath)
    blender_path = $blenderPath
    armature = [string]$result.armature
    armature_count = [int]$result.armature_count
    mesh_count = [int]$result.mesh_count
    bone_count = [int]$result.bone_count
    rule_locks = @(
        "This tool authors Blender action source only; it does not create PNG sheets.",
        "Talk and use are sampled from audited Meshy motion sources.",
        "Wet is hand-authored as a custom physical brine action.",
        "The resulting blend still requires render-script and Godot import audits before any sprite sheet counts as present."
    )
    actions = @($actionRows)
}

$status | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $statusJsonPath -Encoding UTF8

$lines = @(
    "# Corvin Side Action Blend Status",
    "",
    'Generated by `tools/Author-CorvinSideActionBlend.ps1`.',
    "",
    "Status: authored_actions_pending_render_audit",
    "Blend: ``$(Get-RelativePath -Path $sourceBlendPath)``",
    "Armature: $($result.armature)",
    "Meshes: $($result.mesh_count)",
    "Bones: $($result.bone_count)",
    "",
    "Rule locks:",
    "- This tool authors Blender action source only; it does not create PNG sheets.",
    "- Talk and use are sampled from audited Meshy motion sources.",
    "- Wet is hand-authored as a custom physical brine action.",
    "- The resulting blend still requires render-script and Godot import audits before any sprite sheet counts as present.",
    "",
    "| Action | Frames | Keyed frames | F-curves | Keyframes | Source |",
    "|---|---:|---:|---:|---:|---|"
)
foreach ($action in $actionRows) {
    $lines += "| ``$($action.name)`` | $($action.frames) | $($action.stats.keyed_frame_count) | $($action.stats.fcurve_count) | $($action.stats.keyframe_count) | $($action.source_action) |"
}
Set-Content -LiteralPath $statusMdPath -Value $lines -Encoding UTF8

Write-Host "Corvin side action blend authored: actions=$($actionRows.Count), blend=$(Get-RelativePath -Path $sourceBlendPath)."
