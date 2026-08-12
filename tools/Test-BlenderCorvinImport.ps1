$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$probeJsonPath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
$probeReportPath = Join-Path $root "docs\art\blender_corvin_import_probe.md"
$sourceGlb = Join-Path $root "art\src\characters\corvin\meshy\corvin_act_i_clean.glb"
$characterBlend = Join-Path $root "art\src\characters\corvin\corvin_act_i_clean.blend"
$shaderBlend = Join-Path $root "art\src\shaders\ink_wash_shader_spike.blend"
$timeoutSeconds = 120

. (Join-Path $PSScriptRoot "Resolve-Blender.ps1")

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

foreach ($directory in @(
    (Split-Path -Parent $probeJsonPath),
    (Split-Path -Parent $characterBlend),
    (Split-Path -Parent $shaderBlend)
)) {
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

$blenderPath = Get-CorpseBlenderPath -Optional
$status = "pending"
$versionText = ""
$notes = New-Object System.Collections.Generic.List[string]
$details = [ordered]@{
    object_count = 0
    mesh_count = 0
    armature_count = 0
    material_count = 0
    action_count = 0
    imported_bounds = $null
}

if ($null -eq $blenderPath) {
    $notes.Add("Blender executable was not found.")
}
elseif (-not (Test-Path -LiteralPath $sourceGlb)) {
    $notes.Add("Canonical Corvin Act I GLB is missing.")
}
else {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_blender_probe_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $probeScript = Join-Path $tempDir "probe_corvin_import.py"
    $stdoutPath = Join-Path $tempDir "blender_stdout.txt"
    $stderrPath = Join-Path $tempDir "blender_stderr.txt"
    $blenderResultJson = Join-Path $tempDir "probe_result.json"

    $python = @"
import bpy
import json
import os
import sys
from mathutils import Vector

source_glb = r'''$sourceGlb'''
character_blend = r'''$characterBlend'''
shader_blend = r'''$shaderBlend'''
result_json = r'''$blenderResultJson'''

bpy.ops.object.select_all(action='SELECT')
bpy.ops.object.delete()
bpy.ops.import_scene.gltf(filepath=source_glb)

objects = list(bpy.context.scene.objects)
meshes = [obj for obj in objects if obj.type == 'MESH']
armatures = [obj for obj in objects if obj.type == 'ARMATURE']
materials = list(bpy.data.materials)
actions = list(bpy.data.actions)

bound_points = []
for obj in meshes:
    for corner in obj.bound_box:
        bound_points.append(obj.matrix_world @ Vector(corner))

if bound_points:
    mins = Vector((min(point.x for point in bound_points), min(point.y for point in bound_points), min(point.z for point in bound_points)))
    maxs = Vector((max(point.x for point in bound_points), max(point.y for point in bound_points), max(point.z for point in bound_points)))
    bounds = {
        "min": [round(mins.x, 4), round(mins.y, 4), round(mins.z, 4)],
        "max": [round(maxs.x, 4), round(maxs.y, 4), round(maxs.z, 4)],
        "size": [round(maxs.x - mins.x, 4), round(maxs.y - mins.y, 4), round(maxs.z - mins.z, 4)]
    }
else:
    bounds = None

camera_data = bpy.data.cameras.new("ShaderSpike_Orthographic_Camera")
camera = bpy.data.objects.new("ShaderSpike_Orthographic_Camera", camera_data)
bpy.context.collection.objects.link(camera)
camera.location = (0.0, -6.0, 1.8)
camera.rotation_euler = (1.5708, 0.0, 0.0)
camera_data.type = 'ORTHO'
camera_data.ortho_scale = 3.6
bpy.context.scene.camera = camera

light_data = bpy.data.lights.new("ShaderSpike_Key_Area", type='AREA')
light = bpy.data.objects.new("ShaderSpike_Key_Area", light_data)
bpy.context.collection.objects.link(light)
light.location = (-2.0, -4.0, 5.0)
light_data.energy = 450
light_data.size = 4.0

bpy.context.scene.render.resolution_x = 1920
bpy.context.scene.render.resolution_y = 1080
bpy.context.scene.render.fps = 12

result = {
    "object_count": len(objects),
    "mesh_count": len(meshes),
    "armature_count": len(armatures),
    "material_count": len(materials),
    "action_count": len(actions),
    "imported_bounds": bounds,
    "character_blend_present": os.path.exists(character_blend),
    "shader_blend_present": os.path.exists(shader_blend)
}
with open(result_json, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2)
"@

    Set-Content -LiteralPath $probeScript -Value $python -Encoding UTF8

    $versionOutput = & $blenderPath --version 2>&1
    $versionText = (($versionOutput | Select-Object -First 1) -replace "[^\u0000-\u007F]", "")

    $process = Start-Process -FilePath $blenderPath `
        -ArgumentList @("--background", "--factory-startup", "--python", $probeScript) `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force
        $status = "failed"
        $notes.Add("Blender import probe timed out after $timeoutSeconds seconds.")
    }
    elseif (-not (Test-Path -LiteralPath $blenderResultJson)) {
        $status = "failed"
        $process.Refresh()
        $exitCode = if ($null -eq $process.ExitCode) { "unknown" } else { [string]$process.ExitCode }
        $notes.Add("Blender import probe did not write its result JSON. Exit code: $exitCode.")
    }
    else {
        $process.Refresh()
        $exitCode = $process.ExitCode
        $result = Get-Content -LiteralPath $blenderResultJson -Raw | ConvertFrom-Json
        $details.object_count = [int]$result.object_count
        $details.mesh_count = [int]$result.mesh_count
        $details.armature_count = [int]$result.armature_count
        $details.material_count = [int]$result.material_count
        $details.action_count = [int]$result.action_count
        $details.imported_bounds = $result.imported_bounds

        if ($details.mesh_count -lt 1) {
            $status = "failed"
            $notes.Add("Blender imported the GLB but found no mesh objects.")
        }
        elseif (-not $result.character_blend_present -or -not $result.shader_blend_present) {
            $status = "failed"
            $notes.Add("Blender imported the GLB but one or more canonical source blend files are missing.")
        }
        else {
            $status = "audited"
            $notes.Add("Blender imported Corvin Act I clean GLB and validated existing source blend files without modifying them.")
            if ($null -ne $exitCode -and $exitCode -ne 0) {
                $notes.Add("Blender wrote a valid result despite reporting exit code $exitCode.")
            }
        }
    }
}

