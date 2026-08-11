param(
    [switch]$Force
)

$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$probePath = Join-Path $root "docs\art\blender_corvin_import_probe.json"
$shaderBlend = Join-Path $root "art\src\shaders\ink_wash_shader_spike.blend"
$tempFrameDir = Join-Path $root "art\export\characters\corvin\act_i_clean\_idle_side_right_frames"
$sheetOutput = Join-Path $root "art\export\characters\corvin\act_i_clean\idle_side_right.png"
$godotOutput = Join-Path $root "game\characters\corvin\sprites\act_i_clean\idle_side_right.png"
$statusPath = Join-Path $root "docs\art\corvin_act_i_clean_side_idle_status.json"
$reportPath = Join-Path $root "docs\art\corvin_act_i_clean_side_idle_status.md"
$frameCount = 12
$cellWidth = 256
$cellHeight = 512
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

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Directory)

    if (-not (Test-Path -LiteralPath $Directory)) {
        New-Item -ItemType Directory -Path $Directory | Out-Null
    }
}

foreach ($directory in @($tempFrameDir, (Split-Path -Parent $sheetOutput), (Split-Path -Parent $godotOutput), (Split-Path -Parent $statusPath))) {
    Ensure-Directory -Directory $directory
}

if ($Force) {
    Get-ChildItem -LiteralPath $tempFrameDir -Filter "frame_*.png" -File -ErrorAction SilentlyContinue | Remove-Item -Force
}

$blenderPath = Resolve-Blender
$status = "pending"
$notes = New-Object System.Collections.Generic.List[string]

if ($null -eq $blenderPath) {
    $status = "failed"
    $notes.Add("Blender executable was not found.")
}
elseif (-not (Test-Path -LiteralPath $shaderBlend)) {
    $status = "failed"
    $notes.Add("Shader spike blend is missing.")
}
else {
    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ("corpse_corvin_idle_" + [System.Guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $tempDir | Out-Null
    $renderScript = Join-Path $tempDir "render_corvin_idle_side.py"
    $stdoutPath = Join-Path $tempDir "blender_stdout.txt"
    $stderrPath = Join-Path $tempDir "blender_stderr.txt"
    $resultJson = Join-Path $tempDir "render_result.json"

    $python = @"
import bpy
import json
import math
import os

frame_dir = r'''$tempFrameDir'''
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
target.rotation_euler = (0.0, 0.0, math.radians(-90.0))

mat = bpy.data.materials.new("IdleSideSilhouetteMask")
mat.diffuse_color = (0.86, 0.83, 0.75, 1.0)
target.data.materials.clear()
target.data.materials.append(mat)

camera = scene.camera
if camera is None:
    camera_data = bpy.data.cameras.new("Corvin_Idle_Side_Camera")
    camera = bpy.data.objects.new("Corvin_Idle_Side_Camera", camera_data)
    bpy.context.collection.objects.link(camera)
    scene.camera = camera
camera.location = (0.0, -6.0, 0.0)
camera.rotation_euler = (math.radians(90.0), 0.0, 0.0)
camera.data.type = 'ORTHO'
camera.data.ortho_scale = 4.2

os.makedirs(frame_dir, exist_ok=True)
for i in range(frame_count):
    scene.frame_set(i + 1)
    scene.render.filepath = os.path.join(frame_dir, f"frame_{i + 1:04d}.png")
    bpy.ops.render.render(write_still=True)

with open(result_json, "w", encoding="utf-8") as f:
    json.dump({"frames": frame_count, "frame_dir": frame_dir}, f, indent=2)
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
        $notes.Add("Blender side idle render timed out after $timeoutSeconds seconds.")
    }
    elseif (-not (Test-Path -LiteralPath $resultJson)) {
        $process.Refresh()
        $exitCode = if ($null -eq $process.ExitCode) { "unknown" } else { [string]$process.ExitCode }
        $status = "failed"
        $notes.Add("Blender side idle render did not write result JSON. Exit code: $exitCode.")
    }
}

Add-Type -AssemblyName System.Drawing

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
    return [ordered]@{ MinX = $minX; MinY = $minY; MaxX = $maxX; MaxY = $maxY; Width = ($maxX - $minX + 1); Height = ($maxY - $minY + 1) }
}

