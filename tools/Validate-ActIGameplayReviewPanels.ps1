$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_gameplay_review_panels.json"
$mdPath = Join-Path $root "docs\art\act_i_gameplay_review_panels.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_gameplay_review_panels_contact_sheet.png"
$builderPath = Join-Path $root "tools\Build-ActIGameplayReviewPanels.py"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $builderPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I gameplay review panel artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "exported") {
    throw "Act I gameplay review panel report must have status exported."
}
if ([string]$report.source -ne "docs/art/act_i_godot_runtime_frames.json") {
    throw "Act I gameplay review panels must source the Godot runtime frame report."
}
if ([int]$report.panel_count -ne 8) {
    throw "Act I gameplay review panel report expected 8 panels, got $($report.panel_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_gameplay_review_panels_contact_sheet.png") {
    throw "Act I gameplay review panel contact sheet path is not stable."
}
foreach ($requiredText in @("larger cropped gameplay panels", "runtime art", "Corvin", "NPCs", "HUD", "room-specific dialogue captions")) {
    if ([string]$report.purpose -notmatch [regex]::Escape($requiredText)) {
        throw "Act I gameplay review panel report missing purpose text: $requiredText"
    }
}

Add-Type -AssemblyName System.Drawing
$requiredCodes = @("R02", "R03", "R05", "R06", "R07", "R09", "R10", "R12")
$seen = @{}
$panels = @($report.panels)
foreach ($panel in $panels) {
    $code = [string]$panel.room_code
    if ($code -notin $requiredCodes) {
        throw "Unexpected Act I gameplay review panel room code: $code"
    }
    if ($seen.ContainsKey($code)) {
        throw "Duplicate Act I gameplay review panel room code: $code"
    }
    $seen[$code] = $true
    $cropBox = @($panel.crop_box)
    if ($cropBox.Count -ne 4 -or [int]$cropBox[0] -ne 480 -or [int]$cropBox[1] -ne 360 -or [int]$cropBox[2] -ne 1680 -or [int]$cropBox[3] -ne 1080) {
        throw "Act I gameplay review panel $code has unexpected crop box."
    }
    if (-not [bool]$panel.includes_hud_crop -or -not [bool]$panel.includes_runtime_art) {
        throw "Act I gameplay review panel $code must include HUD crop and runtime art flags."
    }
    $caption = [string]$panel.dialogue_caption
    if ([string]::IsNullOrWhiteSpace($caption) -or $caption -eq "Corvin: dead, damp, and still doing the voice.") {
        throw "Act I gameplay review panel $code must carry the room-specific dialogue caption."
    }
    $panelPath = Join-Path $root ([string]$panel.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $panelPath)) {
        throw "Missing Act I gameplay review panel PNG: $($panel.output)"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($panelPath)
        if ($bitmap.Width -ne 1200 -or $bitmap.Height -ne 720) {
            throw "Act I gameplay review panel $code must be 1200x720, got $($bitmap.Width)x$($bitmap.Height)."
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
        throw "Missing Act I gameplay review panel room code: $code"
    }
}

$contactBitmap = $null
try {
    $contactBitmap = [System.Drawing.Bitmap]::new($contactSheetPath)
    if ($contactBitmap.Width -lt 1200 -or $contactBitmap.Height -lt 1600) {
        throw "Act I gameplay review panel contact sheet is unexpectedly small: $($contactBitmap.Width)x$($contactBitmap.Height)."
    }
}
finally {
    if ($null -ne $contactBitmap) {
        $contactBitmap.Dispose()
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Act I Gameplay Review Panels", "larger crops", "room-specific dialogue captions", "Crop box")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I gameplay review panel report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I gameplay review panel report must stay ASCII-only."
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @("crop_gameplay_panel", "480, 360, 1680, 1080", "act_i_gameplay_review_panels", "dialogue_caption")) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I gameplay review panel builder missing required text: $requiredText"
    }
}

Write-Host "Act I gameplay review panel validation passed: panels=$($panels.Count), contactSheet=present."
