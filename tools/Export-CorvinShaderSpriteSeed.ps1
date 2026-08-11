$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$shaderStatusPath = Join-Path $root "docs\art\ink_shader_spike_status.md"
$metricsPath = Join-Path $root "docs\art\ink_shader_spike_metrics_status.json"
$yawStatusPath = Join-Path $root "docs\art\ink_shader_spike_yaw_render_status.json"
$manifestPath = Join-Path $root "docs\art\corvin_animation_manifest.json"
$seedJsonPath = Join-Path $root "docs\art\corvin_shader_sprite_seed.json"
$seedReportPath = Join-Path $root "docs\art\corvin_shader_sprite_seed.md"
$contactSheetPath = Join-Path $root "art\export\characters\corvin\act_i_clean\proof_yaw_side_right_contact.png"
$paletteDir = Join-Path $root "art\export\shader_spike\yaw_palette_mapped"
$frameCount = 24
$columns = 6
$cellWidth = 320
$cellHeight = 180

function Resolve-RepoPath {
    param([Parameter(Mandatory=$true)][string]$RelativePath)

    return Join-Path $root ($RelativePath -replace "/", "\")
}

function Get-RelativePath {
    param([Parameter(Mandatory=$true)][string]$Path)

    return ($Path.Substring($root.Length + 1) -replace "\\", "/")
}

foreach ($path in @($shaderStatusPath, $metricsPath, $yawStatusPath, $manifestPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing shader/sprite seed input: $path"
    }
}

$shaderStatus = Get-Content -LiteralPath $shaderStatusPath -Raw
if ($shaderStatus -notmatch "Summary: 7 present, 0 pending, 7 total shader proof slots") {
    throw "Shader spike status must be fully present before exporting Corvin shader sprite seed."
}

$metrics = Get-Content -LiteralPath $metricsPath -Raw | ConvertFrom-Json
if ($metrics.status -ne "audited") {
    throw "Shader metrics must be audited before exporting Corvin shader sprite seed: $($metrics.status)"
}
if ([int]$metrics.object_sequence.frames_found -ne $frameCount -or [int]$metrics.bad_control_sequence.frames_found -ne $frameCount) {
    throw "Shader metrics must cover both 24-frame yaw sequences."
}
if ([double]$metrics.object_sequence.pairwise_max_percent -gt [double]$metrics.pairwise_threshold_percent) {
    throw "Object-anchored hatch pairwise max exceeds threshold."
}
if ([double]$metrics.object_sequence.first_to_last_drift_percent -gt [double]$metrics.first_to_last_drift_threshold_percent) {
    throw "Object-anchored hatch first-last drift exceeds threshold."
}
if ([double]$metrics.bad_control_sequence.pairwise_max_percent -le [double]$metrics.object_sequence.pairwise_max_percent) {
    throw "Bad control must measure worse than the object-anchored candidate."
}

$yawStatus = Get-Content -LiteralPath $yawStatusPath -Raw | ConvertFrom-Json
if ($yawStatus.status -ne "audited" -or [int]$yawStatus.palette_mapped_frames -ne $frameCount) {
    throw "Yaw render status must be audited with 24 palette-mapped frames."
}

$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
$actI = @($manifest.variants | Where-Object { $_.id -eq "act_i_clean" })[0]
if ($null -eq $actI) {
    throw "Corvin animation manifest missing act_i_clean variant."
}
$sideIdle = @(@($actI.animations | Where-Object { $_.id -eq "idle" })[0].directions | Where-Object { $_.direction -eq "side_right" })[0]
if ($null -eq $sideIdle) {
    throw "Corvin animation manifest missing Act I clean side-right idle target."
}

$frames = @()
for ($i = 1; $i -le $frameCount; $i++) {
    $path = Join-Path $paletteDir ("frame_{0:D4}.png" -f $i)
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing palette-mapped yaw frame: $path"
    }
    $frames += $path
}

$contactDir = Split-Path -Parent $contactSheetPath
if (-not (Test-Path -LiteralPath $contactDir)) {
    New-Item -ItemType Directory -Path $contactDir | Out-Null
}

