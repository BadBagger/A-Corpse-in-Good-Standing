$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$reportPath = Join-Path $root "docs\art\salt_market_crowd_setpiece.json"
$scenePath = Join-Path $root "game\rooms\salt_market\room_salt_market.tscn"
$roomScriptPath = Join-Path $root "game\rooms\act_i_greybox_room.gd"
$playerScriptPath = Join-Path $root "game\rooms\sectional_setpiece_player.gd"
$reviewPath = Join-Path $root "docs\art\review\salt_market_crowd_setpiece_review.png"

foreach ($path in @($reportPath, $scenePath, $roomScriptPath, $playerScriptPath, $reviewPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Salt Market crowd setpiece input: $path"
    }
}

$report = Get-Content -LiteralPath $reportPath -Raw | ConvertFrom-Json
if ($report.id -ne "salt_market_crowd") {
    throw "Unexpected setpiece id: $($report.id)"
}
if ([int]$report.bounds.x -ne 1070 -or [int]$report.bounds.y -ne 455 -or [int]$report.bounds.width -ne 520 -or [int]$report.bounds.height -ne 330) {
    throw "Salt Market crowd bounds drifted from the registered sectional region."
}
if ($report.trigger.room_code -ne "R03" -or $report.trigger.hotspot -ne "MarketCrowd" -or $report.trigger.verb -ne "talk") {
    throw "Salt Market crowd trigger drifted."
}

Add-Type -AssemblyName System.Drawing
foreach ($state in @($report.states)) {
    $runtimePath = Join-Path $root ($state.runtime_path -replace '/', '\')
    if (-not (Test-Path -LiteralPath $runtimePath)) {
        throw "Missing runtime setpiece sheet: $($state.runtime_path)"
    }
    $image = [System.Drawing.Bitmap]::new($runtimePath)
    try {
        $expectedWidth = [int]$state.width * [int]$state.frames
        if ($image.Width -ne $expectedWidth -or $image.Height -ne [int]$state.height) {
            throw "Setpiece sheet $($state.runtime_path) dimensions $($image.Width)x$($image.Height), expected ${expectedWidth}x$($state.height)."
        }
        foreach ($point in @(
            @{ X = 0; Y = 0 },
            @{ X = $image.Width - 1; Y = 0 },
            @{ X = 0; Y = $image.Height - 1 },
            @{ X = $image.Width - 1; Y = $image.Height - 1 }
        )) {
            $pixel = $image.GetPixel([int]$point.X, [int]$point.Y)
            if ($pixel.A -ne 0) {
                throw "Setpiece sheet $($state.runtime_path) has an opaque corner at $($point.X),$($point.Y); this would reintroduce a pasted rectangle."
            }
        }

        $opaqueSamples = 0
        $greenDominanceSamples = 0
        for ($y = 0; $y -lt $image.Height; $y += 12) {
            for ($x = 0; $x -lt $image.Width; $x += 12) {
                $pixel = $image.GetPixel($x, $y)
                if ($pixel.A -gt 32) {
                    $opaqueSamples += 1
                    if ($pixel.G -gt ($pixel.R * 1.05) -and $pixel.G -gt ($pixel.B * 1.03) -and $pixel.G -gt 54) {
                        $greenDominanceSamples += 1
                    }
                }
            }
        }
        if ($opaqueSamples -lt 20) {
            throw "Setpiece sheet $($state.runtime_path) appears blank after masking."
        }
        $greenDominancePercent = ($greenDominanceSamples / $opaqueSamples) * 100.0
        if ($greenDominancePercent -gt 0.5) {
            throw "Setpiece sheet $($state.runtime_path) reads too green: $([Math]::Round($greenDominancePercent, 2))% sampled opaque pixels."
        }
    }
    finally {
        $image.Dispose()
    }
}

$scene = Get-Content -LiteralPath $scenePath -Raw
foreach ($requiredText in @(
    '[node name="Props" type="Node2D" parent="."]',
    '[node name="MarketCrowd" type="Area2D" parent="Hotspots"]',
    'interaction_key = "market_crowd"'
)) {
    if ($scene -notmatch [regex]::Escape($requiredText)) {
        throw "Salt Market scene missing required setpiece trigger text: $requiredText"
    }
}

$roomScript = Get-Content -LiteralPath $roomScriptPath -Raw
foreach ($requiredText in @(
    'SECTIONAL_SETPIECE_PLAYER',
    'ACT_I_SETPIECES_BY_ROOM',
    'salt_market_crowd',
    'turn_to_corvin',
    '_play_act_i_setpiece("salt_market_crowd", "turn_to_corvin")'
)) {
    if ($roomScript -notmatch [regex]::Escape($requiredText)) {
        throw "Act I room script missing setpiece runtime text: $requiredText"
    }
}

$playerScript = Get-Content -LiteralPath $playerScriptPath -Raw
foreach ($requiredText in @(
    'func configure(states: Dictionary, default_state: String) -> bool:',
    'func play_state(state_name: String, restart := false) -> bool:',
    'return_state'
)) {
    if ($playerScript -notmatch [regex]::Escape($requiredText)) {
        throw "Sectional setpiece player missing required API text: $requiredText"
    }
}

Write-Host "Salt Market crowd setpiece validation passed: states=$(@($report.states).Count), bounds=$($report.bounds.width)x$($report.bounds.height), trigger=$($report.trigger.hotspot).$($report.trigger.verb)."
