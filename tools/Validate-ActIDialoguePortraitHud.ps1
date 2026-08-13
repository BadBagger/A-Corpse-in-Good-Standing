$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$hudPath = Join-Path $root "game\ui\prologue_hud.gd"
$builderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$reportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$mdPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.md"
$sampleFramePath = Join-Path $root "docs\art\review\act_i_godot_runtime_frames\sabine_office_godot_runtime_frame.png"
$portraitDir = Join-Path $root "game\portraits\act_i"

foreach ($path in @($hudPath, $builderPath, $reportPath, $mdPath, $sampleFramePath, $portraitDir)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I dialogue portrait HUD artifact: $path"
    }
}

$requiredPortraits = @(
    "corvin_neutral.png",
    "tomas_wry.png",
    "registrar_bored.png",
    "prosper_forgetful_kind.png",
    "juno_warm_danger.png",
    "sabine_controlled.png"
)
foreach ($portrait in $requiredPortraits) {
    $path = Join-Path $portraitDir $portrait
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I generated dialogue portrait: $portrait"
    }
}

$hud = Get-Content -LiteralPath $hudPath -Raw
foreach ($requiredText in @(
    "PORTRAIT_BASE",
    "SPEAKER_PORTRAITS",
    "DialogueSpeakerPortraitPlate",
    "DialogueSpeakerPortrait",
    "_add_dialogue_portrait_frame",
    "_set_speaker_portrait",
    "corvin_neutral",
    "sabine_controlled",
    "juno_warm_danger"
)) {
    if (-not $hud.Contains($requiredText)) {
        throw "Playable HUD missing dialogue portrait text: $requiredText"
    }
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @(
    "ROOM_SPEAKER_PORTRAITS",
    "speaker portraits embedded in the generated in-frame HUD",
    "dialogue_portrait",
    "dialogue_portrait_embedded_in_hud",
    "small_icon_frame.png"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Runtime frame builder missing dialogue portrait text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if ([string]$report.runtime_evidence -notmatch "speaker portraits embedded") {
    throw "Act I runtime frame report missing speaker portrait evidence."
}
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I dialogue portrait HUD expected 9 runtime rooms, got $($rooms.Count)."
}
$expectedPortraitByCode = @{
    R01 = "corvin_neutral"
    R02 = "tomas_wry"
    R03 = "corvin_neutral"
    R05 = "registrar_bored"
    R06 = "corvin_neutral"
    R07 = "prosper_forgetful_kind"
    R09 = "corvin_neutral"
    R10 = "juno_warm_danger"
    R12 = "sabine_controlled"
}
foreach ($room in $rooms) {
    $code = [string]$room.room_code
    if (-not $expectedPortraitByCode.ContainsKey($code)) {
        throw "Unexpected runtime portrait room code: $code"
    }
    if (-not [bool]$room.dialogue_portrait_embedded_in_hud) {
        throw "Runtime frame $code missing dialogue portrait HUD flag."
    }
    if ([string]$room.dialogue_portrait -ne [string]$expectedPortraitByCode[$code]) {
        throw "Runtime frame $code has wrong dialogue portrait: $($room.dialogue_portrait)"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("speaker portraits embedded", "Portrait", "sabine_controlled", "juno_warm_danger", "tomas_wry")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I runtime frame markdown missing dialogue portrait text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I runtime frame markdown must stay ASCII-only."
}

Add-Type -AssemblyName System.Drawing
$bitmap = $null
try {
    $bitmap = [System.Drawing.Bitmap]::new($sampleFramePath)
    $nonPanelSamples = 0
    $amberFrameSamples = 0
    $sampleCount = 0
    for ($y = 864; $y -lt 960; $y += 3) {
        for ($x = 548; $x -lt 644; $x += 3) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -le 32) {
                continue
            }
            $sampleCount += 1
            if ($pixel.R -gt 120 -and $pixel.G -gt 70 -and $pixel.G -lt 160 -and $pixel.B -lt 110) {
                $amberFrameSamples += 1
            }
            if ([Math]::Abs($pixel.R - 42) -gt 14 -or [Math]::Abs($pixel.G - 58) -gt 14 -or [Math]::Abs($pixel.B - 64) -gt 14) {
                $nonPanelSamples += 1
            }
        }
    }
    if ($sampleCount -lt 700) {
        throw "Act I dialogue portrait HUD sample area is unexpectedly sparse."
    }
    $nonPanelRatio = $nonPanelSamples / [Math]::Max(1, $sampleCount)
    if ($nonPanelRatio -lt 0.22) {
        throw "Act I dialogue portrait HUD does not visibly contain portrait art in Sabine frame: $([Math]::Round($nonPanelRatio * 100, 3))% non-panel samples."
    }
    $amberRatio = $amberFrameSamples / [Math]::Max(1, $sampleCount)
    if ($amberRatio -lt 0.01) {
        throw "Act I dialogue portrait HUD frame is not visible enough in Sabine frame: $([Math]::Round($amberRatio * 100, 3))% amber samples."
    }
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
}

Write-Host "Act I dialogue portrait HUD validation passed: playable HUD and runtime frames embed generated speaker portraits."
