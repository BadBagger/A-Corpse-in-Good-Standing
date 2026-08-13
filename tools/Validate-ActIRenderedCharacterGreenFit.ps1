$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "docs\art\act_i_godot_runtime_frames.json"
$builderPath = Join-Path $root "tools\Build-ActIGodotRuntimeFrames.py"
$contactSheetPath = Join-Path $root "docs\art\review\act_i_godot_runtime_frame_contact_sheet.png"

foreach ($path in @($reportPath, $builderPath, $contactSheetPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I rendered character green-fit artifact: $path"
    }
}

$builder = Get-Content -LiteralPath $builderPath -Raw
foreach ($requiredText in @(
    "CHARACTER_INTEGRATION_RIM",
    "ROOM_SPEAKER_PORTRAITS",
    "speaker portraits embedded in the generated in-frame HUD"
)) {
    if (-not $builder.Contains($requiredText)) {
        throw "Act I rendered character green-fit builder missing required text: $requiredText"
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
$rooms = @($report.rooms)
if ($rooms.Count -ne 9) {
    throw "Act I rendered character green-fit expected 9 runtime rooms, got $($rooms.Count)."
}
if ([string]$report.runtime_evidence -notmatch "standee character integration rims") {
    throw "Act I rendered character green-fit requires standee integration-rim runtime evidence."
}

$characterZones = @(
    @{ room = "old_quay"; label = "Corvin/Tomas"; x1 = 315; y1 = 440; x2 = 930; y2 = 780; maxGreenDominance = 7.5; minAmber = 0.08 },
    @{ room = "harbor_registry"; label = "Corvin/Registrar"; x1 = 690; y1 = 395; x2 = 1375; y2 = 795; maxGreenDominance = 6.0; minAmber = 0.06 },
    @{ room = "bone_chandler"; label = "Corvin/Chandler"; x1 = 650; y1 = 410; x2 = 1365; y2 = 820; maxGreenDominance = 6.0; minAmber = 0.06 },
    @{ room = "almshouse"; label = "Corvin/Prosper"; x1 = 745; y1 = 430; x2 = 1360; y2 = 825; maxGreenDominance = 6.0; minAmber = 0.06 },
    @{ room = "church_of_the_drowned"; label = "Corvin/Teodor"; x1 = 760; y1 = 380; x2 = 1390; y2 = 780; maxGreenDominance = 9.0; minAmber = 0.04 },
    @{ room = "grey_float"; label = "Corvin/Juno"; x1 = 710; y1 = 380; x2 = 1425; y2 = 790; maxGreenDominance = 6.0; minAmber = 0.08 },
    @{ room = "sabine_office"; label = "Corvin/Sabine"; x1 = 700; y1 = 370; x2 = 1400; y2 = 790; maxGreenDominance = 5.0; minAmber = 0.06 }
)

$roomsById = @{}
foreach ($room in $rooms) {
    $roomsById[[string]$room.room_id] = $room
}

Add-Type -AssemblyName System.Drawing
$results = @()
foreach ($zone in $characterZones) {
    if (-not $roomsById.ContainsKey([string]$zone.room)) {
        throw "Act I rendered character green-fit missing runtime room: $($zone.room)"
    }
    $room = $roomsById[[string]$zone.room]
    $framePath = Join-Path $root ([string]$room.output -replace "/", "\")
    if (-not (Test-Path -LiteralPath $framePath)) {
        throw "Act I rendered character green-fit missing frame: $($room.output)"
    }

    $bitmap = $null
    try {
        $bitmap = [System.Drawing.Bitmap]::new($framePath)
        $samples = 0
        $greenDominant = 0
        $wrongLightGreen = 0
        $amber = 0
        for ($y = [int]$zone.y1; $y -lt [int]$zone.y2; $y += 4) {
            for ($x = [int]$zone.x1; $x -lt [int]$zone.x2; $x += 4) {
                $pixel = $bitmap.GetPixel($x, $y)
                if ($pixel.A -le 32) {
                    continue
                }
                if ($pixel.R -lt 18 -and $pixel.G -lt 22 -and $pixel.B -lt 24) {
                    continue
                }
                $samples += 1
                if ($pixel.G -gt ($pixel.R * 1.12) -and $pixel.G -gt ($pixel.B * 1.08) -and $pixel.G -gt 56) {
                    $greenDominant += 1
                }
                if ($pixel.G -gt 92 -and $pixel.R -lt 160 -and $pixel.B -lt 140 -and $pixel.G -gt ($pixel.R * 1.04)) {
                    $wrongLightGreen += 1
                }
                if ($pixel.R -gt 95 -and $pixel.G -gt 52 -and $pixel.G -lt 165 -and $pixel.B -lt 120 -and $pixel.R -gt ($pixel.B * 1.15)) {
                    $amber += 1
                }
            }
        }
        if ($samples -lt 2400) {
            throw "Act I rendered character green-fit zone $($zone.room) / $($zone.label) is unexpectedly sparse: $samples samples."
        }
        $greenPercent = [Math]::Round(($greenDominant / [Math]::Max(1, $samples)) * 100, 3)
        $wrongLightPercent = [Math]::Round(($wrongLightGreen / [Math]::Max(1, $samples)) * 100, 3)
        $amberPercent = [Math]::Round(($amber / [Math]::Max(1, $samples)) * 100, 3)
        if ($greenPercent -gt [double]$zone.maxGreenDominance) {
            throw "Act I rendered character green-fit zone $($zone.room) / $($zone.label) reads too green: $greenPercent% over $($zone.maxGreenDominance)%."
        }
        if ($amberPercent -lt [double]$zone.minAmber) {
            throw "Act I rendered character green-fit zone $($zone.room) / $($zone.label) lacks warm character integration: $amberPercent% under $($zone.minAmber)%."
        }
        $results += [pscustomobject]@{
            room = [string]$zone.room
            label = [string]$zone.label
            green_dominance_percent = $greenPercent
            wrong_light_green_percent = $wrongLightPercent
            amber_integration_percent = $amberPercent
        }
    }
    finally {
        if ($null -ne $bitmap) {
            $bitmap.Dispose()
        }
    }
}

$maxGreen = ($results | Measure-Object -Property green_dominance_percent -Maximum).Maximum
$maxWrong = ($results | Measure-Object -Property wrong_light_green_percent -Maximum).Maximum
Write-Host "Act I rendered character green-fit validation passed: zones=$($results.Count), maxGreenDominance=$maxGreen%, maxWrongLightGreen=$maxWrong%."
