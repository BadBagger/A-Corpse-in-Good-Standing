$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_in_scene_action_review.json"
$mdPath = Join-Path $root "docs\art\act_i_in_scene_action_review.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_in_scene_action_contact_sheet.png"
$builderPath = Join-Path $root "tools\Build-ActIInSceneActionReview.py"
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $builderPath, $roomScriptPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I in-scene action review artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "exported") {
    throw "Act I in-scene action review status must be exported."
}
if ([int]$report.frame_count -ne 4) {
    throw "Act I in-scene action review expected 4 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_in_scene_action_contact_sheet.png") {
    throw "Act I in-scene action contact sheet path is not stable."
}
foreach ($requiredText in @("Corvin talk/use/wet side actions", "Salt Market crowd", "turn_to_corvin")) {
    if ([string]$report.runtime_evidence -notmatch [regex]::Escape($requiredText)) {
        throw "Act I in-scene action report missing runtime evidence text: $requiredText"
    }
}

$expected = @{
    "salt_market_talk_crowd_turn" = @{ room = "R03"; animation = "talk_side_right"; setpiece = "turn_to_corvin"; frames = 6 }
    "salt_market_use_crowd_turn" = @{ room = "R03"; animation = "use_side_right"; setpiece = "turn_to_corvin"; frames = 8 }
    "old_quay_wet_action" = @{ room = "R02"; animation = "wet_side_right"; setpiece = "water_glint_loop"; frames = 8 }
    "grey_float_talk_action" = @{ room = "R10"; animation = "talk_side_right"; setpiece = "steam_loop"; frames = 6 }
}

Add-Type -AssemblyName System.Drawing
$frames = @($report.frames)
if ($frames.Count -ne 4) {
    throw "Act I in-scene action report expected 4 frame records, got $($frames.Count)."
}
$seen = @{}
foreach ($frame in $frames) {
    $id = [string]$frame.id
    if (-not $expected.ContainsKey($id)) {
        throw "Unexpected Act I in-scene action frame id: $id"
    }
    if ($seen.ContainsKey($id)) {
        throw "Duplicate Act I in-scene action frame id: $id"
    }
    $seen[$id] = $true
    $case = $expected[$id]
    if ([string]$frame.room_code -ne [string]$case.room) {
        throw "Act I in-scene action frame $id room mismatch."
    }
    if ([string]$frame.corvin_animation -ne [string]$case.animation) {
        throw "Act I in-scene action frame $id animation mismatch."
    }
    if ([string]$frame.expected_setpiece_state -ne [string]$case.setpiece) {
        throw "Act I in-scene action frame $id setpiece mismatch."
    }
    if ([int]$frame.corvin_frame_count -ne [int]$case.frames) {
        throw "Act I in-scene action frame $id Corvin frame count mismatch."
    }
    foreach ($flag in @("uses_in_scene_corvin_action", "uses_sectional_setpiece_frame", "uses_compact_hud")) {
        if (-not [bool]$frame.$flag) {
            throw "Act I in-scene action frame $id missing flag: $flag"
        }
    }
    $foot = @($frame.corvin_foot)
    if ($foot.Count -ne 2 -or [int]$foot[0] -lt 1 -or [int]$foot[1] -lt 1) {
        throw "Act I in-scene action frame $id must include a valid corvin_foot crop anchor."
    }
    $framePath = Join-Path $root ([string]$frame.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Act I in-scene action frame missing output: $($frame.output)"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        if ($bitmap.Width -ne 1920 -or $bitmap.Height -ne 1080) {
            throw "Act I in-scene action frame $id must be 1920x1080, got $($bitmap.Width)x$($bitmap.Height)."
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
        throw "Missing Act I in-scene action frame id: $id"
    }
}

$contactBitmap = $null
try {
    $contactBitmap = [System.Drawing.Bitmap]::new($contactSheetPath)
    if ($contactBitmap.Width -lt 1400 -or $contactBitmap.Height -lt 650) {
        throw "Act I in-scene action contact sheet is unexpectedly small: $($contactBitmap.Width)x$($contactBitmap.Height)."
    }
}
finally {
    if ($null -ne $contactBitmap) {
        $contactBitmap.Dispose()
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Act I In-Scene Action Review", "talk, use, and wet", "turn_to_corvin", "static idle room shots")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I in-scene action report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I in-scene action report must stay ASCII-only."
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @("salt_market_crowd_turn_to_corvin.png", "talk_side_right", "use_side_right", "wet_side_right", "corvin_foot", "uses_sectional_setpiece_frame")) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I in-scene action builder missing required text: $requiredText"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @('_play_act_i_setpiece("salt_market_crowd", "turn_to_corvin")', "interaction_key == `"market_crowd`"", "verb == `"talk`"", "verb == `"use`"")) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing crowd-turn runtime trigger text: $requiredText"
    }
}

Write-Host "Act I in-scene action review validation passed: frames=$($frames.Count), contactSheet=present."
