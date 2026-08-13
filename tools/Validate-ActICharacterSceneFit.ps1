$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$runtimeBuilderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$runtimeReportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$standeeDir = Join-Path $root "game\standees\act_i"

foreach ($path in @($roomScriptPath, $runtimeBuilderPath, $runtimeReportPath, $standeeDir)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I character scene-fit artifact: $path"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    "ACT_I_CHARACTER_INTEGRATION_RIM_COLOR",
    "ACT_I_CHARACTER_INTEGRATION_RIM_OFFSETS",
    "_make_act_i_standee_integration_rim",
    "CharacterIntegrationRim",
    "_make_act_i_standee_shadow",
    "_make_act_i_standee_reflection"
)) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing character scene-fit runtime text: $requiredText"
    }
}

$builder = Get-Content -LiteralPath $runtimeBuilderPath -Raw
foreach ($requiredText in @(
    "CHARACTER_INTEGRATION_RIM",
    "CHARACTER_INTEGRATION_RIM_OFFSETS",
    "draw_character_integration_rim",
    "standee_character_integration_rim_count"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I runtime frame builder missing character scene-fit text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I character scene-fit expected 9 runtime rooms, got $($rooms.Count)."
}

$standeeRows = @(
    @{ room = "old_quay"; id = "tomas_bollard"; foot_y = 735; scale = 1.0 },
    @{ room = "harbor_registry"; id = "registrar"; foot_y = 705; scale = 0.78 },
    @{ room = "bone_chandler"; id = "bone_chandler"; foot_y = 760; scale = 0.78 },
    @{ room = "almshouse"; id = "prosper"; foot_y = 775; scale = 0.82 },
    @{ room = "church_of_the_drowned"; id = "teodor"; foot_y = 740; scale = 0.78 },
    @{ room = "grey_float"; id = "juno"; foot_y = 745; scale = 0.75 },
    @{ room = "sabine_office"; id = "sabine"; foot_y = 735; scale = 0.76 }
)

Add-Type -AssemblyName System.Drawing

foreach ($row in $standeeRows) {
    $assetPath = Join-Path $standeeDir "$($row.id).png"
    if (-not (Test-Path -LiteralPath $assetPath)) {
        throw "Missing Act I standee scene-fit asset: $assetPath"
    }

    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($assetPath)
        $scaledHeight = [Math]::Round($bitmap.Height * [double]$row.scale)
        $scaledWidth = [Math]::Round($bitmap.Width * [double]$row.scale)
        if ($scaledHeight -lt 285 -or $scaledHeight -gt 410) {
            throw "Act I standee $($row.id) has bad in-scene height $scaledHeight px; expected 285-410 px so people fit room furniture scale."
        }
        if ($scaledWidth -gt 360) {
            throw "Act I standee $($row.id) has bad in-scene width $scaledWidth px; expected <=360 px."
        }
        if ([int]$row.foot_y -lt 690 -or [int]$row.foot_y -gt 790) {
            throw "Act I standee $($row.id) foot position $($row.foot_y) is outside the playable ground band."
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$roomsById = @{}
foreach ($room in $rooms) {
    $roomsById[[string]$room.room_id] = $room
}

foreach ($row in $standeeRows) {
    if (-not $roomsById.ContainsKey($row.room)) {
        throw "Act I character scene-fit report missing room: $($row.room)"
    }
    $room = $roomsById[$row.room]
    if ([int]$room.standee_count -lt 1) {
        throw "Act I character scene-fit report missing standee count for room: $($row.room)"
    }
    if ([int]$room.standee_reflection_count -ne [int]$room.standee_count) {
        throw "Act I character scene-fit report missing standee reflections for room: $($row.room)"
    }
    if ([int]$room.standee_character_integration_rim_count -ne [int]$room.standee_count) {
        throw "Act I character scene-fit report missing integration rims for room: $($row.room)"
    }
    if (-not (Test-Path -LiteralPath (Join-Path $root ([string]$room.output -replace "/", "\")))) {
        throw "Act I character scene-fit runtime frame missing: $($room.output)"
    }
}

$sampleFramePath = Join-Path $root "docs\art\review\act_i_godot_runtime_frames\sabine_office_godot_runtime_frame.png"
$sample = $null
try {
    $sample = [System.Drawing.Bitmap]::new($sampleFramePath)
    $amberSamples = 0
    $greenDominantSamples = 0
    $totalSamples = 0
    for ($y = 250; $y -lt 750; $y += 4) {
        for ($x = 1040; $x -lt 1400; $x += 4) {
            $pixel = $sample.GetPixel($x, $y)
            if ($pixel.A -le 32) {
                continue
            }
            $totalSamples += 1
            if ($pixel.R -gt 110 -and $pixel.G -gt 65 -and $pixel.G -lt 145 -and $pixel.B -lt 95 -and $pixel.R -gt ($pixel.B * 1.35)) {
                $amberSamples += 1
            }
            if ($pixel.G -gt ($pixel.R * 1.12) -and $pixel.G -gt ($pixel.B * 1.08)) {
                $greenDominantSamples += 1
            }
        }
    }
    if ($totalSamples -lt 1000) {
        throw "Act I character scene-fit Sabine sample area is unexpectedly sparse."
    }
    $amberRatio = $amberSamples / [Math]::Max(1, $totalSamples)
    if ($amberRatio -lt 0.002 -or $amberRatio -gt 0.09) {
        throw "Act I character integration rim is not visible at the expected subtle range in Sabine frame: $([Math]::Round($amberRatio * 100, 3))% amber samples."
    }
    $greenRatio = $greenDominantSamples / [Math]::Max(1, $totalSamples)
    if ($greenRatio -gt 0.045) {
        throw "Act I character scene-fit sample has too much green dominance in Sabine frame: $([Math]::Round($greenRatio * 100, 3))%."
    }
}
finally {
    if ($null -ne $sample) {
        $sample.Dispose()
    }
}

Write-Host "Act I character scene-fit validation passed: standees are scaled, grounded, reflected, rim-lit, and green-controlled in runtime frames."
