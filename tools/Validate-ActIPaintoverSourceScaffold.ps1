$ErrorActionPreference = "Stop"

$root = Split-Path -Parent $PSScriptRoot
$exportScript = Join-Path $PSScriptRoot "Export-ActIPaintoverSourceScaffold.ps1"
$jsonPath = Join-Path $root "docs\art\act_i_paintover_source_scaffold.json"
$mdPath = Join-Path $root "docs\art\act_i_paintover_source_scaffold.md"
$assetStatusPath = Join-Path $root "docs\art\act_i_background_asset_status.csv"

if (-not (Test-Path -LiteralPath $exportScript)) {
    throw "Missing Act I paintover source scaffold exporter: $exportScript"
}

& powershell -NoProfile -ExecutionPolicy Bypass -File $exportScript
if ($LASTEXITCODE -ne 0) {
    throw "Act I paintover source scaffold export failed."
}

foreach ($path in @($jsonPath, $mdPath, $assetStatusPath)) {
    if (-not (Test-Path -LiteralPath $path)) {
        throw "Missing Act I paintover source scaffold validation input: $path"
    }
}

$scaffold = Get-Content -LiteralPath $jsonPath -Raw | ConvertFrom-Json
$rooms = @($scaffold.rooms)
if ($rooms.Count -ne 11) {
    throw "Act I paintover source scaffold expected 11 rooms, got $($rooms.Count)."
}

$assetRows = @(Import-Csv -LiteralPath $assetStatusPath)
$paintoverRows = @($assetRows | Where-Object { $_.asset_kind -eq "paintover_source" })
if ($paintoverRows.Count -ne 11) {
    throw "Expected 11 paintover source status rows, got $($paintoverRows.Count)."
}
$presentPaintovers = @($paintoverRows | Where-Object { $_.status -eq "present" })
if ($presentPaintovers.Count -ne 0) {
    throw "Paintover scaffolds must not mark final PSD paintover sources present: $($presentPaintovers.relative_path -join ', ')"
}

foreach ($room in $rooms) {
    $scaffoldPath = Join-Path $root ([string]$room.scaffold -replace "/", "\")
    if (-not (Test-Path -LiteralPath $scaffoldPath)) {
        throw "Missing per-room paintover scaffold: $($room.scaffold)"
    }
    if ($room.target_status_remains -ne "pending") {
        throw "Room $($room.room_id) paintover target should remain pending."
    }
    foreach ($layer in @(
        "00_blockout_reference_locked",
        "03_navigation_and_walk_band",
        "04_puzzle_hotspot_readability",
        "07_final_paint",
        "08_export_notes"
    )) {
        if ($layer -notin @($room.layer_stack)) {
            throw "Room $($room.room_id) scaffold missing layer: $layer"
        }
    }

    $text = Get-Content -LiteralPath $scaffoldPath -Raw
    foreach ($requiredText in @(
        "This is a scaffold for the pending paintover source, not final art.",
        "Do not create or mark the target PSD complete until final paint exists.",
        "Exported PNG must pass G9/G10 palette audit",
        "Layer stack:",
        "Critical hotspots:"
    )) {
        if ($text -notmatch [regex]::Escape($requiredText)) {
            throw "Per-room paintover scaffold $($room.scaffold) missing required text: $requiredText"
        }
    }
}

$greyFloat = @($rooms | Where-Object { $_.room_id -eq "grey_float" })[0]
if ("hard_r_float_staging" -notin @($greyFloat.risk_tags)) {
    throw "Grey Float scaffold must carry hard_r_float_staging risk."
}
$registry = @($rooms | Where-Object { $_.room_id -eq "harbor_registry" })[0]
if ("duel_format_lock" -notin @($registry.risk_tags)) {
    throw "Harbor Registry scaffold must carry duel_format_lock risk."
}

$report = Get-Content -LiteralPath $mdPath -Raw
foreach ($requiredText in @(
    "Act I Paintover Source Scaffold",
    "not final art",
    "must not be counted as paintover completion",
    "Target PSD",
    "Status Remains"
)) {
    if ($report -notmatch [regex]::Escape($requiredText)) {
        throw "Act I paintover source scaffold report missing required text: $requiredText"
    }
}
foreach ($forbiddenText in @("System.Object[]", "@{", "ï»¿", "`t", "	ools/")) {
    if ($report.Contains($forbiddenText)) {
        throw "Act I paintover source scaffold report contains malformed Markdown: $forbiddenText"
    }
}
if ($report -match "[^\u0000-\u007F]") {
    throw "Act I paintover source scaffold report must stay ASCII-only."
}

Write-Host "Act I paintover source scaffold validation passed: rooms=$($rooms.Count), finalPaintoversPresent=$($presentPaintovers.Count)."
