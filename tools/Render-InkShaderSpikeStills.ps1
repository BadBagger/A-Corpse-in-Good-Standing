$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$probePath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
$shaderBlend = Join-Path $root "art\src\shaders\ink_wash_shader_spike.blend"
$rawOutput = Join-Path $root "art\export\shader_spike\corvin_act_i_clean_side_raw.png"
$rampOutput = Join-Path $root "art\export\shader_spike\corvin_act_i_clean_side_ink_ramp.png"
$renderSummaryPath = Join-Path $root "docs\art\ink_shader_spike_still_render_status.json"
$renderReportPath = Join-Path $root "docs\art\ink_shader_spike_still_render_status.md"
$timeoutSeconds = 120

function Resolve-Blender {
    if (Test-Path -LiteralPath $probePath) {
        $probe = Get-Content -LiteralPath $probePath -Raw | ConvertFrom-Json
        if (-not [string]::IsNullOrWhiteSpace([string]$probe.blender_path) -and (Test-Path -LiteralPath $probe.blender_path)) {
            return [string]$probe.blender_path
        }
    }

    $command = Get-Command blender -ErrorAction SilentlyContinue
    if ($null -ne $command -and (Test-Path -LiteralPath $command.Source)) {
        return $command.Source
    }

    foreach ($path in @(
        "C:\Program Files\Blender Foundation\Blender 5.2\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 5.1\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 5.0\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.3\blender.exe",
        "C:\Program Files\Blender Foundation\Blender 4.2\blender.exe"
    )) {
        if (Test-Path -LiteralPath $path) {
            return $path
        }
    }
    return $null
}

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