Add-Type -AssemblyName System.Drawing
$rows = [math]::Ceiling($frameCount / $columns)
$sheetWidth = $columns * $cellWidth
$sheetHeight = [int]$rows * $cellHeight
$sheet = $null
$graphics = $null
try {
    $sheet = [System.Drawing.Bitmap]::new($sheetWidth, $sheetHeight, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $graphics = [System.Drawing.Graphics]::FromImage($sheet)
    $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::NearestNeighbor
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::Half
    $graphics.Clear([System.Drawing.Color]::FromArgb(255, 12, 16, 19))

    for ($i = 0; $i -lt $frames.Count; $i++) {
        $source = $null
        try {
            $source = [System.Drawing.Bitmap]::new($frames[$i])
            $column = $i % $columns
            $row = [math]::Floor($i / $columns)
            $dest = [System.Drawing.Rectangle]::new($column * $cellWidth, [int]$row * $cellHeight, $cellWidth, $cellHeight)
            $graphics.DrawImage($source, $dest)
        }
        finally {
            if ($null -ne $source) {
                $source.Dispose()
            }
        }
    }
    $sheet.Save($contactSheetPath, [System.Drawing.Imaging.ImageFormat]::Png)
}
finally {
    if ($null -ne $graphics) {
        $graphics.Dispose()
    }
    if ($null -ne $sheet) {
        $sheet.Dispose()
    }
}

$seed = [ordered]@{
    generated_from = "tools/Export-CorvinShaderSpriteSeed.ps1"
    purpose = "Bridge the audited ink shader yaw proof into Corvin Act I side-profile sprite production."
    status = "audited"
    runtime_sheet = $false
    warning = "This is a proof seed/contact sheet, not a final runtime animation sheet."
    character_id = "corvin"
    variant = "act_i_clean"
    direction = "side_right"
    preferred_camera = "orthographic side-on adventure-game camera"
    source_model = [string]$actI.meshy_source
    blender_source = [string]$actI.blender_source
    shader_source = "art/src/shaders/ink_wash_shader_spike.blend"
    source_frames = "art/export/shader_spike/yaw_palette_mapped/frame_0001.png"
    source_frame_count = $frameCount
    contact_sheet = Get-RelativePath -Path $contactSheetPath
    intended_first_runtime_target = [string]$sideIdle.sheet_path
    intended_godot_resource = [string]$sideIdle.godot_resource
    metrics = [ordered]@{
        measurement = [string]$metrics.measurement
        object_pairwise_max_percent = [double]$metrics.object_sequence.pairwise_max_percent
        object_first_last_drift_percent = [double]$metrics.object_sequence.first_to_last_drift_percent
        bad_control_pairwise_max_percent = [double]$metrics.bad_control_sequence.pairwise_max_percent
        pairwise_threshold_percent = [double]$metrics.pairwise_threshold_percent
        first_to_last_drift_threshold_percent = [double]$metrics.first_to_last_drift_threshold_percent
    }
    next_production_step = "Render a true in-place side_right idle or walk action through the same shader stack; do not ship the yaw contact sheet as gameplay animation."
}

$seed | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $seedJsonPath -Encoding UTF8

$reportLines = @(
    "# Corvin Shader Sprite Seed",
    "",
    'Generated by `tools/Export-CorvinShaderSpriteSeed.ps1`.',
    "",
    "Purpose: bridge the audited ink shader yaw proof into Corvin Act I side-profile sprite production.",
    "",
    "Status: audited.",
    "Runtime sheet: false.",
    "Warning: this is a proof seed/contact sheet, not a final runtime animation sheet.",
    "",
    "Character: Corvin Vale.",
    "Variant: act_i_clean.",
    "Direction: side_right.",
    "Source frames: ``art/export/shader_spike/yaw_palette_mapped/frame_0001.png`` through frame 0024.",
    "Contact sheet: ``$(Get-RelativePath -Path $contactSheetPath)``.",
    "Intended first runtime target: ``$($sideIdle.sheet_path)``.",
    "",
    "Metrics:",
    "- Measurement: $($metrics.measurement).",
    "- Object pairwise max: $($metrics.object_sequence.pairwise_max_percent) percent.",
    "- Object first-last drift: $($metrics.object_sequence.first_to_last_drift_percent) percent.",
    "- Bad-control pairwise max: $($metrics.bad_control_sequence.pairwise_max_percent) percent.",
    "",
    "Next production step: render a true in-place side_right idle or walk action through the same shader stack; do not ship the yaw contact sheet as gameplay animation."
)
Set-Content -LiteralPath $seedReportPath -Value $reportLines -Encoding UTF8

Write-Host "Exported Corvin shader sprite seed -> $seedJsonPath"
Write-Host "Exported Corvin shader sprite seed report -> $seedReportPath"
Write-Host "Exported Corvin shader sprite contact sheet -> $contactSheetPath"
