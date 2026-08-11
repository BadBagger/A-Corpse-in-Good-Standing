param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$probePath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
$shaderBlend = Join-Path $root "art\src\shaders\ink_wash_shader_spike.blend"
$silhouetteDir = Join-Path $root "art\export\shader_spike\yaw_silhouette"
$objectDir = Join-Path $root "art\export\shader_spike\yaw_object_anchored"
$badDir = Join-Path $root "art\export\shader_spike\yaw_screen_space_bad_control"
$paletteDir = Join-Path $root "art\export\shader_spike\yaw_palette_mapped"
$summaryPath = Join-Path $root "docs\art\ink_shader_spike_yaw_render_status.json"
$reportPath = Join-Path $root "docs\art\ink_shader_spike_yaw_render_status.md"
$frameCount = 24
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

function Clear-FrameDirectory {
    param([Parameter(Mandatory=$true)][string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
        return
    }
    if ($Force) {
        Get-ChildItem -LiteralPath $Directory -Filter "frame_*.png" -File | Remove-Item -Force
    }
}

foreach ($directory in @($silhouetteDir, $objectDir, $badDir, $paletteDir, (Split-Path -Parent $summaryPath))) {
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
}

Clear-FrameDirectory -Directory $silhouetteDir
Clear-FrameDirectory -Directory $objectDir
Clear-FrameDirectory -Directory $badDir
Clear-FrameDirectory -Directory $paletteDir

Add-Type -AssemblyName System.Drawing

$blenderPath = Resolve-Blender
$status = "pending"
$notes = New-Object System.Collections.Generic.List[string]

if ($null -eq $blenderPath) {
    $notes.Add("Blender executable was not found.")
}
elseif (-not (Test-Path -LiteralPath $shaderBlend)) {
    $notes.Add("Shader spike blend is missing.")
}
else {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_shader_yaw_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $renderScript = Join-Path $tempDir "render_yaw_silhouette.py"
    $stdoutPath = Join-Path $tempDir "blender_stdout.txt"
    $stderrPath = Join-Path $tempDir "blender_stderr.txt"
    $resultJson = Join-Path $tempDir "render_result.json"

    $python = @"
import bpy
import json
import math
import os

silhouette_dir = r'''$silhouetteDir'''
result_json = r'''$resultJson'''
frame_count = $frameCount

scene = bpy.context.scene
scene.render.engine = 'BLENDER_WORKBENCH'
scene.render.resolution_x = 1920
scene.render.resolution_y = 1080
scene.render.fps = 12
scene.display.shading.light = 'STUDIO'
scene.display.shading.color_type = 'MATERIAL'
scene.display.shading.background_type = 'WORLD'
scene.world.color = (0.047, 0.063, 0.075)

mesh_objects = [obj for obj in scene.objects if obj.type == 'MESH']
if not mesh_objects:
    raise RuntimeError("No mesh objects found in shader spike blend.")

target = mesh_objects[0]
target.location = (0.0, 0.0, 0.0)

mat = bpy.data.materials.new("YawSilhouetteMask")
mat.diffuse_color = (0.86, 0.83, 0.75, 1.0)
target.data.materials.clear()
target.data.materials.append(mat)

camera = scene.camera
if camera is None:
    camera_data = bpy.data.cameras.new("ShaderSpike_Yaw_Camera")
    camera = bpy.data.objects.new("ShaderSpike_Yaw_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
camera.location = (0.0, -6.0, 0.0)
camera.rotation_euler = (math.radians(90.0), 0.0, 0.0)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 4.2

os.makedirs(silhouette_dir, exist_ok=True)
for i in range(frame_count):
    t = i / float(frame_count - 1)
    yaw = math.radians(-35.0 + 70.0 * t)
    target.rotation_euler = (0.0, 0.0, yaw)
    scene.frame_set(i + 1)
    scene.render.filepath = os.path.join(silhouette_dir, f"frame_{i + 1:04d}.png")
    bpy.ops.render.render(write_still=True)

with open(result_json, "w", encoding="utf-8") as f:
    json.dump({"frames": frame_count, "silhouette_dir": silhouette_dir}, f, indent=2)
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
        $notes.Add("Blender yaw silhouette render timed out after $timeoutSeconds seconds.")
    }
    elseif (-not (Test-Path -LiteralPath $resultJson)) {
        $process.Refresh()
        $exitCode = if ($null -eq $process.ExitCode) { "unknown" } else { [string]$process.ExitCode }
        $status = "failed"
        $notes.Add("Blender yaw silhouette render did not write result JSON. Exit code: $exitCode.")
    }
}

function Get-ForegroundBounds {
    param([Parameter(Mandatory=$true)][System.Drawing.Bitmap]$Bitmap)

    $minX = $Bitmap.Width
    $minY = $Bitmap.Height
    $maxX = -1
    $maxY = -1
    for ($y = 0; $y -lt $Bitmap.Height; $y += 2) {
        for ($x = 0; $x -lt $Bitmap.Width; $x += 2) {
            $pixel = $Bitmap.GetPixel($x, $y)
            if ($pixel.R -gt 120 -and $pixel.G -gt 120 -and $pixel.B -gt 100) {
                if ($x -lt $minX) { $minX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }

    if ($maxX -lt 0) {
        return $null
    }
    return [ordered]@{ MinX = $minX; MinY = $minY; MaxX = $maxX; MaxY = $maxY }
}

function Render-HatchedFrame {
    param(
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [Parameter(Mandatory=$true)][string]$ObjectPath,
        [Parameter(Mandatory=$true)][string]$BadPath,
        [Parameter(Mandatory=$true)][string]$PalettePath,
        [Parameter(Mandatory=$true)][int]$FrameIndex
    )

    $source = $null
    $objectBitmap = $null
    $badBitmap = $null
    $paletteBitmap = $null
    try {
        $source = [System.Drawing.Bitmap]::new($SourcePath)
        $bounds = Get-ForegroundBounds -Bitmap $source
        if ($null -eq $bounds) {
            throw "Could not detect foreground bounds in $SourcePath"
        }

        $objectBitmap = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $badBitmap = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $paletteBitmap = [System.Drawing.Bitmap]::new($source.Width, $source.Height, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)

        $background = [System.Drawing.Color]::FromArgb(255, 12, 16, 19)
        $body = [System.Drawing.Color]::FromArgb(255, 42, 58, 64)
        $hatch = [System.Drawing.Color]::FromArgb(255, 228, 220, 200)
        $amber = [System.Drawing.Color]::FromArgb(255, 201, 138, 60)

        foreach ($bitmap in @($objectBitmap, $badBitmap, $paletteBitmap)) {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear($background)
            }
            finally {
                $graphics.Dispose()
            }
        }

        for ($y = [int]$bounds.MinY; $y -le [int]$bounds.MaxY; $y++) {
            for ($x = [int]$bounds.MinX; $x -le [int]$bounds.MaxX; $x++) {
                $pixel = $source.GetPixel($x, $y)
                $isForeground = ($pixel.R -gt 120 -and $pixel.G -gt 120 -and $pixel.B -gt 100)
                if (-not $isForeground) {
                    continue
                }

                $localX = $x - [int]$bounds.MinX
                $localY = $y - [int]$bounds.MinY
                $objectLine = ((($localX + (2 * $localY)) % 28) -lt 3)
                $badLine = ((($x + (2 * $y) + ($FrameIndex * 7)) % 28) -lt 3)
                $highlightLine = ($localY -lt 14 -and (($localX + $FrameIndex) % 19) -lt 2)

                $objectColor = if ($objectLine) { $hatch } else { $body }
                $badColor = if ($badLine) { $hatch } else { $body }
                $paletteColor = if ($highlightLine) { $amber } elseif ($objectLine) { $hatch } else { $body }

                $objectBitmap.SetPixel($x, $y, $objectColor)
                $badBitmap.SetPixel($x, $y, $badColor)
                $paletteBitmap.SetPixel($x, $y, $paletteColor)
            }
        }

        $objectBitmap.Save($ObjectPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $badBitmap.Save($BadPath, [System.Drawing.Imaging.ImageFormat]::Png)
        $paletteBitmap.Save($PalettePath, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        if ($null -ne $source) { $source.Dispose() }
        if ($null -ne $objectBitmap) { $objectBitmap.Dispose() }
        if ($null -ne $badBitmap) { $badBitmap.Dispose() }
        if ($null -ne $paletteBitmap) { $paletteBitmap.Dispose() }
    }
}

if ($status -ne "failed" -and $null -ne $blenderPath -and (Test-Path -LiteralPath $shaderBlend)) {
    for ($i = 1; $i -le $frameCount; $i++) {
        $name = "frame_{0:D4}.png" -f $i
        $sourcePath = Join-Path $silhouetteDir $name
        if (-not (Test-Path -LiteralPath $sourcePath)) {
            $status = "failed"
            $notes.Add("Missing silhouette frame: $(Get-RelativePath -Path $sourcePath)")
            break
        }
        Render-HatchedFrame `
            -SourcePath $sourcePath `
            -ObjectPath (Join-Path $objectDir $name) `
            -BadPath (Join-Path $badDir $name) `
            -PalettePath (Join-Path $paletteDir $name) `
            -FrameIndex $i
    }

    if ($status -ne "failed") {
        $status = "audited"
        $notes.Add("Rendered 24-frame Blender yaw silhouette sequence.")
        $notes.Add("Generated object-bounds-anchored hatch candidate, screen-crawling bad control, and locked-palette mapped sequence.")
    }
}

$objectFrames = @(Get-ChildItem -LiteralPath $objectDir -Filter "frame_*.png" -File -ErrorAction SilentlyContinue)
$badFrames = @(Get-ChildItem -LiteralPath $badDir -Filter "frame_*.png" -File -ErrorAction SilentlyContinue)
$paletteFrames = @(Get-ChildItem -LiteralPath $paletteDir -Filter "frame_*.png" -File -ErrorAction SilentlyContinue)

$summary = [ordered]@{
    generated_from = "tools/Render-InkShaderSpikeYawSequences.ps1"
    status = $status
    timeout_seconds = $timeoutSeconds
    blender_path = $blenderPath
    shader_blend = Get-RelativePath -Path $shaderBlend
    silhouette_directory = Get-RelativePath -Path $silhouetteDir
    object_anchored_directory = Get-RelativePath -Path $objectDir
    bad_control_directory = Get-RelativePath -Path $badDir
    palette_mapped_directory = Get-RelativePath -Path $paletteDir
    required_frames = $frameCount
    object_frames = $objectFrames.Count
    bad_control_frames = $badFrames.Count
    palette_mapped_frames = $paletteFrames.Count
    notes = @($notes)
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $summaryPath -Encoding UTF8

$reportLines = @(
    "# Ink Shader Spike Yaw Render Status",
    "",
    'Generated by `tools/Render-InkShaderSpikeYawSequences.ps1`.',
    "",
    "Status: $status.",
    "Required frames: $frameCount.",
    "Object-anchored frames: $($objectFrames.Count).",
    "Bad-control frames: $($badFrames.Count).",
    "Palette-mapped frames: $($paletteFrames.Count).",
    "",
    "Notes:"
)
foreach ($note in $notes) {
    $reportLines += "- $note"
}
Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

if ($status -eq "failed") {
    throw "Ink shader spike yaw render failed: $(@($notes) -join ' ')"
}

Write-Host "Ink shader spike yaw render: status=$status, objectFrames=$($objectFrames.Count), badControlFrames=$($badFrames.Count), paletteFrames=$($paletteFrames.Count)"
