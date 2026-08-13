$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$jsonPath = Join-Path $root "docs\art\act_i_character_palette_grade.json"
$mdPath = Join-Path $root "docs\art\act_i_character_palette_grade.md"
$scriptPath = Join-Path $root "tools\Grade-ActICharacterPalette.py"
$standeeDir = Join-Path $root "game\standees\act_i"

foreach ($path in @($jsonPath, $mdPath, $scriptPath, $standeeDir)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I character palette grade artifact: $path"
    }
}

$report = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
if ($report.status -ne "audited") {
    throw "Act I character palette report must be the non-mutating audited status."
}
if ([int]$report.current_asset_count -ne 11) {
    throw "Act I character palette report expected 11 current assets, got $($report.current_asset_count)."
}
if ([string]$report.palette_rule -notmatch "green reserved for wrong light") {
    throw "Act I character palette report must state the green-as-wrong-light rule."
}

$assets = @($report.current_assets)
$required = @(
    "game/standees/act_i/bone_chandler.png",
    "game/standees/act_i/juno.png",
    "game/standees/act_i/market_crowd.png",
    "game/standees/act_i/prosper.png",
    "game/standees/act_i/registrar.png",
    "game/standees/act_i/sabine.png",
    "game/standees/act_i/teodor.png",
    "game/standees/act_i/tomas_bollard.png",
    "game/rooms/salt_market/setpieces/salt_market_crowd_idle_murmur.png",
    "game/rooms/salt_market/setpieces/salt_market_crowd_settle.png",
    "game/rooms/salt_market/setpieces/salt_market_crowd_turn_to_corvin.png"
)
$seen = @{}
foreach ($asset in $assets) {
    $path = [string]$asset.asset
    if ($path -notin $required) {
        throw "Unexpected Act I standee palette asset: $path"
    }
    if ($seen.ContainsKey($path)) {
        throw "Duplicate Act I standee palette asset: $path"
    }
    $seen[$path] = $true
    $pngPath = Join-Path $root ($path -replace "/", "\")
    if (-not (Test-Path -LiteralPath $pngPath)) {
        throw "Missing standee PNG from palette report: $path"
    }
    $wrongLightGreen = [double]$asset.wrong_light_green_percent
    if ($wrongLightGreen -gt 0.5) {
        throw "Act I standee $path has wrong-light green $wrongLightGreen%, over 0.5%."
    }
    $greenDominance = [double]$asset.green_dominance_percent
    if ($greenDominance -gt 4.0) {
        throw "Act I standee $path has broad green dominance $greenDominance%, over 4.0%."
    }
}
foreach ($path in $required) {
    if (-not $seen.ContainsKey($path)) {
        throw "Missing Act I standee palette asset: $path"
    }
}

$script = Get-Content -LiteralPath $scriptPath -Raw
foreach ($requiredText in @("--apply", "green_cast_ratio", "green_dominance_ratio", "wrong_light_green_percent", "green_dominance_percent", "green reserved for wrong light")) {
    if (-not $script.Contains($requiredText)) {
        throw "Act I character palette script missing required text: $requiredText"
    }
}

$md = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @('Act I Character Palette Grade', 'Mode: `audit`', 'Current Assets')) {
    if (-not $md.Contains($requiredText)) {
        throw "Act I character palette report missing required text: $requiredText"
    }
}
if ($md -match "[^\u0000-\u007F]") {
    throw "Act I character palette report must stay ASCII-only."
}

Write-Host "Act I character palette grade validation passed: assets=$($assets.Count), maxWrongLightGreen<=0.5%, maxGreenDominance<=4.0%."
