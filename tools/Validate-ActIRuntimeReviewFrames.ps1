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
if ([int]$report.frame_count -ne 9) {
    throw "Act I runtime review frame report expected 9 frames, got $($report.frame_count)."
}
if ([string]$report.contact_sheet -ne "docs/art/review/act_i_runtime_frame_contact_sheet.png") {
    throw "Act I runtime review frame contact sheet path is not stable."
}
if ([string]$report.runtime_evidence -notmatch "runtime foreground props" -or [string]$report.runtime_evidence -notmatch "Corvin" -or [string]$report.runtime_evidence -notmatch "generated HUD skin") {
    throw "Act I runtime review frame report must state runtime foreground props, Corvin, and generated HUD evidence."
}
if ([string]$report.runtime_evidence -notmatch "standee wet-floor reflections") {
    throw "Act I runtime review frame report must state standee wet-floor reflection evidence."
}
if ([string]$report.runtime_evidence -notmatch "room-specific dialogue captions and status text embedded in the generated in-frame HUD") {
    throw "Act I runtime review frame report must state embedded generated-HUD dialogue and status evidence."
}

Add-Type -AssemblyName System.Drawing
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I runtime review frame report expected 9 room records, got $($rooms.Count)."
}

$requiredCodes = @("R01", "R02", "R03", "R05", "R06", "R07", "R09", "R10", "R12")
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
    if (-not [bool]$room.dialogue_text_embedded_in_hud) {
        throw "Act I runtime review frame $code must embed dialogue text in the HUD plaque."
    }
    if (-not [bool]$room.status_text_embedded_in_generated_hud) {
        throw "Act I runtime review frame $code must embed status text in the generated HUD strip."
    }
    if ([int]$room.standee_reflection_count -ne [int]$room.standee_count) {
        throw "Act I runtime review frame $code must include one wet-floor reflection per standee."
    }
    $caption = [string]$room.dialogue_caption
    if ([string]::IsNullOrWhiteSpace($caption) -or $caption -eq "Corvin: dead, damp, and still doing the voice.") {
        throw "Act I runtime review frame $code must include a room-specific dialogue caption."
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
    "runtime foreground prop composites",
    "Corvin side sprites",
    "wet-floor reflections",
    "standee reflection",
    "room-specific dialogue captions and status text embedded in the generated in-frame HUD",
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

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @("ROOM_CAPTIONS", "wrap_text", "dialogue_caption", "dialogue_text_embedded_in_hud", "status_text_embedded_in_generated_hud", "caption_font", "prepare_status_strip")) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I runtime review builder missing dialogue caption text: $requiredText"
    }
}
foreach ($requiredText in @("mudflats_tide_glint", "mudflats_openai_prop_composite.png")) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I runtime review builder missing Mudflats runtime review text: $requiredText"
    }
}
if ($builder.Contains("Corvin: dead, damp, and still doing the voice.")) {
    throw "Act I runtime review builder must not use the generic dialogue placeholder."
}
if ($builder.Contains("draw.rectangle((18, 16")) {
    throw "Act I runtime review builder must not draw a black debug status rectangle over the generated HUD."
}

$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @("_make_act_i_standee_reflection", "WetFloorReflection", "reflection_image.flip_y", "Color(0.164706, 0.227451, 0.25098, 0.18)")) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room runtime missing standee reflection text: $requiredText"
    }
}

$scene = Get-Content -LiteralPath $corvinScenePath -Raw
if ($scene.Contains("default_color = Color(0.494118, 0.607843, 0.305882, 1)")) {
    throw "Corvin fallback drip still uses absinthe-green."
}

Write-Host "Act I runtime review frame validation passed: frames=$($rooms.Count), contactSheet=present."
