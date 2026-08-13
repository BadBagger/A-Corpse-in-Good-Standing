$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\corvin_action_runtime_frames.json"
$mdPath = Join-Path $root "docs\art\corvin_action_runtime_frames.md"
$contactSheetPath = Join-Path $root "docs\art\review\corvin_action_runtime_contact_sheet.png"
$captureScriptPath = Join-Path $root "tools\godot_capture_corvin_action_frames.gd"
$wrapperPath = Join-Path $root "tools\Capture-CorvinActionRuntimeFrames.ps1"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $captureScriptPath, $wrapperPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Corvin action runtime artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "captured") {
    throw "Corvin action runtime report must have status captured."
}
if ([string]$report.capture -ne "godot_subviewport") {
    throw "Corvin action runtime report must identify capture as godot_subviewport."
}
if ([int]$report.frame_count -ne 8) {
    throw "Corvin action runtime report expected 8 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/corvin_action_runtime_contact_sheet.png") {
    throw "Corvin action runtime contact sheet path is not stable."
}
foreach ($requiredText in @("actual Corvin character scene", "RuntimeSprite loader", "idle, talk, use, and wet side animations")) {
    if ([string]$report.runtime_evidence -notmatch [regex]::Escape($requiredText)) {
        throw "Corvin action runtime report missing runtime evidence text: $requiredText"
    }
}

$expected = @{
    "idle_side_right" = @{ method = "play_idle_side_right"; animation = "idle_side_right"; frames = 12 }
    "talk_side_right" = @{ method = "play_talk_side_right"; animation = "talk_side_right"; frames = 6 }
    "use_side_right" = @{ method = "play_use_side_right"; animation = "use_side_right"; frames = 8 }
    "wet_side_right" = @{ method = "play_wet_side_right"; animation = "wet_side_right"; frames = 8 }
    "idle_side_left" = @{ method = "play_idle_side_left"; animation = "idle_side_left"; frames = 12 }
    "talk_side_left" = @{ method = "play_talk_side_left"; animation = "talk_side_left"; frames = 6 }
    "use_side_left" = @{ method = "play_use_side_left"; animation = "use_side_left"; frames = 8 }
    "wet_side_left" = @{ method = "play_wet_side_left"; animation = "wet_side_left"; frames = 8 }
}

Add-Type -AssemblyName System.Drawing
$frames = @($report.frames)
if ($frames.Count -ne 8) {
    throw "Corvin action runtime report expected 8 frame records, got $($frames.Count)."
}
$seen = @{}
foreach ($frame in $frames) {
    $id = [string]$frame.id
    if (-not $expected.ContainsKey($id)) {
        throw "Unexpected Corvin action runtime frame id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Corvin action runtime frame id: $id"
    }
    $seen[$id] = $true
    $case = $expected[$id]
    if ([string]$frame.method -ne [string]$case.method) {
        throw "Corvin action frame $id method mismatch."
    }
    if ([string]$frame.active_animation -ne [string]$case.animation) {
        throw "Corvin action frame $id active animation mismatch."
    }
    if ([int]$frame.frame_count -ne [int]$case.frames) {
        throw "Corvin action frame $id frame count mismatch."
    }
    foreach ($flag in @("uses_actual_corvin_scene", "uses_runtime_sprite_loader")) {
        if (-not [bool]$frame.$flag) {
            throw "Corvin action frame $id missing flag: $flag"
        }
    }
    $framePath = Join-Path $root ([string]$frame.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Corvin action runtime frame missing output: $($frame.output)"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        if ($bitmap.Width -ne 640 -or $bitmap.Height -ne 720) {
            throw "Corvin action frame $id must be 640x720, got $($bitmap.Width)x$($bitmap.Height)."
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}
foreach ($id in $expected.Keys) {
    if (-not $seen.ContainsKey($id)) {
        throw "Missing Corvin action runtime frame id: $id"
    }
}

$contactBitmap = $null
try {
    $contactBitmap = [System.Drawing.Bitmap]::new($contactSheetPath)
    if ($contactBitmap.Width -lt 1300 -or $contactBitmap.Height -lt 700) {
        throw "Corvin action runtime contact sheet is unexpectedly small: $($contactBitmap.Width)x$($contactBitmap.Height)."
    }
}
finally {
    if ($null -ne $contactBitmap) {
        $contactBitmap.Dispose()
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Corvin Action Runtime Frames", "character_corvin.tscn", "RuntimeSprite", "talk", "use", "wet")) {
    if (-not $md.Contains($requiredText)) {
        throw "Corvin action runtime report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Corvin action runtime report must stay ASCII-only."
}

$captureScript = Get-Content -LiteralPath $captureScriptPath -Raw
foreach ($requiredText in @("character_corvin.tscn", "SubViewport", "play_talk_side_right", "play_use_side_right", "play_wet_side_right")) {
    if (-not $captureScript.Contains($requiredText)) {
        throw "Corvin action runtime capture script missing required text: $requiredText"
    }
}

Write-Host "Corvin action runtime frame validation passed: frames=$($frames.Count), contactSheet=present."
