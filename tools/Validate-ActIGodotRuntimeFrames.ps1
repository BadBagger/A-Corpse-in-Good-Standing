$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$mdPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.md"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_godot_runtime_frame_contact_sheet.png"
$captureScriptPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$wrapperPath = Join-Path $root "tools\Capture-ActIGodotRuntimeFrames.ps1"

foreach ($path in @($jsonPath, $mdPath, $contactSheetPath, $captureScriptPath, $wrapperPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I Godot runtime frame artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "captured") {
    throw "Act I Godot runtime frame report must have status captured."
}
if ([string]$report.capture -ne "godot_runtime_composition") {
    throw "Act I Godot runtime frame report must identify the capture as godot_runtime_composition."
}
if ([int]$report.frame_count -ne 9) {
    throw "Act I Godot runtime frame report expected 9 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_godot_runtime_frame_contact_sheet.png") {
    throw "Act I Godot runtime frame contact sheet path is not stable."
}
foreach ($requiredText in @("actual room scene background paths", "shared runtime art constants", "runtime foreground props", "wet-floor reflections", "standee wet-floor reflections", "room-specific dialogue captions", "actual Corvin character scene", "RuntimeSprite loader")) {
    if ([string]$report.runtime_evidence -notmatch [regex]::Escape($requiredText)) {
        throw "Act I Godot runtime report missing runtime evidence text: $requiredText"
    }
}

Add-Type -AssemblyName System.Drawing
$requiredCodes = @("R01", "R02", "R03", "R05", "R06", "R07", "R09", "R10", "R12")
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I Godot runtime report expected 9 room records, got $($rooms.Count)."
}
$seen = @{}
foreach ($room in $rooms) {
    $code = [string]$room.room_code
    if ($code -notin $requiredCodes) {
        throw "Unexpected Act I Godot runtime room code: $code"
    }
    if ($seen.ContainsKey($code)) {
        throw "Duplicate Act I Godot runtime room code: $code"
    }
    $seen[$code] = $true
    foreach ($flag in @("includes_godot_runtime_composition", "includes_actual_corvin_scene", "includes_corvin_runtime_sprite_loader", "uses_room_scene_background", "uses_shared_room_art_constants", "uses_direct_png_loading")) {
        if (-not [bool]$room.$flag) {
            throw "Act I Godot runtime frame $code missing flag: $flag"
        }
    }
    $propCount = [int]$room.foreground_prop_count
    if ($propCount -lt 1) {
        throw "Act I Godot runtime frame $code must include foreground props."
    }
    if ([int]$room.contact_shadow_count -ne $propCount) {
        throw "Act I Godot runtime frame $code contact shadow count must equal foreground prop count."
    }
    if ([int]$room.wet_reflection_count -ne $propCount) {
        throw "Act I Godot runtime frame $code wet reflection count must equal foreground prop count."
    }
    if ([int]$room.standee_reflection_count -ne [int]$room.standee_count) {
        throw "Act I Godot runtime frame $code must include one wet-floor reflection per standee."
    }
    $caption = [string]$room.dialogue_caption
    if ([string]::IsNullOrWhiteSpace($caption) -or $caption -eq "Corvin: dead, damp, and still doing the voice.") {
        throw "Act I Godot runtime frame $code must include a room-specific dialogue caption."
    }
    $framePath = Join-Path $root ([string]$room.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Act I Godot runtime frame missing output: $($room.output)"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        if ($bitmap.Width -ne 1920 -or $bitmap.Height -ne 1080) {
            throw "Act I Godot runtime frame $code must be 1920x1080, got $($bitmap.Width)x$($bitmap.Height)."
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
        throw "Missing Act I Godot runtime room code: $code"
    }
}

$contactBitmap = $null
try {
    $contactBitmap = [System.Drawing.Bitmap]::new($contactSheetPath)
    if ($contactBitmap.Width -lt 900 -or $contactBitmap.Height -lt 1000) {
        throw "Act I Godot runtime contact sheet is unexpectedly small: $($contactBitmap.Width)x$($contactBitmap.Height)."
    }
}
finally {
    if ($null -ne $contactBitmap) {
        $contactBitmap.Dispose()
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Act I Godot Runtime Frames", "Godot runtime", "actual room scene background paths", "shared runtime art constants", "runtime foreground props", "wet-floor reflections", "standee wet-floor reflections", "room-specific dialogue captions", "Dialogue caption", "actual Corvin character scene")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I Godot runtime report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I Godot runtime report must stay ASCII-only."
}

$captureScript = Get-Content -LiteralPath $captureScriptPath -Raw
foreach ($requiredText in @("act_i_godot_runtime_frames", "godot_runtime_composition", "foreground_prop_count", "draw_wet_floor_reflection", "standee_reflection_count", "ROOM_CAPTIONS", "wrap_text", "dialogue_caption", 'game" / "characters" / "corvin', "RuntimeSprite", "direct PNG loading")) {
    if (-not $captureScript.Contains($requiredText)) {
        throw "Act I Godot runtime capture script missing required text: $requiredText"
    }
}
foreach ($requiredText in @("mudflats_tide_glint", "mudflats_openai_prop_composite.png")) {
    if (-not $captureScript.Contains($requiredText)) {
        throw "Act I Godot runtime capture script missing Mudflats runtime review text: $requiredText"
    }
}
if ($captureScript.Contains("Corvin: dead, damp, and still doing the voice.")) {
    throw "Act I Godot runtime capture script must not use the generic dialogue placeholder."
}

$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @("_make_act_i_standee_reflection", "WetFloorReflection", "reflection_image.flip_y")) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I Godot room script missing standee reflection text: $requiredText"
    }
}

Write-Host "Act I Godot runtime frame validation passed: frames=$($rooms.Count), contactSheet=present."
