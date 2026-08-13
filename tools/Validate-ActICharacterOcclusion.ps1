$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$runtimeBuilderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$runtimeReportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$sampleFramePath = Join-Path $root "docs\art\review\act_i_godot_runtime_frames\sabine_office_godot_runtime_frame.png"

foreach ($path in @($roomScriptPath, $runtimeBuilderPath, $runtimeReportPath, $sampleFramePath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I character occlusion artifact: $path"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    "ACT_I_CHARACTER_OCCLUDERS_BY_ROOM",
    "ActICharacterOccluders",
    "_add_act_i_character_occluders",
    "_add_act_i_character_occluder",
    "CharacterOccluder",
    "region_enabled",
    "region_rect",
    "crop_top_ratio",
    '"harbormaster_desk"',
    '"bone_trade_counter"',
    '"juno_ledger_table"'
)) {
    if (-not $roomScript.Contains($requiredText)) {
        throw "Act I room script missing character occlusion runtime text: $requiredText"
    }
}

$builder = Get-Content -LiteralPath $runtimeBuilderPath -Raw
foreach ($requiredText in @(
    "character_occluders",
    "paste_character_occluder",
    "character_occluder_count",
    "foreground character occluders"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I runtime frame builder missing character occlusion text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $runtimeReportPath -Raw | ConvertFrom-Json
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I character occlusion expected 9 runtime rooms, got $($rooms.Count)."
}

$expectedCounts = @{
    harbor_registry = 1
    bone_chandler = 1
    almshouse = 1
    church_of_the_drowned = 1
    grey_float = 2
    sabine_office = 2
}

$totalOccluders = 0
foreach ($room in $rooms) {
    $roomId = [string]$room.room_id
    $count = [int]$room.character_occluder_count
    if ($expectedCounts.ContainsKey($roomId)) {
        if ($count -ne [int]$expectedCounts[$roomId]) {
            throw "Act I runtime frame report has wrong character occluder count for ${roomId}: $count"
        }
    }
    elseif ($count -ne 0) {
        throw "Unexpected Act I character occluders in room ${roomId}: $count"
    }
    $totalOccluders += $count
}
if ($totalOccluders -ne 8) {
    throw "Act I character occlusion expected 8 total foreground occluders, got $totalOccluders."
}

Add-Type -AssemblyName System.Drawing
$bitmap = $null
try {
    $bitmap = [System.Drawing.Bitmap]::new($sampleFramePath)
    $deskSamples = 0
    $darkInkSamples = 0
    $amberRimSamples = 0

    # Sabine's desk should sit in front of the character band. This region
    # catches the foreground prop slice that is composited after Corvin/Sabine.
    for ($y = 680; $y -lt 815; $y += 3) {
        for ($x = 930; $x -lt 1320; $x += 3) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -le 32) {
                continue
            }
            $deskSamples += 1
            if ($pixel.R -lt 75 -and $pixel.G -lt 85 -and $pixel.B -lt 85) {
                $darkInkSamples += 1
            }
            if ($pixel.R -gt 110 -and $pixel.G -gt 65 -and $pixel.G -lt 145 -and $pixel.B -lt 95 -and $pixel.R -gt ($pixel.B * 1.35)) {
                $amberRimSamples += 1
            }
        }
    }

    if ($deskSamples -lt 1000) {
        throw "Act I character occlusion Sabine desk sample area is unexpectedly sparse."
    }
    $darkRatio = $darkInkSamples / [Math]::Max(1, $deskSamples)
    if ($darkRatio -lt 0.18) {
        throw "Act I character occlusion desk slice is not visually present enough in Sabine frame: $([Math]::Round($darkRatio * 100, 3))% dark ink samples."
    }
    $amberRatio = $amberRimSamples / [Math]::Max(1, $deskSamples)
    if ($amberRatio -gt 0.12) {
        throw "Act I character occlusion leaves too much character rim over the foreground desk slice: $([Math]::Round($amberRatio * 100, 3))% amber samples."
    }
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
}

Write-Host "Act I character occlusion validation passed: foreground prop slices restore depth over characters in runtime frames."
