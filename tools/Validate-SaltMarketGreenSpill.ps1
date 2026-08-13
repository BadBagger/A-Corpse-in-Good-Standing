$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\salt_market_green_spill_grade.json"
$mdPath = Join-Path $root "docs\art\salt_market_green_spill_grade.md"
$scriptPath = Join-Path $root "tools\Fix-SaltMarketGreenSpill.py"
$gameplayPanelPath = Join-Path $root "docs\art\review\act_i_gameplay_review_panels\salt_market_gameplay_panel.png"

foreach ($path in @($jsonPath, $mdPath, $scriptPath, $gameplayPanelPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Salt Market green-spill artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "graded") {
    throw "Salt Market green-spill report must have graded status."
}
if ([int]$report.target_count -ne 5) {
    throw "Salt Market green-spill report expected 5 targets, got $($report.target_count)."
}
if ([string]$report.rule -notmatch "sky/Church/wrong-light only") {
    throw "Salt Market green-spill report must preserve the allowed wrong-light exception."
}
if ([double]$report.max_green_spill_percent_after -gt 0.35) {
    throw "Salt Market green-spill maximum after-grade is too high: $($report.max_green_spill_percent_after)%."
}

$required = @(
    "game/rooms/salt_market/background/salt_market_bg.png",
    "game/rooms/salt_market/props/boot_stall.png",
    "game/rooms/salt_market/props/fishmonger.png",
    "game/rooms/salt_market/props/market_crowd_dressing.png",
    "game/rooms/salt_market/props/confession_queue.png"
)
$seen = @{}
foreach ($record in @($report.records)) {
    $asset = [string]$record.asset
    if ($asset -notin $required) {
        throw "Unexpected Salt Market green-spill asset: $asset"
    }
    $seen[$asset] = $true
    if ([double]$record.green_spill_percent_after -gt 0.35) {
        throw "Salt Market green-spill asset $asset still exceeds after-grade cap: $($record.green_spill_percent_after)%."
    }
    $absoluteAsset = Join-Path $root ($asset -replace "/", "\")
    if (-not (Test-Path -LiteralPath $absoluteAsset)) {
        throw "Missing graded Salt Market asset: $asset"
    }
}
foreach ($asset in $required) {
    if (-not $seen.ContainsKey($asset)) {
        throw "Salt Market green-spill report missing asset: $asset"
    }
}

$backgroundRecord = @($report.records) | Where-Object { [string]$_.asset -eq "game/rooms/salt_market/background/salt_market_bg.png" } | Select-Object -First 1
if ($null -eq $backgroundRecord) {
    throw "Salt Market green-spill report missing the background market/crowd band record."
}
if ([double]$backgroundRecord.green_spill_percent_before -le 0.5) {
    throw "Salt Market green-spill background record must prove it found the visible market/crowd spill before grading."
}
if ([int]$backgroundRecord.changed_pixels -lt 1000) {
    throw "Salt Market green-spill background record changed too few pixels to support the visible crowd/market correction."
}
$changedRecordCount = @($report.records | Where-Object { [int]$_.changed_pixels -gt 0 }).Count
if ($changedRecordCount -lt 1) {
    throw "Salt Market green-spill pass did not change any target assets."
}

$script = Get-Content -LiteralPath $scriptPath -Raw
foreach ($requiredText in @("is_green_spill", "sky and distant Church glow", "market, crowd, cloth", "wet black, harbor slate, and whale-oil amber")) {
    if (-not $script.Contains($requiredText)) {
        throw "Salt Market green-spill script missing required text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @("Salt Market Green Spill Grade", "Max green spill after", "game/rooms/salt_market/background/salt_market_bg.png")) {
    if (-not $md.Contains($requiredText)) {
        throw "Salt Market green-spill report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Salt Market green-spill report must stay ASCII-only."
}

Add-Type -AssemblyName System.Drawing
$bitmap = $null
try {
    $bitmap = [System.Drawing.Bitmap]::new($gameplayPanelPath)
    $greenishSamples = 0
    $humanBandSamples = 0
    # The crop panel is 1200x720 from the runtime frame. This band corresponds
    # to the visible Salt Market crowd/market foreground, excluding the top sky.
    for ($y = 150; $y -lt 500; $y += 4) {
        for ($x = 0; $x -lt 1040; $x += 4) {
            $pixel = $bitmap.GetPixel($x, $y)
            if ($pixel.A -le 32) {
                continue
            }
            $humanBandSamples += 1
            if ($pixel.G -gt ($pixel.R * 1.08) -and $pixel.G -gt ($pixel.B * 0.96) -and $pixel.G -gt 62) {
                $greenishSamples += 1
            }
        }
    }
    $ratio = $greenishSamples / [Math]::Max(1, $humanBandSamples)
    if ($ratio -gt 0.035) {
        throw "Salt Market gameplay crowd/foreground band is still too green: $([Math]::Round($ratio * 100, 2))% sampled green dominance."
    }
}
finally {
    if ($null -ne $bitmap) {
        $bitmap.Dispose()
    }
}

Write-Host "Salt Market green-spill validation passed: targets=$($report.target_count), maxAfter=$($report.max_green_spill_percent_after)%."
