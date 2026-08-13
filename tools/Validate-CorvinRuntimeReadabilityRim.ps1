$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$loaderPath = Join-Path $root "game\characters\corvin\runtime_sprite_sheet_loader.gd"
$runtimeBuilderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$runtimeReportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$gameplayPanelPath = Join-Path $root "docs\art\review\act_i_gameplay_review_panels\mudflats_gameplay_panel.png"

foreach ($path in @($loaderPath, $runtimeBuilderPath, $runtimeReportPath, $gameplayPanelPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin runtime readability artifact: $path"
    }
}

$loader = Get-Content -LiteralPath $loaderPath -Raw
foreach ($requiredText in @(
    "READABILITY_RIM_COLOR",
    "READABILITY_RIM_OFFSETS",
    "RuntimeReadabilityRim",
    "Color(0.788235, 0.541176, 0.235294, 0.22)",
    "Vector2(-2, 0)",
    "Vector2(2, 0)",
    "Vector2(0, -2)"
)) {
    if (-not $loader.Contains($requiredText)) {
        throw "Corvin runtime sprite loader missing readability rim text: $requiredText"
    }
}

$rimNodeCount = ([regex]::Matches($loader, "RuntimeReadabilityRim")).Count
if ($rimNodeCount -lt 1) {
    throw "Corvin runtime sprite loader must create readability rim nodes."
}

$builder = Get-Content -LiteralPath $runtimeBuilderPath -Raw
foreach ($requiredText in @(
    "CORVIN_READABILITY_RIM",
    "CORVIN_READABILITY_RIM_OFFSETS",
    "includes_corvin_readability_rim",
    "round(value * 0.22)"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I Godot runtime frame builder missing Corvin readability rim text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Corvin readability runtime report expected 9 rooms, got $($rooms.Count)."
}
foreach ($room in $rooms) {
    if (-not [bool]$room.includes_corvin_readability_rim) {
        throw "Runtime frame report missing Corvin readability rim flag for room: $($room.room_id)"
    }
}

Add-Type -AssemblyName System.Drawing
$bitmap = $null
try {
    $bitmap = [System.Drawing.Bitmap]::new($gameplayPanelPath)
    $amberRimSamples = 0
    $playerBandSamples = 0
    # Mudflats crop contains Corvin around the upper-left side of the playable
    # band. This sanity check catches a missing rim in the most silhouette-hostile
    # bright exterior frame without demanding a hard-coded sprite mask.
    for ($y = 20; $y -lt 300; $y += 3) {
        for ($x = 210; $x -lt 470; $x += 3) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -le 32) {
                continue
            }
            $playerBandSamples += 1
            if ($pixel.R -gt 115 -and $pixel.G -gt 65 -and $pixel.G -lt 140 -and $pixel.B -lt 90 -and $pixel.R -gt ($pixel.B * 1.45)) {
                $amberRimSamples += 1
            }
        }
    }
    if ($playerBandSamples -lt 1000) {
        throw "Corvin readability rim sample band is unexpectedly sparse."
    }
    $ratio = $amberRimSamples / [Math]::Max(1, $playerBandSamples)
    if ($ratio -lt 0.003) {
        throw "Corvin readability rim is not visible enough in the Mudflats gameplay panel: $([Math]::Round($ratio * 100, 3))% amber samples."
    }
    if ($ratio -gt 0.08) {
        throw "Corvin readability rim is too broad in the Mudflats gameplay panel: $([Math]::Round($ratio * 100, 3))% amber samples."
    }
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
}

Write-Host "Corvin runtime readability rim validation passed: rooms=$($rooms.Count)."