$probe = [ordered]@{
    generated_from = "tools/Test-BlenderCorvinImport.ps1"
    status = $status
    timeout_seconds = $timeoutSeconds
    blender_path = $blenderPath
    blender_version = $versionText
    source_glb = Get-RelativePath -Path $sourceGlb
    source_glb_present = (Test-Path -LiteralPath $sourceGlb)
    character_blend = Get-RelativePath -Path $characterBlend
    character_blend_present = (Test-Path -LiteralPath $characterBlend)
    shader_spike_blend = Get-RelativePath -Path $shaderBlend
    shader_spike_blend_present = (Test-Path -LiteralPath $shaderBlend)
    object_count = $details.object_count
    mesh_count = $details.mesh_count
    armature_count = $details.armature_count
    material_count = $details.material_count
    action_count = $details.action_count
    imported_bounds = $details.imported_bounds
    notes = @($notes)
}

$probe | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $probeJsonPath -Encoding UTF8

$reportLines = @(
    "# Blender Corvin Import Probe",
    "",
    'Generated by `tools/Test-BlenderCorvinImport.ps1`.',
    "",
    "This is a headless Blender preflight for the Meshy -> Blender -> sprite-sheet path. It verifies importability without writing to source blend files.",
    "",
    "Status: $status.",
    "Blender: $versionText.",
    "Source GLB: ``$(Get-RelativePath -Path $sourceGlb)``.",
    "Character blend: ``$(Get-RelativePath -Path $characterBlend)``.",
    "Shader spike blend: ``$(Get-RelativePath -Path $shaderBlend)``.",
    "",
    "| Metric | Value |",
    "|---|---:|",
    "| objects | $($details.object_count) |",
    "| meshes | $($details.mesh_count) |",
    "| armatures | $($details.armature_count) |",
    "| materials | $($details.material_count) |",
    "| actions | $($details.action_count) |",
    "",
    "Notes:"
)

foreach ($note in $notes) {
    $reportLines += "- $note"
}

Set-Content -LiteralPath $probeReportPath -Value $reportLines -Encoding UTF8

if ($status -eq "failed") {
    throw "Blender Corvin import probe failed: $(@($notes) -join ' ')"
}

Write-Host "Blender Corvin import probe: status=$status, blender=$versionText, meshes=$($details.mesh_count), armatures=$($details.armature_count), actions=$($details.action_count)"
