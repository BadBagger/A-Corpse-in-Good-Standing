$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_runtime_review_frames.json"
$mdPath = Join-Path $root "docs\art\act_i_runtime_review_frames.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_runtime_frame_contact_sheet.png"
$builderPath = Join-Path $root "tools\Build-ActIRuntimeReviewFrames.py"
$corvinLoaderPath = Join-Path $root "game\characters\corvin\runtime_sprite_sheet_loader.gd"
$corvinScenePath = Join-Path $root "game\characters\corvin\character_corvin.tscn"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $builderPath, $corvinLoaderPath, $corvinScenePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I runtime review artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "exported") {
    throw "Act I runtime review frame report must have status exported."
}
if ([int]$report.frame_count -ne 8) {
    throw "Act I runtime review frame report expected 8 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_runtime_frame_contact_sheet.png") {
    throw "Act I runtime review frame contact sheet path is not stable."
}
if ([string]$report.runtime_evidence -notmatch "runtime Corvin" -or [string]$report.runtime_evidence -notmatch "generated HUD skin") {
    throw "Act I runtime review frame report must state runtime Corvin and generated HUD evidence."
}

Add-Type -AssemblyName System.Drawing
$rooms = @($report.rooms)
if ($rooms.Count -ne 8) {
    throw "Act I runtime review frame report expected 8 room records, got $($rooms.Count)."
}

$requiredCodes = @("R02", "R03", "R05", "R06", "R07", "R09", "R10", "R12")
$seen = @{}
foreach ($room in $rooms) {
    $code = [string]$room.room_code
    if ($code -notin $requiredCodes) {
        throw "Unexpected Act I runtime review room code: $code"
    }
    if ($seen.ContainsKey($code)) {
        throw "Duplicate Act I runtime review room code: $code"
    }
    $seen[$code] = $true
    if (-not [bool]$room.includes_corvin -or -not [bool]$room.includes_hud) {
        throw "Act I runtime review frame $code must include Corvin and HUD."
    }
    $framePath = Join-Path $root ([string]$room.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Act I runtime review frame missing output: $($room.output)"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        if ($bitmap.Width -ne 1920 -or $bitmap.Height -ne 1080) {
            throw "Act I runtime review frame $code must be 1920x1080, got $($bitmap.Width)x$($bitmap.Height)."
        }
        $greenDominanceSamples = 0
        $samples = 0
        for ($y = 0; $y -lt $bitmap.Height; $y += 24) {
            for ($x = 0; $x -lt $bitmap.Width; $x += 24) {
                $pixel = $bitmap.GetPixel($x, $y)
                $samples += 1
                if ($pixel.G -gt ($pixel.R * 1.18) -and $pixel.G -gt ($pixel.B * 1.06) -and $pixel.G -gt 118) {
                    $greenDominanceSamples += 1
                }
            }
        }
        $greenDominancePercent = ($greenDominanceSamples / $samples) * 100.0
        if ($greenDominancePercent -gt 9.0) {
            throw "Act I runtime review frame $code has too much global green dominance: $([Math]::Round($greenDominancePercent, 2))%."
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}
foreach ($code in $requiredCodes) {
    if (-not $seen.ContainsKey($code)) {
        throw "Missing Act I runtime review room code: $code"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Runtime Review Frames",
    "runtime room composites",
    "Corvin side sprites",
    "generated noir HUD skin",
    "looks like an in-game screen"
)) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I runtime review report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I runtime review report must stay ASCII-only."
}

$loader = Get-Content -LiteralPath $corvinLoaderPath -Raw
foreach ($requiredText in @(
    "READABILITY_SHADOW_COLOR",
    "RuntimeReadabilityShadow",
    "_update_readability_shadow"
)) {
    if (-not $loader.Contains($requiredText)) {
        throw "Corvin runtime sprite loader missing readability shadow text: $requiredText"
    }
}

$scene = Get-Content -LiteralPath $corvinScenePath -Raw
if ($scene.Contains("default_color = Color(0.494118, 0.607843, 0.305882, 1)")) {
    throw "Corvin fallback drip still uses absinthe-green."
}

Write-Host "Act I runtime review frame validation passed: frames=$($rooms.Count), contactSheet=present."