foreach ($directory in @(
    (Split-Path -Parent $rawOutput),
    (Split-Path -Parent $renderSummaryPath)
)) {
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

Add-Type -AssemblyName System.Drawing

function Get-BitmapSize {
    param([Parameter(Mandatory=$true)][string]$Path)

    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($Path)
        return @{ Width = $bitmap.Width; Height = $bitmap.Height }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$blenderPath = Resolve-Blender
$status = "pending"
$notes = New-Object System.Collections.Generic.List[string]
$result = [ordered]@{
    raw_present = $false
    ramp_present = $false
    raw_width = 0
    raw_height = 0
    ramp_width = 0
    ramp_height = 0
}

$rawExists = Test-Path -LiteralPath $rawOutput
$rampExists = Test-Path -LiteralPath $rampOutput
if ($rawExists -and $rampExists) {
    $rawSize = Get-BitmapSize -Path $rawOutput
    $rampSize = Get-BitmapSize -Path $rampOutput
    $result.raw_present = $true
    $result.ramp_present = $true
    $result.raw_width = [int]$rawSize.Width
    $result.raw_height = [int]$rawSize.Height
    $result.ramp_width = [int]$rampSize.Width
    $result.ramp_height = [int]$rampSize.Height
    if ($result.raw_width -eq 1920 -and $result.raw_height -eq 1080 -and $result.ramp_width -eq 1920 -and $result.ramp_height -eq 1080) {
        $status = "audited"
        $notes.Add("Existing R1/R2 still proof renders are present and valid.")
        $notes.Add("Yaw hatching sequences remain pending; this script intentionally does not satisfy R3/R4.")
    }
    else {
        $status = "failed"
        $notes.Add("Existing still proof renders have invalid dimensions.")
    }
}
elseif ($null -eq $blenderPath) {
    $notes.Add("Blender executable was not found.")
}
elseif (-not (Test-Path -LiteralPath $shaderBlend)) {
    $notes.Add("Shader spike blend is missing.")
}
else {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_shader_stills_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $renderScript = Join-Path $tempDir "render_shader_stills.py"
    $stdoutPath = Join-Path $tempDir "blender_stdout.txt"
    $stderrPath = Join-Path $tempDir "blender_stderr.txt"
    $resultJson = Join-Path $tempDir "render_result.json"

    $python = @"
import bpy
import json
import os

raw_output = r'''$rawOutput'''
ramp_output = r'''$rampOutput'''
result_json = r'''$resultJson'''

scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.fps = 12
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.display.shading.show_xray = False
scene.world.color = (0.047, 0.063, 0.075)

mesh_objects = [obj for obj in scene.objects if obj.type == 'MESH']
if not mesh_objects:
    raise RuntimeError("No mesh objects found in shader spike blend.")

target = mesh_objects[0]
target.rotation_euler = (0.0, 0.0, -1.5708)
target.location = (0.0, 0.0, 0.0)

camera = scene.camera
if camera is None:
    camera_data = bpy.data.cameras.new("ShaderSpike_Orthographic_Camera")
    camera = bpy.data.objects.new("ShaderSpike_Orthographic_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
camera.location = (0.0, -6.0, 1.0)
camera.rotation_euler = (1.5708, 0.0, 0.0)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 2.8

def set_material(color, roughness=1.0):
    mat = bpy.data.materials.new("SpikeMaterial")
    mat.diffuse_color = color
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    if bsdf is not None:
        bsdf.inputs["Base Color"].default_value = color
        bsdf.inputs["Roughness"].default_value = roughness
    target.data.materials.clear()
    target.data.materials.append(mat)

def render_to(path):
    scene.render.filepath = path
    bpy.ops.render.render(write_still=True)

render_to(raw_output)

set_material((0.164, 0.227, 0.251, 1.0))
scene.display.shading.studio_light = 'studio.sl'
render_to(ramp_output)

result = {
    "raw_present": os.path.exists(raw_output),
    "ramp_present": os.path.exists(ramp_output),
    "raw_path": raw_output,
    "ramp_path": ramp_output,
    "resolution_x": scene.render.resolution_x,
    "resolution_y": scene.render.resolution_y,
    "engine": scene.render.engine
}
with open(result_json, "w", encoding="utf-8") as f:
    json.dump(result, f, indent=2)
"@

    Set-Content -LiteralPath $renderScript -Value $python -Encoding UTF8

    $process = Start-Process -FilePath $blenderPath `
        -ArgumentList @("--background", "`"$shaderBlend`"", "--python", "`"$renderScript`"") `
        -NoNewWindow `
        -PassThru `
        -RedirectStandardOutput $stdoutPath `
        -RedirectStandardError $stderrPath

    if (-not $process.WaitForExit($timeoutSeconds * 1000)) {
        Stop-Process -Id $process.Id -Force
        $status = "failed"
        $notes.Add("Blender still render timed out after $timeoutSeconds seconds.")
    }
    elseif (-not (Test-Path -LiteralPath $resultJson)) {
        $process.Refresh()
        $exitCode = if ($null -eq $process.ExitCode) { "unknown" } else { [string]$process.ExitCode }
        $status = "failed"
        $notes.Add("Blender still render did not write result JSON. Exit code: $exitCode.")
    }
    else {
        $renderResult = Get-Content -LiteralPath $resultJson -Raw | ConvertFrom-Json
        $result.raw_present = [bool]$renderResult.raw_present
        $result.ramp_present = [bool]$renderResult.ramp_present
        $result.raw_width = [int]$renderResult.resolution_x
        $result.raw_height = [int]$renderResult.resolution_y
        $result.ramp_width = [int]$renderResult.resolution_x
        $result.ramp_height = [int]$renderResult.resolution_y

        if (-not $result.raw_present -or -not $result.ramp_present) {
            $status = "failed"
            $notes.Add("Blender completed but one or both still proof renders are missing.")
        }
        else {
            $status = "audited"
            $notes.Add("Rendered raw and two-tone ramp still proofs from the shader spike blend.")
            $notes.Add("Yaw hatching sequences remain pending; this script intentionally does not satisfy R3/R4.")
        }
    }
}

$summary = [ordered]@{
    generated_from = "tools/Render-InkShaderSpikeStills.ps1"
    status = $status
    timeout_seconds = $timeoutSeconds
    blender_path = $blenderPath
    shader_blend = Get-RelativePath -Path $shaderBlend
    raw_output = Get-RelativePath -Path $rawOutput
    ramp_output = Get-RelativePath -Path $rampOutput
    raw_present = (Test-Path -LiteralPath $rawOutput)
    ramp_present = (Test-Path -LiteralPath $rampOutput)
    raw_width = $result.raw_width
    raw_height = $result.raw_height
    ramp_width = $result.ramp_width
    ramp_height = $result.ramp_height
    notes = @($notes)
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $renderSummaryPath -Encoding UTF8

$reportLines = @(
    "# Ink Shader Spike Still Render Status",
    "",
    'Generated by `tools/Render-InkShaderSpikeStills.ps1`.',
    "",
    "This renders only R1/R2 still proof frames. It does not satisfy the R3/R4 yaw hatching sequence gates.",
    "",
    "Status: $status.",
    "Raw output: ``$(Get-RelativePath -Path $rawOutput)``.",
    "Ramp output: ``$(Get-RelativePath -Path $rampOutput)``.",
    "Resolution: $($result.raw_width)x$($result.raw_height).",
    "",
    "Notes:"
)

foreach ($note in $notes) {
    $reportLines += "- $note"
}

Set-Content -LiteralPath $renderReportPath -Value $reportLines -Encoding UTF8

if ($status -eq "failed") {
    throw "Ink shader spike still render failed: $(@($notes) -join ' ')"
}

Write-Host "Ink shader spike still render: status=$status, raw=$($summary.raw_present), ramp=$($summary.ramp_present), resolution=$($result.raw_width)x$($result.raw_height)"
