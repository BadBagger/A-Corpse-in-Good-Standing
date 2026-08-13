$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$builderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$runtimeReportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$runtimeReportMdPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.md"

foreach ($path in @($roomScriptPath, $builderPath, $runtimeReportPath, $runtimeReportMdPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I living scene cue artifact: $path"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    "ACT_I_LIVING_SCENE_CUES_BY_ROOM",
    "ActILivingSceneCues",
    "_add_act_i_living_scene_cues",
    "_add_act_i_living_scene_cue",
    "_add_act_i_living_light_pool",
    "_animate_act_i_living_scene_cue",
    "_make_act_i_ellipse_polygon",
    "ledger_wrong_light",
    "confession_hall_wrong_light",
    "float_warmth_trap",
    "window_rain_silver"
)) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Playable Act I room script missing living-scene cue text: $requiredText"
    }
}
if ($roomScript -notmatch "create_tween\(\).*[\s\S]*set_loops\(\)") {
    throw "Playable Act I living scene cues must use looping tweens, not static overlays."
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @(
    "LIVING_SCENE_CUES",
    "draw_living_scene_cues",
    "living_scene_cue_count",
    "living_scene_cues",
    "looping living scene cues",
    "wrong-light pools"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I runtime frame builder missing living-scene cue text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json
if ([string]$report.runtime_evidence -notmatch "looping living scene cues") {
    throw "Act I runtime report must state that living scene cues are present."
}
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I living scene cue report expected 9 runtime rooms, got $($rooms.Count)."
}
$expectedCounts = @{
    R01 = 2
    R02 = 2
    R03 = 2
    R05 = 2
    R06 = 1
    R07 = 1
    R09 = 2
    R10 = 2
    R12 = 2
}
foreach ($room in $rooms) {
    $code = [string]$room.room_code
    if (-not $expectedCounts.ContainsKey($code)) {
        throw "Unexpected living scene cue room code: $code"
    }
    if ([int]$room.living_scene_cue_count -ne [int]$expectedCounts[$code]) {
        throw "Room $code has wrong living scene cue count: $($room.living_scene_cue_count)"
    }
    if (@($room.living_scene_cues).Count -ne [int]$expectedCounts[$code]) {
        throw "Room $code living scene cue id list does not match expected count."
    }
}

$md = Get-Content -LiteralPath $runtimeReportMdPath -Raw
foreach ($requiredText in @("looping living scene cues", "Living cues", "wrong-light pools")) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I runtime frame markdown missing living-scene cue text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I runtime frame markdown must stay ASCII-only."
}

Add-Type -AssemblyName System.Drawing
$sampleChecks = @(
    @{ room = "docs\art\review\act_i_godot_runtime_frames\grey_float_godot_runtime_frame.png"; label = "Grey Float warmth"; x1 = 760; y1 = 585; x2 = 1510; y2 = 805; minAmber = 4.0; maxGreen = 6.0 },
    @{ room = "docs\art\review\act_i_godot_runtime_frames\church_of_the_drowned_godot_runtime_frame.png"; label = "Church wrong light"; x1 = 620; y1 = 330; x2 = 1180; y2 = 535; minGreen = 0.25; maxAmber = 12.0 },
    @{ room = "docs\art\review\act_i_godot_runtime_frames\sabine_office_godot_runtime_frame.png"; label = "Sabine lamp hold"; x1 = 780; y1 = 585; x2 = 1450; y2 = 760; minAmber = 2.0; maxGreen = 5.0 }
)
foreach ($check in $sampleChecks) {
    $framePath = Join-Path $root ([string]$check.room)
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Missing living scene cue sample frame: $framePath"
    }
    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        $samples = 0
        $amber = 0
        $green = 0
        for ($y = [int]$check.y1; $y -lt [int]$check.y2; $y += 5) {
            for ($x = [int]$check.x1; $x -lt [int]$check.x2; $x += 5) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -le 32) {
                    continue
                }
                $samples += 1
                if ($pixel.R -gt 90 -and $pixel.G -gt 50 -and $pixel.G -lt 170 -and $pixel.B -lt 125 -and $pixel.R -gt ($pixel.B * 1.15)) {
                    $amber += 1
                }
                if ($pixel.G -gt ($pixel.R * 1.08) -and $pixel.G -gt ($pixel.B * 1.04) -and $pixel.G -gt 72) {
                    $green += 1
                }
            }
        }
        if ($samples -lt 1600) {
            throw "Living scene cue sample $($check.label) is unexpectedly sparse: $samples samples."
        }
        $amberPercent = [Math]::Round(($amber / [Math]::Max(1, $samples)) * 100, 3)
        $greenPercent = [Math]::Round(($green / [Math]::Max(1, $samples)) * 100, 3)
        if ($check.ContainsKey("minAmber") -and $amberPercent -lt [double]$check.minAmber) {
            throw "Living scene cue sample $($check.label) lacks amber integration: $amberPercent% under $($check.minAmber)%."
        }
        if ($check.ContainsKey("maxAmber") -and $amberPercent -gt [double]$check.maxAmber) {
            throw "Living scene cue sample $($check.label) has too much amber for a wrong-light zone: $amberPercent% over $($check.maxAmber)%."
        }
        if ($check.ContainsKey("minGreen") -and $greenPercent -lt [double]$check.minGreen) {
            throw "Living scene cue sample $($check.label) lacks intentional wrong-light green: $greenPercent% under $($check.minGreen)%."
        }
        if ($check.ContainsKey("maxGreen") -and $greenPercent -gt [double]$check.maxGreen) {
            throw "Living scene cue sample $($check.label) is too green: $greenPercent% over $($check.maxGreen)%."
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

Write-Host "Act I living scene cue validation passed: rooms=$($rooms.Count), runtime cues animate and screenshot evidence is palette-bounded."
