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
if ([int]$report.frame_count -ne 9) {
    throw "Act I in-scene action review expected 9 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_in_scene_action_contact_sheet.png") {
    throw "Act I in-scene action contact sheet path is not stable."
}
foreach ($requiredText in @("Corvin talk/use/wet side actions", "Salt Market crowd", "turn_to_corvin", "named NPC standee dialogue/counter staging", "visible wet interaction pulses")) {
    if ([string]$report.runtime_evidence -notmatch [regex]::Escape($requiredText)) {
        throw "Act I in-scene action report missing runtime evidence text: $requiredText"
    }
}

$expected = @{
    "salt_market_talk_crowd_turn" = @{ room = "R03"; animation = "talk_side_right"; setpiece = "turn_to_corvin"; frames = 6 }
    "salt_market_use_crowd_turn" = @{ room = "R03"; animation = "use_side_right"; setpiece = "turn_to_corvin"; frames = 8 }
    "old_quay_wet_action" = @{ room = "R02"; animation = "wet_side_right"; setpiece = "water_glint_loop"; frames = 8 }
    "harbor_registry_talk_registrar" = @{ room = "R05"; animation = "talk_side_right"; setpiece = "lamp_smoke_loop"; frames = 6 }
    "bone_chandler_use_counter" = @{ room = "R06"; animation = "use_side_right"; setpiece = "npc_counter_staging"; frames = 8 }
    "almshouse_talk_prosper" = @{ room = "R07"; animation = "talk_side_right"; setpiece = "npc_dialogue_staging"; frames = 6 }
    "grey_float_talk_action" = @{ room = "R10"; animation = "talk_side_right"; setpiece = "steam_loop"; frames = 6 }
    "sabine_office_talk_sabine" = @{ room = "R12"; animation = "talk_side_right"; setpiece = "window_rain_loop"; frames = 6 }
    "fish_hall_wet_drain" = @{ room = "R08"; animation = "wet_side_right"; setpiece = "wet_pulse_drain"; frames = 8 }
}

Add-Type -AssemblyName System.Drawing
$frames = @($report.frames)
if ($frames.Count -ne 9) {
    throw "Act I in-scene action report expected 9 frame records, got $($frames.Count)."
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
    foreach ($flag in @("uses_in_scene_corvin_action", "uses_compact_hud")) {
        if (-not [bool]$frame.$flag) {
            throw "Act I in-scene action frame $id missing flag: $flag"
        }
    }
    if ([string]$frame.room_code -in @("R02", "R05", "R06", "R07", "R10", "R12")) {
        if (-not [bool]$frame.uses_named_npc_standee -or [int]$frame.standee_count -lt 1) {
            throw "Act I in-scene action frame $id must include named NPC standee staging."
        }
    }
    if ([string]$frame.room_code -in @("R02", "R03", "R05", "R10", "R12")) {
        if (-not [bool]$frame.uses_sectional_setpiece_frame) {
            throw "Act I in-scene action frame $id must include an atmosphere or sectional setpiece frame."
        }
    }
    if ($id -in @("old_quay_wet_action", "harbor_registry_talk_registrar", "fish_hall_wet_drain")) {
        if (-not [bool]$frame.uses_interaction_pulse) {
            throw "Act I in-scene action frame $id must include visible wet interaction pulse metadata."
        }
        $pulse = $frame.interaction_pulse
        if ([string]::IsNullOrWhiteSpace([string]$pulse.label)) {
            throw "Act I in-scene action frame $id pulse must include a label."
        }
    }
    $foot = @($frame.corvin_foot)
    if ($foot.Count -ne 2 -or [int]$foot[0] -lt 1 -or [int]$foot[1] -lt 1) {
        throw "Act I in-scene action frame $id must include a valid corvin_foot crop anchor."
    }
    if ([string]$frame.room_code -eq "R03") {
        $crowdHotspot = @($frame.crowd_hotspot)
        if ($crowdHotspot.Count -ne 2) {
            throw "Act I Salt Market action frame $id must include crowd_hotspot anchor metadata."
        }
        if ([double]$frame.crowd_distance_px -lt 260.0) {
            throw "Act I Salt Market action frame $id leaves Corvin too close to crowd hotspot: $($frame.crowd_distance_px)px."
        }
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
foreach ($requiredText in @("Act I In-Scene Action Review", "talk, use, and wet", "turn_to_corvin", "named NPC cases", "visible interaction pulses", "static idle room shots")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I in-scene action report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I in-scene action report must stay ASCII-only."
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @("salt_market_crowd_turn_to_corvin.png", "talk_side_right", "use_side_right", "wet_side_right", "draw_interaction_pulse", "uses_interaction_pulse", "paste_standee", "standee_count", "ImageFilter.MaxFilter", "201, 138, 60", "corvin_foot", "crowd_distance_px", "uses_sectional_setpiece_frame")) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I in-scene action builder missing required text: $requiredText"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @('_play_act_i_setpiece("salt_market_crowd", "turn_to_corvin")', '_play_act_i_interaction_pulse(interaction_key)', "ACT_I_INTERACTION_PULSES", "rope_cleat", "church_sign", "desk_lamp", "drain", "interaction_key == `"market_crowd`"", "verb == `"talk`"", "verb == `"use`"", "verb == `"wet`"")) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing crowd-turn runtime trigger text: $requiredText"
    }
}

Write-Host "Act I in-scene action review validation passed: frames=$($frames.Count), contactSheet=present."