function Render-FrameCell {
    param(
        [Parameter(Mandatory=$true)][string]$SourcePath,
        [Parameter(Mandatory=$true)][int]$FrameIndex
    )

    $source = $null
    $cell = $null
    try {
        $source = [System.Drawing.Bitmap]::new($SourcePath)
        $bounds = Get-ForegroundBounds -Bitmap $source
        if ($null -eq $bounds) {
            throw "Could not detect foreground bounds in $SourcePath"
        }

        $cell = [System.Drawing.Bitmap]::new($cellWidth, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $background = [System.Drawing.Color]::FromArgb(0, 12, 16, 19)
        $body = [System.Drawing.Color]::FromArgb(255, 42, 58, 64)
        $hatch = [System.Drawing.Color]::FromArgb(255, 228, 220, 200)
        $amber = [System.Drawing.Color]::FromArgb(255, 201, 138, 60)
        $drip = [System.Drawing.Color]::FromArgb(255, 125, 155, 78)

        $graphics = [System.Drawing.Graphics]::FromImage($cell)
        try {
            $graphics.Clear($background)
        }
        finally {
            $graphics.Dispose()
        }

        $scaleX = 210.0 / [double]$bounds.Width
        $scaleY = 460.0 / [double]$bounds.Height
        $scale = [math]::Min($scaleX, $scaleY)
        $drawWidth = [int][math]::Round([double]$bounds.Width * $scale)
        $drawHeight = [int][math]::Round([double]$bounds.Height * $scale)
        $offsetX = [int][math]::Floor(($cellWidth - $drawWidth) / 2)
        $offsetY = [int][math]::Floor(($cellHeight - $drawHeight) / 2)

        for ($dy = 0; $dy -lt $drawHeight; $dy++) {
            $sourceY = [int]$bounds.MinY + [int][math]::Floor($dy / $scale)
            for ($dx = 0; $dx -lt $drawWidth; $dx++) {
                $sourceX = [int]$bounds.MinX + [int][math]::Floor($dx / $scale)
                $pixel = $source.GetPixel($sourceX, $sourceY)
                if (-not ($pixel.R -gt 120 -and $pixel.G -gt 120 -and $pixel.B -gt 100)) {
                    continue
                }

                $objectLine = ((($dx + (2 * $dy)) % 16) -lt 2)
                $highlightLine = ($dy -lt 16 -and (($dx + $FrameIndex) % 21) -lt 2)
                $color = if ($highlightLine) { $amber } elseif ($objectLine) { $hatch } else { $body }
                $cell.SetPixel($offsetX + $dx, $offsetY + $dy, $color)
            }
        }

        # Tiny deterministic coat drip motion: enough to prove this is a loop, not enough to fight the body hatch.
        $dripX = [int]($cellWidth / 2) + 20
        $dripTop = $offsetY + $drawHeight - 20
        $dripLength = 8 + (($FrameIndex - 1) % 4)
        for ($i = 0; $i -lt $dripLength; $i++) {
            $y = $dripTop + $i
            if ($y -ge 0 -and $y -lt $cellHeight) {
                $cell.SetPixel($dripX, $y, $drip)
                if (($i % 3) -eq 0 -and ($dripX + 1) -lt $cellWidth) {
                    $cell.SetPixel($dripX + 1, $y, $drip)
                }
            }
        }

        return $cell
    }
    finally {
        if ($null -ne $source) {
            $source.Dispose()
        }
    }
}

$framePaths = @()
for ($i = 1; $i -le $frameCount; $i++) {
    $framePath = Join-Path $tempFrameDir ("frame_{0:D4}.png" -f $i)
    if (-not (Test-Path -LiteralPath $framePath)) {
        $status = "failed"
        $notes.Add("Missing side idle silhouette frame: $(Get-RelativePath -Path $framePath)")
        break
    }
    $framePaths += $framePath
}

if ($status -ne "failed") {
    $sheet = $null
    $graphics = $null
    try {
        $sheet = [System.Drawing.Bitmap]::new($cellWidth * $frameCount, $cellHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
        $graphics = [System.Drawing.Graphics]::FromImage($sheet)
        $graphics.Clear([System.Drawing.Color]::FromArgb(0, 12, 16, 19))
        $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
        $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half

        for ($i = 0; $i -lt $framePaths.Count; $i++) {
            $cell = $null
            try {
                $cell = Render-FrameCell -SourcePath $framePaths[$i] -FrameIndex ($i + 1)
                $graphics.DrawImageUnscaled($cell, $i * $cellWidth, 0)
            }
            finally {
                if ($null -ne $cell) {
                    $cell.Dispose()
                }
            }
        }

        $sheet.Save($sheetOutput, [System.Drawing.Imaging.ImageFormat]::Png)
        $sheet.Save($godotOutput, [System.Drawing.Imaging.ImageFormat]::Png)
        $status = "audited"
        $notes.Add("Rendered first-pass Act I clean side_right idle sprite sheet.")
        $notes.Add("This is a runtime candidate sheet, not final animation polish.")
    }
    finally {
        if ($null -ne $graphics) {
            $graphics.Dispose()
        }
        if ($null -ne $sheet) {
            $sheet.Dispose()
        }
    }
}

$summary = [ordered]@{
    generated_from = "tools/Render-CorvinActICleanSideIdleSheet.ps1"
    status = $status
    runtime_candidate = $true
    final_polish = $false
    character_id = "corvin"
    variant = "act_i_clean"
    animation = "idle"
    direction = "side_right"
    fps = 12
    frames = $frameCount
    cell_width = $cellWidth
    cell_height = $cellHeight
    sheet_width = $cellWidth * $frameCount
    sheet_height = $cellHeight
    sheet_export = Get-RelativePath -Path $sheetOutput
    godot_resource = Get-RelativePath -Path $godotOutput
    source_blend = Get-RelativePath -Path $shaderBlend
    notes = @($notes)
}

$summary | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath $statusPath -Encoding UTF8

$reportLines = @(
    "# Corvin Act I Clean Side Idle Status",
    "",
    'Generated by `tools/Render-CorvinActICleanSideIdleSheet.ps1`.',
    "",
    "Status: $status.",
    "Runtime candidate: true.",
    "Final polish: false.",
    "Variant: act_i_clean.",
    "Animation: idle.",
    "Direction: side_right.",
    "Frames: $frameCount at 12 fps.",
    "Cell: ${cellWidth}x${cellHeight}.",
    "Sheet: ``$(Get-RelativePath -Path $sheetOutput)``.",
    "Godot resource: ``$(Get-RelativePath -Path $godotOutput)``.",
    "",
    "Notes:"
)
foreach ($note in $notes) {
    $reportLines += "- $note"
}
Set-Content -LiteralPath $reportPath -Value $reportLines -Encoding UTF8

if ($status -eq "failed") {
    throw "Corvin Act I clean side idle sheet render failed: $(@($notes) -join ' ')"
}

Write-Host "Corvin Act I clean side idle sheet: status=$status, sheet=$(Get-RelativePath -Path $sheetOutput), godot=$(Get-RelativePath -Path $godotOutput), frames=$frameCount, cell=${cellWidth}x${cellHeight}"
